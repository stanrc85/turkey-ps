#script to parse GNMAP files (not created by Turkey) to sort hosts based on keywords
#output is text files with hosts
#by Ryan Stanley
#updated 2/4/2014

#usage: .\sorts *filename*


Param(
  [Parameter(Mandatory=$True,Position=1)]
   [string]$file
)

###################
#Filter hosts     #
###################
Function filterHosts
{
###################
#add more "keywords" to this arrary to sort results by
$keywords = @("windows","linux","solaris","unix","esx","cisco","printer","http","sql","ssh","dns","smtp","oracle","ftp","telnet","nfs")
###################
#$sorts = read-host "Enter the name of the nmap scan to filter"
for ($k=0; $k -lt $keywords.length; $k++)
{
$word = $keywords[$k]
rm "$file-$word-hosts.txt" -WarningAction SilentlyContinue -ErrorAction SilentlyContinue
$sorts = (gc "$file.gnmap" | ? {$_.contains("Ports:")})
foreach ($sort in $sorts){
    $os = $sort.split("`t")[2].split(":")[1].trim()
    if ($os -match("$word")){
        $sort.split("`t")[0].trimstart("Host: ").trimend(" ()") | Out-File -Append -Encoding ascii "$file-$word-hosts.txt"
       write-host -ForegroundColor green "." -NoNewline
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

write-host "`n`n"
for ($k=0; $k -lt $keywords.length; $k++)
{
$word = $keywords[$k]
if (Test-Path ".\$file-$word-hosts.txt"){
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

filterHosts