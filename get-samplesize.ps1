$input = read-host "Enter the name of a file to read from"
$output = "samplehosts.txt"
$count = read-host "Enter the number of hosts you want to sample"
$ip = (gc $input)
$list = @()
$i = 0

do {

$list += $ip[(get-random $ip.count)]
$i = $i + 1

}
until ($i -eq $count)
write-host -ForegroundColor green "Gathered $count hosts from $input and saved to $output"
$list | Out-File -Encoding ascii $output