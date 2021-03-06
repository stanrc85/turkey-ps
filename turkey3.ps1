#Codename: Turkey
#by Ryan Stanley


#add tshark check, now prompts to start tshark - done
#better OS/service sorting - done
#add dns scan to provide list of host names and IPs (for easier reporting) - done
#better IP list sorting, try to remove garbage from list - done
#IP sorting accurate now - done
#only asks for your IP once - done
#11/8/13 - v3 rewrite program, add functions, smarter
#11/25/13 - pre-final version, needs to be tested on assessment first
#12/19/13 - adding nessus support - beta
#1/25/14 - rewrite sorting function, cleaner and better IP accuracy
#4/3/2014 - fix OS detection
#4/4/2014 - add ability to import from other gnmap files and sort results
#4/7/2014 - actually fix OS detection
#4/17/2014 - show gnmap files in current directory when importing results
#5/13/2014 - DNS is optional based on user input

#to fix list: better port entry (range or top ports)


#SAT Nmap scripter and parser
#First does vitality scan (ping sweep)
#and then saves results to $file-live-hosts.txt
#and then does full scan of those hosts based on port range provided
#and then saves an IP list based on each "keyword" (see array below)

#Usage: .\turkey3.ps1


$global:token = '0'
$global:myip = '0'
################################
#check ip to exclude from scans#
################################
Function IPCheck
{
#Get IP of LAN and exclude from nmap scan
$right_ip = 'n'
$ipcount = 0
$global:myip = ((ipconfig | findstr [0-9].\.)[2]).Split()[-1]
while ($right_ip -eq 'n'){
$right_ip = read-host "`nIs" $global:myip "the correct LAN IP? (y/n)"
if ($right_ip -eq 'y'){
    return $global:myip
}
$global:myip = ((ipconfig | findstr [0-9].\.)[$ipcount]).Split()[-1]
$ipcount = $ipcount + 1
}
clear
}

##################
#stats           #
##################
Function stats
{
$live = (gc $file-live-hosts.txt | Measure-Object -line).Lines
$portsopen = gc $file-scan.gnmap -Delimiter /
$portcount = 0
foreach ($word in $portsopen)
{
 if ($word -cmatch "open")
 {
 $portcount++
 }
}
Write-Host -ForegroundColor green "`n[+] Identified $portcount open ports across $live hosts.`n"
}

##################
#tshark check    #
##################
Function tshark
{
$tshark = 0
while ($tshark -ne "true"){
gps | ?{if ($_ -match "tshark"){ $tshark = "true"}}
if ($tshark -ne "true") 
{
Start-Process powershell .\tshark2.ps1 -WorkingDirectory .
while ($tshark -ne "true")
{
gps | ?{if ($_ -match "tshark"){ $tshark = "true"}}
write-host -ForegroundColor red "[!] Error: Tshark must be running!"
sleep -s 3
}
}
}
}

##############################
#Find live hosts (ping sweep)#
##############################
Function findLiveHosts
{
$range = Read-Host "`nEnter the IP range to scan, in Nmap readable format"
if (Test-Path ".\$file-live-hosts.txt")
{rm "$file-live-hosts.txt"}
write-host -ForegroundColor green "`n[+] Starting ping sweep of $range"
##################
#ping sweep nmap scan - modify as needed
$pingsweep = "nmap -sn -PP -PE $range -oA $file -n --exclude $global:myip"
Invoke-Expression $pingsweep
##################

$ip = gc "$file.gnmap" | ? {$_.Contains("Up")}
foreach ($i in $ip){
$i.split("`t")[0].trimstart("Host: ").trimend(" ()") | Out-File -append -encoding ASCII "$file-live-hosts.txt"}
if (Test-Path ".\$file-live-hosts.txt")
{
Write-Host -ForegroundColor green "`n[+] Ping sweep complete,"$ip.length"hosts found." 
write-host -ForegroundColor green "[+] Live hosts written to $file-live-hosts.txt"
}
else
{
write-host -ForegroundColor red "`n[!] IPs not written to file. Possibly no hosts found?`n"
again
}
}

###################
#Reverse-DNS      #
###################
Function DNS
{
Write-Host -ForegroundColor green "`n[+] Reverse DNS scan started."
##################
#nmap for reverse dns
$dnsscan = "nmap -sn -P0 -R -iL $file-live-hosts.txt -oG $file-reverse-dns.txt"
Invoke-Expression $dnsscan
##################

Write-Host -ForegroundColor green "`n[+] Reverse DNS scan complete."
Write-Host -ForegroundColor green "[+] Results written to $file-reverse-dns.txt"
}


###################
#Custom Nmap Scan #
###################
Function customNmap
{
$customnmap = Read-Host "`nEnter the nmap scan you would like to run"
Write-Host -ForegroundColor green "`n[+] Starting custom nmap scan."
Invoke-Expression "$customnmap --exclude $global:myip -oA $file-scan"
Write-Host -ForegroundColor green "`n[+] Results saved to $file-scan."
$ip = gc "$file-scan.gnmap" | ? {$_.Contains("Up")}
foreach ($i in $ip){
$i.split("`t")[0].trimstart("Host: ").trimend(" ()") | Out-File -append -encoding ASCII "$file-live-hosts.txt"}
if (Test-Path ".\$file-live-hosts.txt")
{
write-host -ForegroundColor green "[+] Live hosts written to $file-live-hosts.txt"
}
else
{
write-host -ForegroundColor red "`n[!] IPs not written to file. Possibly no hosts found?`n"
again
}
filterHosts
stats
again
}

###################
#Port Scan        #
###################
Function portScan
{
if (!(Test-Path ".\$file-live-hosts.txt")){
Write-Host -ForegroundColor red "`n[!] Error.  File not found: $file-live-hosts.txt"
write-host -foregroundColor red "[!] Please restart the script and run step 1 first."
again
}
$ports = Read-Host "`nBased on Nmap's Top Ports list, enter the number of ports you would like to scan"
$dodns = read-host "`nWould you like to perform a reverse DNS scan? (y/n)"
###################
#modify this variable to change nmap syntax
if ($dodns -eq 'y'){
$nmap = "nmap -sS -A -Pn -R --top-ports $ports -iL $file-live-hosts.txt --exclude $global:myip -oA $file-scan -vvv"
} else {
$nmap = "nmap -sS -A -Pn --top-ports $ports -iL $file-live-hosts.txt --exclude $global:myip -oA $file-scan -vvv"
}
###################

Write-Host -ForegroundColor green "`n[+] The host list is taken from the ping sweep, the nmap scan to be run is: `n"
Write-Host -ForegroundColor yellow  $nmap
write-Host "`nPress enter to continue..."
$x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
Invoke-Expression $nmap
}

###################
#Filter hosts     #
###################
Function filterHosts
{

Write-Host -ForegroundColor yellow "`n[+] List of previous scans in current directory.`n"
$a = ls | ?{$_.Name -cmatch "gnmap"}
$a | ForEach-Object {$_.name.Substring(0,$_.Name.Length-6)}
if (Test-Path ./$file){
    $file = read-host "`nEnter the file (gnmap) to import. ex: lab-scan"
    $sorts = (gc "$file.gnmap" | ? {$_.contains("Ports:")})
}else{    
$sorts = (gc $file-scan.gnmap | ? {$_.contains("Ports:")})
}


###################
#add more "keywords" to this arrary to sort results by
$keywords = @("windows","linux","solaris","unix","esx","cisco","printer","http","sql","ssh","dns","smtp","oracle","ftp","telnet","nfs")
###################
rm "$file-typesfound.txt" -Force -WarningAction SilentlyContinue -ErrorAction SilentlyContinue
write-host -ForegroundColor green "`n[+] Sorting" -NoNewline
$findos = 'y'
$count = 0
foreach ($sort in $sorts){  
$count2 = $sort.split("`t").count
while ($findos -eq 'y'){
if ($count -eq $count2){$findos = 'n'}
        $osline = $sort.split("`t")[$count]
        
           if ($osline){
            if ($osline.contains("OS: ")){
                $findos = 'n'
            }else {
                $count = $count+1
                
            }
     } 
   }
 }  

for ($k=0; $k -lt $keywords.length; $k++)
{
$word = $keywords[$k]
rm "$file-$word-hosts.txt" -WarningAction SilentlyContinue -ErrorAction SilentlyContinue

foreach ($sort in $sorts){           
    $hostos = $sort.split("`t")[$count]
    if ($hostos){
        if ($hostos -match ("$word")){
             $sort.split("`t")[0].trimstart("Host: ").trimend(" ()") | Out-File -Append -Encoding ascii "$file-$word-hosts.txt"
             write-host -ForegroundColor green "." -NoNewline
        }
   }
   $services = $sort.split("`t")[1].split(":")[1].split(",").trim()
   
   foreach ($line2 in $services){
    $open = $line2.split("/")[1]
    if ($open -eq "open"){
   $service2 = $line2.split("/")[4]
   if ($service2.contains("$word")){
       $sort.split("`t")[0].trimstart("Host: ").trimend(" ()") | Out-File -Append -Encoding ascii "$file-$word-hosts.txt"
       write-host -ForegroundColor green "." -NoNewline
   }
   }
   }
   rm "$file-$word.txt" -WarningAction SilentlyContinue -ErrorAction SilentlyContinue

}
}


#"Sorting Hat" loop
write-host "`n`n"
for ($k=0; $k -lt $keywords.length; $k++)
{
$word = $keywords[$k]
if (Test-Path ".\$file-$word-hosts.txt"){
#gc $file-$word-hosts.txt | select -Unique | out-file -Encoding ascii $file-$word-hosts.txt
$count = (gc "$file-$word-hosts.txt" | Measure-Object)
write-host -ForegroundColor green "[+] Sorted: $word -"$count.Count"Hosts Found"
$word | Out-File -Append -encoding ASCII "$file-typesfound.txt"
}
else
{
#write-host -ForegroundColor red "Sorted: $word - None Found"
}
}
#Write-Host -ForegroundColor yellow "`nPlease review host lists prior to using as input to another program."
}

###################
#cleanup          #
###################
Function cleanup
{
  Write-Host -ForegroundColor yellow "`n[+] List of previous scans in current directory, you can load from these or start a new one.`n"
$a = ls | ?{$_.Name -cmatch "-live-hosts.txt"}
$a | ForEach-Object {$_.name.Substring(0,$_.Name.Length-15)}
  
  $clean = read-host "`nEnter the name (prefix) for the files you would like to remove"
  write-host -ForegroundColor Yellow "`n[!] Warning: This will erase all files associated with those scans."
  $continue = Read-Host "`nWould you like to continue? (y/n)"
  if ($continue -eq 'y') {
        Remove-Item $clean*
        write-host -ForegroundColor green "`n[+] Files cleaned."
}
  else {
    again
  }

}

###################
#Nessus Menu     #
###################
Function nessusMenu
{
#################
#Fancy header   #
#################
clear
Write-Host -ForegroundColor green "****************************"
Write-Host -ForegroundColor green "SAT NMap Scripter v3: Nessus"
Write-Host -ForegroundColor green "****************************"
Write-Host ""
Write-Host ""
Write-Host "Choose an option from the list"
Write-Host ""
if ($token -eq '0'){
Write-Host -ForegroundColor red "     1 - Authenticate with Nessus"
}
else {
Write-Host -ForegroundColor green "     1 - Authenticate with Nessus"
}
Write-Host "     2 - Show Nessus Policies"
Write-Host "     3 - Start Scan"
Write-Host "     4 - Show scan status"
Write-Host ""
Write-Host "     0 - Exit"
$choice = Read-Host "`nEnter your choice"
if ($choice -eq '0'){
again
} elseif ($choice -eq '1'){
    nessusLogin
    nessusagain
} elseif ($choice -eq '2'){
    nessusPolicies
    nessusagain
} elseif ($choice -eq '3'){
    nessusScan
    nessusagain
} elseif ($choice -eq '4'){
    nessusStatus
    nessusagain
} elseif ($choice -eq '5'){
    nessusTest
    nessusagain
}
}

###################
#NessusLogin      #
###################
Function nessusLogin
{
add-type @"
    using System.Net;
    using System.Security.Cryptography.X509Certificates;
    public class TrustAllCertsPolicy : ICertificatePolicy {
        public bool CheckValidationResult(
            ServicePoint srvPoint, X509Certificate certificate,
            WebRequest request, int certificateProblem) {
            return true;
        }
    }
"@
[System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy

#Login to get session cookie
if ($token -eq '0') {
$user = Read-Host "`nEnter the Nessus username"
$securepass = Read-Host "`nEnter the Nessus password" -AsSecureString
$BSTR = `
    [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($securepass)
$plainpass = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR) 
$postParams = @{login=$user;password=$plainpass}
[xml]$results = Invoke-WebRequest -Uri https://localhost:8834/login -Method POST -Body $postParams
$global:token = $results.reply.contents.token
}
else {
$postParams = @{token=$token}
[xml]$results = Invoke-WebRequest -Uri https://localhost:8834/report/list -Method POST -Body $postParams
}
if ($results.reply.status -eq 'OK'){
    write-host -ForegroundColor green "`n[+] Successfully authenticated with Nessus."
}
else {
    write-host -ForegroundColor Yellow "`n[!] Error: Could not authenticate with Nessus."
    $token = '0'
    nessusagain
} 

}


###################
#NessusTest       #
###################
Function nessusTest
{
$postParams = @{token=$token}
[xml]$results = Invoke-WebRequest -Uri https://localhost:8834/policy/list -Method POST -Body $postParams
Out-File -FilePath .\results.xml -InputObject $results.reply.contents.policies
$results.reply.contents.policies.policy | ft -AutoSize -Wrap
nessusagain
}


###################
#NessusPolicies   #
###################
Function nessusPolicies
{
#show nessus policies
$postParams = @{token=$token}
[xml]$results = Invoke-WebRequest -Uri https://localhost:8834/policy/list -Method POST -Body $postParams
if ($results.reply.status -eq 'OK'){
    write-host -ForegroundColor green "`n[+] Nessus scan policies available."
}
else {
    write-host -ForegroundColor Yellow "`n[!] Error: Could not authenticate with Nessus."
    $token = '0'
    nessusagain
} 
$results.reply.contents.policies.policy | ft -AutoSize -Wrap
nessusagain
}

###################
#NessusScan       #
###################
Function nessusScan
{
#start new scan
$postParams = @{token=$token}
[xml]$results = Invoke-WebRequest -Uri https://localhost:8834/policy/list -Method POST -Body $postParams
if ($results.reply.status -eq 'OK'){
    write-host -ForegroundColor green "`n[+] View scan policies below."
}
else {
    write-host -ForegroundColor Yellow "`n[!] Error: Could not authenticate with Nessus."
    nessusagain
} 
$results.reply.contents.policies.policy | ft -AutoSize -Wrap -Property policyName, policyID
$policy = Read-Host "`nEnter the policy ID for the scan policy you would like to use"
write-host ""
Get-ChildItem -Name *.txt
$targets = Read-Host "`nEnter the file name that contains the target IPs"
$targets = (Get-Content $targets) -join ","
#write-host $targets
$scanname = Read-Host "`nEnter the name you would like to save the scan as"
$postParams = @{token=$token;policy_id=$policy;target=$targets;scan_name=$scanname}
[xml]$results = Invoke-WebRequest -Uri https://localhost:8834/scan/new -Method POST -Body $postParams
if ($results.reply.status -eq 'OK'){
    write-host -ForegroundColor green "`n[+] Scan successfully started."
}
else {
    write-host -ForegroundColor Yellow "`n[!] Error: Could not authenticate with Nessus."
    $token = '0'
    nessusagain
} 
nessusagain
}

###################
#NessusStatus     #
###################
Function nessusStatus
{
#view scan status
$postParams = @{token=$token}
[xml]$results = Invoke-WebRequest -Uri https://localhost:8834/report/list -Method POST -Body $postParams
if ($results.reply.status -eq 'OK'){
    write-host -ForegroundColor green "`n[+] Nessus scan status."
}
else {
    write-host -ForegroundColor Yellow "`n[!] Error: Could not authenticate with Nessus."
    $token = '0'
    nessusagain
}  
$results.reply.contents.reports.report | ft -AutoSize -HideTableHeaders -Property readableName,status
}

###################
#Help info        #
###################
Function showHelp
{
clear
Write-Host -ForegroundColor green "********************"
Write-Host -ForegroundColor green "SAT NMap Scripter v3"
Write-Host -ForegroundColor green "********************"
write-host ""
write-host "SAT nmap scanner, used to automate nmap to discover and fingerprint hosts."
write-host ""
write-host -ForegroundColor green "Option 1"
write-host "     Runs nmap ping sweep followed by a scan to resolve DNS names."
write-host "     Live hosts are printed to file, this file is used in later scans as a host list."
write-host ""
write-host "     Nmap syntax used:"
Write-Host -ForegroundColor yellow "     nmap -sn -PP -PE range -oA file -n --exclude $global:myip"
Write-Host -ForegroundColor yellow "     nmap -sn -R -iL file-live-hosts.txt -oG file-reverse-dns.txt"
write-host ""
write-host -ForegroundColor green "Option 2"
write-host "     Performs port scans, OS detection and basic NSE scripts."
write-host "     Takes live hosts from ping sweep and scans the top X ports as decided by user."
write-host "     Once complete, results are parsed and hosts are sorted into lists based on OS or services detected."
write-host ""
write-host "     Nmap syntax used:"
write-host -ForegroundColor Yellow "     nmap -sS -A -Pn -n --top-ports ports -iL file-live-hosts.txt --exclude $global:myip -oA file-scan -vvv"
write-host ""
write-host -ForegroundColor green "Option 3"
write-host "     Based on OS or services running, performs targeted Nmap scripts against targets."
write-host ""
write-host "     Nmap syntax used:"
write-host -ForegroundColor yellow "     nmap -sS -p 80,443,8080,8000 -iL file-http-hosts.txt -oA file-http-scripts --script http-methods"
write-host ""
write-host -ForegroundColor green "Option 4"
write-host "     Performs all previous steps in order."
write-host ""
write-host -ForegroundColor green "Option 5"
write-host "     Run custom nmap scan, user provides syntax. Then sorts hosts based on results."
write-host ""
write-host -ForegroundColor green "Option 7"
write-host "     Imports and sort previous Nmap scan results from gnmap file."
}

###################
#Nmap Scripts     #
###################
Function runScripts
{
if (!(Test-Path ".\$file-typesfound.txt")){
Write-Host -ForegroundColor red "`n[!] Error.  File not found: $file-typesfound.txt"
write-host -foregroundColor red "[!] Please restart the script and run step 2 first."
again
}

Write-Host -ForegroundColor Yellow "`n[+] Please check that hosts lists only contain IP addresses."
Write-Host -ForegroundColor Yellow "[+] Sometimes a version number will make it into the list."
write-Host "`nPress enter to continue..."
$x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
$types = (gc "$file-typesfound.txt").split()
###################
#modify this variable to change nmap syntax
$httpnmap = "nmap -sS -p 80,443,8080,8000 -iL $file-http-hosts.txt -oA $file-http-scripts --script http-methods"
###################
#modify this variable to change nmap syntax
$ftpnmap = "nmap -sS -p 20,21,115,989,990 -iL $file-ftp-hosts.txt -oA $file-ftp-scripts --script ftp-anon"
###################
#modify this variable to change nmap syntax
$winnmap = "nmap -sS -p 135-139,445 -iL $file-windows-hosts.txt -oA $file-windows-scripts --script smb-os-discovery --script smb-security-mode"
###################
#modify this variable to change nmap syntax
$smtpnmap = "nmap -sS -p 25 -iL $file-smtp-hosts.txt -oA $file-smtp-scripts --script smtp-open-relay"
###################
#modify this variable to change nmap syntax
$sshnmap = "nmap -sS -p 22 -iL $file-ssh-hosts.txt -oA $file-ssh-scripts --script sshv1 --script ssh2-enum-algos"
###################
#modify this variable to change nmap syntax
$sqlnmap = "nmap -sS -p 3306,1433 -iL $file-sql-hosts.txt -oA $file-sql-scripts --script ms-sql-info --script mysql-info"



switch ($types){
'http' {
Write-Host -ForegroundColor green "`n[+] Starting HTTP scripts against"(gc $file-http-hosts.txt | Measure-Object -line).Lines"hosts.`n[+] Writing results to $file-http-scripts."
Invoke-Expression $httpnmap
}
'ftp' {
Write-Host -ForegroundColor green "`n[+] Starting FTP scripts against"(gc $file-ftp-hosts.txt | Measure-Object -line).Lines"hosts.`n[+] Writing results to $file-ftp-scripts."
Invoke-Expression $ftpnmap
}
'windows' {
Write-Host -ForegroundColor green "`n[+] Starting Windows (SMB) scripts against"(gc $file-windows-hosts.txt | Measure-Object -line).Lines"hosts.`n[+] Writing results to $file-windows-scripts."
Invoke-Expression $winnmap
}
'ssh' {
Write-Host -ForegroundColor green "`n[+] Starting SSH scripts against"(gc $file-ssh-hosts.txt | Measure-Object -line).Lines"hosts.`n[+] Writing results to $file-ssh-scripts."
Invoke-Expression $sshnmap
}
'sql' {
Write-Host -ForegroundColor green "`n[+] Starting SQL scripts against"(gc $file-sql-hosts.txt | Measure-Object -line).Lines"hosts.`n[+] Writing results to $file-sql-scripts."
Invoke-Expression $sqlnmap
}
'smtp' {
Write-Host -ForegroundColor green "`n[+] Starting SMTP scripts against"(gc $file-smtp-hosts.txt | Measure-Object -line).Lines"hosts.`n[+] Writing results to $file-smtp-scripts."
Invoke-Expression $smtpnmap
}
}
}

###################
#Menu or quit     #
###################
Function nessusagain
{
$again = Read-Host "`nWould you like to return to the (m)enu or (q)uit?"
if ($again -eq 'm'){
    nessusMenu
} else {    
    exit 
}
}


###################
#Menu or quit     #
###################
Function again
{
$again = Read-Host "`nWould you like to return to the (m)enu or (q)uit?"
if ($again -eq 'm'){
    menu
} else {
    
    exit 
}
}

###################
#create menu      #
###################
Function menu
{
#################
#Fancy header   #
#################
clear
Write-Host -ForegroundColor green "********************"
Write-Host -ForegroundColor green "SAT NMap Scripter v3"
Write-Host -ForegroundColor green "********************"
Write-Host ""
Write-Host ""
Write-Host "Choose an option from the list"
Write-Host ""
Write-Host "     1 - Ping sweep and DNS"
Write-Host "     2 - Port scanning and OS Detection"
Write-Host "     3 - Nmap scripts (http, smtp, ftp, etc)"
Write-Host "     4 - Rapid VA: All of the above"
Write-Host ""
Write-Host "     5 - Custom Nmap scan"
Write-Host "     6 - Nessus scanning"
Write-Host "     7 - Import and sort previous scan results (gnmap)"
Write-Host ""
Write-Host "     9 - Help"
Write-Host "     0 - Exit"
Write-Host -ForegroundColor yellow "`nNote: Options 2 and 3 both rely on output from the previous step."
Write-Host -ForegroundColor yellow "      Please do not run out of order unless the previous step has already been run."
$choice = Read-Host "`nEnter your choice"
#write-host $choice "was your choice"
if ($choice -eq '0'){
exit
} elseif ($choice -eq '9'){
    showHelp
    again
} elseif ($choice -eq '8'){
    cleanup
    again
} elseif ($choice -eq '7'){
    filterHosts
    again
} elseif ($choice -eq '6'){
    nessusMenu
    again
    
} elseif ($choice -eq '5'){
    
} elseif ($choice -eq '4'){
    
} elseif ($choice -eq '3'){
    
} elseif ($choice -eq '2'){
    
} elseif ($choice -eq '1'){
    
} else {
    write-host -ForegroundColor red "`n[!] Error: Please enter a valid number from the options listed."
    again
}

if ($global:myip -eq '0'){
    $global:myip = IPCheck
}

#################
#Get vals       #
#################
Write-Host -ForegroundColor yellow "`n[+] List of previous scans in current directory, you can load from these or start a new one.`n"
#ls | ?{$_.Name -cmatch "scan.gnmap" -or $_.Name -cmatch "live-hosts.txt"} | ft -AutoSize -HideTableHeaders -Property name

$a = ls | ?{$_.Name -cmatch "-live-hosts.txt"}
$a | ForEach-Object {$_.name.Substring(0,$_.Name.Length-15)}
#$a | ForEach-Object {$_.name.TrimEnd("-live-hosts.txt")}
#write-host $a
$file = Read-Host "`nEnter the name to resume or create a new one, input and output files will use this as a prefix"

tshark

switch ($choice)
{
'1'
{
findLiveHosts
again
}
'2'
{
portScan
filterHosts
again
}
'3'
{
runScripts
again
}
'4'
{
findLiveHosts
DNS
portScan
filterHosts
runScripts
stats
again
}
'5'
{
customNmap
again
}
'6'
{
nessusLogin
again
}
}
}

##################
#Start here      #
##################
##################
#Run Menu        #
##################
menu