Write-Host "Readings hosts from *-http-hosts.txt."
#[System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$true}
gc "*-http-hosts.txt" | ForEach-Object {
$options = 0
$raw = 0
write-host -ForegroundColor green "Requesting options from"$_
$options = Invoke-WebRequest -uri $_ -Method Options -TimeoutSec 20 -ErrorAction Ignore -WarningAction Ignore
$_ | Out-File -Append http-notes.txt
$options.RawContent | Out-File -append http-notes.txt
$raw = Invoke-WebRequest -uri $_  -ErrorAction SilentlyContinue -WarningAction SilentlyContinue -TimeoutSec 20
write-host -ForegroundColor green "$_"$raw.StatusCode $raw.StatusDescription
$raw.Content | Out-File "$_-web-raw.html"
Write-Host -ForegroundColor green "$_ complete."
}