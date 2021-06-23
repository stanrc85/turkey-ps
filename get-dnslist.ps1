#script to parse txt files (created by Turkey) to show all hosts and domain names
#output is table of devices with ip and hostname
#by Ryan Stanley
#updated 2/4/2014

#usage: .\get-dnslist.ps1 *filename*
#defaults to use *-reverse-dns.txt

Param(
  [Parameter(Mandatory=$False,Position=1)]
   [string]$file
)
if ($file -eq ""){
    $file = "./*-reverse-dns.txt"
}
$obj = @()

$hosts = @()
$hosts = (gc $file | ? {$_.contains("Host:")})

foreach ($line in $hosts){
    $ip = $line.split("`t")[0].trimstart("Host: ").trimend()
    $hostname = $ip.split(" ")[1].trimstart("(").trimend(")")
    $ip = $ip.split(" ")[0]
    $obj += new-object psobject -property @{
            Hostname = $hostname
            IP = $ip
    }
    }

$obj