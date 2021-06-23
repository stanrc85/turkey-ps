#script to parse GNMAP files (created by Turkey or nmap) to show all hosts running web services
#output is table of devices with ports, services and url of target
#by Ryan Stanley
#updated 2/4/2014

#usage: .\get-webhosts.ps1 *filename*
#defaults to use *-scan.gnmap

Param(
  [Parameter(Mandatory=$False,Position=1)]
   [string]$file
)

#$file = read-host "Enter the name of a file to read from"
if ($file -eq ""){
    $file = "./*-scan.gnmap"
}
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
                        $value = $hostname
                        if ($hostname -eq ""){$value = $ip}
                    }
                    else{$value = $ip}
                }
                else{$value = $line.split("`t")[0].trimstart("Host: ").split(" ")[1].trimstart("(").trimend(")")}
                if ($line3[4].contains("http") -and !($line3[4].contains("s"))){
                    $port = $line2.split("/")[0].trim()
                    $obj += new-object psobject -property @{
                        #host = $hostname
                        IP = $ip
                        Port = $port
                        Service = $line2.split("/")[6]
                        URL = "http://${value}:$port"
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
                        URL = "https://${value}:$port"
                        }
                    $sslfound += 1
                    $hostsfound += 1
                }
            }
        }
    }
   }


$obj
#$obj | Format-Table -AutoSize -Property IP,port,service,url

#write-host -ForegroundColor green "Found $httpfound http ports"
#write-host -ForegroundColor green "Found $sslfound ssl ports"
#write-host -ForegroundColor green "Found $httpsfound https ports"
#write-host -ForegroundColor green "Across $hostsfound hosts"