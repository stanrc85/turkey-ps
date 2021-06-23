#script to parse GNMAP files (created by nmap) to show all hosts running specific services
#output is table of devices with ports, services
#by Ryan Stanley
#2/4/2014 - created
#4/4/2014 - fix checking for open ports, port variable found in versions no longer appear in results
#4/7/2014 - added OS column output
#8/18/2014 - added hostname to output if present, shorten OS field, search by hostname


#to add: 

#usage: .\finder.ps1 *port/service name/ip/hostname* *filename*
#default port/service is "common" list
#default file to use is *-scan.gnmap

Param(
  [Parameter(Mandatory=$False,Position=1)]
   [string]$global:file,
  [Parameter(Mandatory=$False,Position=0)]
   [string]$port
)

if ($port -eq ""){
    $port = "common"
}

if ($global:file -eq ""){
    $global:file = "./*-scan.gnmap"
}


Function filterHosts
{
 
    $obj = @()
    $hosts = @()
    $hosts = (gc $global:file | ? {$_.contains("Ports:")})
    foreach ($port in $global:ports){   
    
    foreach ($line in $hosts){
    $ip = ""
    $port2 = ""
    $dns = ""
    $os3 = ""
    $ip = $line.split("`t")[0].trimstart("Host: ").trimend(" ").split(" ")[0]
    $open = $line.split("`t")[1].split(":").split(",").trim()
    $dns = $line.split(" ")[2].split()[0].trimstart("(").trimend(")")
    foreach ($line2 in $open){
    $stuff = $line.split("`t")
    if ($line2.contains("/open/")){
    $find = $line2.split("/")[0].trim()
    $find2 = $line2.split("/")[6]
    $find3 = $line2.split("/")[4]
    $findhostname = $line.split(" ")[2].split()[0].trimstart("(").trimend(")")
    $count2 = $line.split("`t").count
    
    foreach ($line3 in $stuff){
    if ($line3.contains("OS: ")){
    $os3 = $line3.trimstart("OS: ").split("-")[0].split("(")[0]
    }
    
    if ($find -eq $port){
        $port2 = $line2.split("/")[0].trim()
        $obj += new-object psobject -property @{
            IP = $ip
            Port = $port2
            Hostname = $dns
            Service = $line2.split("/")[6]   
            OS = $os3       
            }
    }
    if ($find2){
    if ($find2.contains("$port")){
        $port2 = $line2.split("/")[0].trim()
        if ($port -eq $find){
        $obj += new-object psobject -property @{
            IP = $ip
            Port = $port2
            Hostname = $dns
            Service = $line2.split("/")[6]
            OS = $os3
            }
       }
    }
    }
    if ($find3){
    if ($find3.contains("$port")){
        $port2 = $line2.split("/")[0].trim()
        $obj += new-object psobject -property @{
            IP = $ip
            Port = $port2
            Hostname = $dns
            Service = $line2.split("/")[6]
            OS = $os3
            }
        
    }
    }
    if ($findhostname){
    if ($findhostname.contains("$port")){
        $port2 = $line2.split("/")[0].trim()
        $obj += new-object psobject -property @{
            IP = $ip
            Port = $port2
            Hostname = $dns
            Service = $line2.split("/")[6]
            OS = $os3
            }
        
    }
    }
    }
    }
    }
}
}
$obj | select -Unique ip, port, hostname, service, os | ft -AutoSize

}

#####Filter based on IP####
$isip = [bool]($port -as [ipaddress])
if ($isip){
$findos = 'y'
$count = 0
$obj = @()
$ip2 = $port
$hosts = @()
    
$hosts = (gc $global:file | ? {$_.contains("Ports:")})
foreach ($line in $hosts){
 $stuff = $line.split("`t")
$count2 = $line.split("`t").count
    foreach ($line3 in $stuff){
    if ($line3.contains("OS: ")){
    $os3 = $line3.trimstart("OS: ").split("-")[0].split("(")[0]
    }
    $ip = $line.split("`t")[0].trimstart("Host: ").trimend(" ").split(" ")[0]
    $open = $line.split("`t")[1].split(":").split(",").trimstart()
    $ports = $line.split("`t")[1].split(":")[1].split(",").trimstart()[0]
    $dns = $line.split(" ")[2].split()[0].trimstart("(").trimend(")")
    foreach ($line2 in $open){
    if ($line2 -ne "Ports"){
    if ($line2.Contains("open")){
    
    $find4 = $line.split("`t")[0].split(":")[1].trimstart().split(" ")[0]
    if ($find4 -eq $ip2){
    
        $port2 = $line2.split("/")[0].trim()
        
        $obj += new-object psobject -property @{
            IP = $ip
            Port = $port2
            Hostname = $dns
            Service = $line2.split("/")[6]    
            OS = $os3        
            }
    }
    }
    }
    }
    }
    }
$obj | select -Unique ip,port,hostname,service,os | ft -AutoSize

}

if ($port -eq "common"){
    $global:ports = @("ftp","dns","ssh","sql","oracle","telnet","smtp","nfs","vnc","http","https")
    filterHosts
} else {
    $global:ports = $port
    filterHosts
}