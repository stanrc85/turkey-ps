#script to parse GNMAP files (created by Turkey or nmap) to show all Operating systems
#output is table of devices with ip and OS
#by Ryan Stanley
#created 3/10/2014 v1
#5/21/14 - no more warnings, better OS detection

#to do:

#usage: .\get-os.ps1
#defaults to use *-scan.gnmap

Param(
  [Parameter(Mandatory=$False,Position=1)]
   [string]$file
)
if ($file -eq ""){
    $file = "./*.gnmap"
}
$obj = @()

$hosts = @()
$hosts = (gc $file | ? {$_.contains("OS: ")})
foreach ($line in $hosts){
    $ip = $line.split("`t")[0].trimstart("Host: ").split(" ")[0]
    $stuff = $line.split("`t")
    foreach ($line2 in ($stuff)){
    if ($line2.contains("OS: ")){
    $os = $line2.trimstart("OS: ")     
    if ($obj.ip -match $ip){}
        else {
        $obj += new-object psobject -property @{
            IP = $ip
            OS = $os         
            }
         }
}
else { $os = "Unknown"}
}
}
    
$obj | select -Unique ip,os

