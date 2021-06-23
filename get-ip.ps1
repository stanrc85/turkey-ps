#script to parse GNMAP files (created by Turkey) to show all IP
#output is table of devices with ip
#by Ryan Stanley
#updated 3/10/2014

#usage: .\get-ip.ps1
#defaults to use *-scan.gnmap

Param(
  [Parameter(Mandatory=$False,Position=1)]
   [string]$file
)
if ($file -eq ""){
    $file = "./*-scan.gnmap"
}
$obj = @()

$hosts = @()
$hosts = (gc $file | ? {$_.contains("Ports:")})
foreach ($line in $hosts){
    $ip = $line.split("`t")[0].trimstart("Host: ").trimend(" ").split(" ")[0].trimend(" ")
    
    $open = $line.split("`t")[1].split(":").split(",").trim()
    foreach ($line2 in $open){
    if ($line2 -ne "Ports: "){
        $obj += new-object psobject -property @{
            #host = $hostname
            IP = $ip
                   
            }

    }
    }
}


$obj | select -Unique ip