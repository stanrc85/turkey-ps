#script to parse GNMAP files (created by Turkey or nmap) to identify all hosts running web services
#followed by "web-recon" activities on those devices
#by Ryan Stanley
#created 5/22/2014

#Still in BETA, needs to be tested on more systems.

#to do: 

#usage: .\bacon.ps1 *filename*
#defaults to use *-scan.gnmap

Param(
  [Parameter(Mandatory=$False,Position=1)]
   [string]$file
)

#$file = read-host "Enter the name of a file to read from"
if ($file -eq ""){
    $file = "./*-scan.gnmap"
}

###################

function Ignore-SSLCertificates
{
    $Provider = New-Object Microsoft.CSharp.CSharpCodeProvider
    $Compiler = $Provider.CreateCompiler()
    $Params = New-Object System.CodeDom.Compiler.CompilerParameters
    $Params.GenerateExecutable = $false
    $Params.GenerateInMemory = $true
    $Params.IncludeDebugInformation = $false
    $Params.ReferencedAssemblies.Add("System.DLL") > $null
    $TASource=@'
        namespace Local.ToolkitExtensions.Net.CertificatePolicy
        {
            public class TrustAll : System.Net.ICertificatePolicy
            {
                public bool CheckValidationResult(System.Net.ServicePoint sp,System.Security.Cryptography.X509Certificates.X509Certificate cert, System.Net.WebRequest req, int problem)
                {
                    return true;
                }
            }
        }
'@ 
    $TAResults=$Provider.CompileAssemblyFromSource($Params,$TASource)
    $TAAssembly=$TAResults.CompiledAssembly
    ## We create an instance of TrustAll and attach it to the ServicePointManager
    $TrustAll = $TAAssembly.CreateInstance("Local.ToolkitExtensions.Net.CertificatePolicy.TrustAll")
    [System.Net.ServicePointManager]::CertificatePolicy = $TrustAll
}
Ignore-SSLCertificates
[System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$true}

###################

Function getTargets
{
#parses gnmap file to gather devices with http running on scanned ports
write-host -ForegroundColor green "`n[+] Generating target list based on previous scan results."
$obj = @()
$httpfound = 0
$sslfound = 0
$httpsfound = 0
$hostsfound = 0

$hosts = @()
$hosts = (gc $file | ? {$_.contains("Ports:")})
foreach ($line in $hosts){
    $ip = $line.split("`t")[0].trimstart("Host: ").split(" ")[0].trim()
    $open = $line.split("`t")[1].split(":").split(",").trim()
    foreach ($line2 in $open){
        if($line2 -ne "Ports"){
            $openport = $line2.split("/")[1].trim()
            if ($openport -match "open"){
                $line3 = $line2.split("/").trim()
                if ($line.split("`t")[0].trimstart("Host: ").split(" ")[1] -eq "()"){
                    if ((gc *-reverse-dns.txt -WarningAction SilentlyContinue -ErrorAction SilentlyContinue) -match $ip){
                        $hostname = ((gc *-reverse-dns.txt) | ? {$_.contains($ip)}).split("`t").split(":").split(" ")[3].trimstart("(").trimend(")")
                        $global:value = $hostname
                        if ($hostname -eq ""){$global:value = $ip}
                    }
                    else{$global:value = $ip}
                }
                else{$global:value = $line.split("`t")[0].trimstart("Host: ").split(" ")[1].trimstart("(").trimend(")")}
                if ($line3[4].contains("http") -and !($line3[4].contains("s"))){
                    $port = $line2.split("/")[0].trim()
                    $obj += new-object psobject -property @{
                        #host = $hostname
                        IP = $ip
                        Port = $port
                        Service = $line2.split("/")[6]
                        URL = "http://${global:value}:$port"
                    }
                    $httpfound += 1
                    $hostsfound += 1
    
                }
                if ($line3[4].contains("http") -and $line3[4].contains("s")){
                    $port = $line2.split("/")[0].trim()
                    $obj += new-object psobject -property @{
                        #host = $hostname
                        IP = $ip
                        Port = $port
                        Service = $line2.split("/")[6]
                        URL = "https://${global:value}:$port"
                        }
                    $sslfound += 1
                    $hostsfound += 1
                }
            }
        }
    }
   }
   $obj | ft -Property url -HideTableHeaders | Out-File -Encoding ascii web-targets.txt
   (gc web-targets.txt) | ? {$_.trim() -ne "" } | set-content web-targets.txt
   write-host -ForegroundColor green "`n[+] Target list saved to web-targets.txt"
}


Function getMethods 
{
    $obj2 = @()
    $targets = gc web-targets.txt
    foreach ($target in $targets){
    $target = $target.trimstart().trimend()
    $options = ""
    $title = "No Title Found"
    $method = ""

  

    
    
    Write-Host -ForegroundColor green "`n[+] Gathering info on"$target
    $options = Invoke-WebRequest -Uri $target -TimeoutSec 10 -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
    $contents = $options.content
    foreach ($content in $contents){
      $title = ($content -split("<title>") -split("</title>"))[1]
     
    }
    Write-Host -ForegroundColor green "`n[+]" $target "-" $options.statuscode $options.statusdescription "-" $title
    $global:ip = $target.split("/")[2].split(":")[0].trimstart().trimend()
    $global:port = $target.split(":")[2].trimstart().trimend()
    #$method2 = "No response"
    #if ($options.statusdescription -eq 'OK'){
    
    nmapMethodScript
    foreach ($method in $global:methods){
        if ($method -match ("http-methods:")){
             Write-Host -ForegroundColor green "`n[+] Methods available:"$method.split(":")[1]
             if ($method -match "Allow"){
                $method2 = "No response"
             }
             else{
                $method2 = $method.split(":")[1].trimstart().trimend()
             }
        }
    }
    #}
                $obj2 += new-object psobject -property @{
                        IP = $global:ip
                        Port = $global:port
                        Title = $title
                        Status = $options.statuscode
                        Description = $options.statusdescription
                        Server = $options.headers.server
                        Methods = $method2
                }
}
$obj2 | ft -AutoSize -Property IP,Port,Status,Description,Title,Server,Methods
$obj2 | fl -Property IP,port,status,title,server,methods | Out-File web-results.txt
}

Function getScreenshot
{
$targets = gc web-targets.txt
foreach ($target in $targets){
$src = @'
using System;
using System.Runtime.InteropServices;

namespace PInvoke
{
    public static class NativeMethods 
    {
        [DllImport("user32.dll")]
        [return: MarshalAs(UnmanagedType.Bool)]
        public static extern bool GetWindowRect(IntPtr hWnd, out RECT lpRect);
    }

    [StructLayout(LayoutKind.Sequential)]
    public struct RECT
    {
        public int Left;        // x position of upper-left corner
        public int Top;         // y position of upper-left corner
        public int Right;       // x position of lower-right corner
        public int Bottom;      // y position of lower-right corner
    }
}
'@

Write-Host -ForegroundColor green "`n[+] Capturing screenshot of $target."
$ie = New-Object -ComObject InternetExplorer.Application
$ie.Navigate2($target)
$ie.Visible = $true
sleep -Seconds 3


Add-Type -TypeDefinition $src
Add-Type -AssemblyName System.Drawing

# Get a process object from which we will get the main window bounds

$iseProc = Get-Process -name iexplore


$bmpScreenCap = $g = $null
try {
    $rect = new-object PInvoke.RECT
    if ([PInvoke.NativeMethods]::GetWindowRect($iseProc[0].MainWindowHandle, [ref]$rect))
    {
        $width = $rect.Right - $rect.Left + 1
        $height = $rect.Bottom - $rect.Top + 1
        $bmpScreenCap = new-object System.Drawing.Bitmap $width,$height
        $g = [System.Drawing.Graphics]::FromImage($bmpScreenCap)
        $g.CopyFromScreen($rect.Left, $rect.Top, 0, 0, $bmpScreenCap.Size, 
                          [System.Drawing.CopyPixelOperation]::SourceCopy)
        $bmpScreenCap.Save("$home\$target.screenshot.bmp")
    }
}
finally {
    if ($bmpScreenCap) { $bmpScreenCap.Dispose() }
    if ($g) { $g.Dispose() }
}
}
$ie.Quit()
}


Function nmapMethodScript
{
    $nmapmethods = "nmap $global:ip -p $global:port --script=http-methods"
    $global:methods = Invoke-Expression $nmapmethods

}

Function getPorts
{
    $global:ports = gc web-targets.txt | % {$_.split(":")[2].trimstart().trimend()} | select -Unique
}

#################
#Start here     #
#################

if (Test-Path .\web-targets.txt){
    write-host -ForegroundColor yellow "`n[!] Target list has already been created."
    $again = read-Host "`nWould you like to run the parser again? (y/n)"
    if ($again -eq 'y'){
        getTargets
    }

}
else {    
    getTargets    
}
#getPorts
getMethods
getScreenshot

