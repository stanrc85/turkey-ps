#script to start tshark with optimal switches for logging to file in folder of choosing
#also outputs to screen to serve as troubleshooting aid for network issues
#5/4/2012
write-host -ForegroundColor green "Script to start tshark"
$filename = read-host "Enter a filename"
$tshark = 'C:\Program Files\Wireshark\tshark.exe'
write-host "tshark logs will be saved in the current directory with the filename prefix: " $filename
Write-Host ""
Start-Process -FilePath 'C:\Program Files\Wireshark\tshark.exe' -ArgumentList "-D" -NoNewWindow -Wait
Write-Host ""
$i = Read-Host "Select which interface you would like to use"
Write-Host "Starting tshark." -ForegroundColor green
#modify "argument list" as needed
#-i for interface, 1 should be the physical nic
#-b filesize, change how big to let the file get before splitting
#-w name of output file will match folder name provided, will automatically append data and time stamp
#-S outputs to screen as well, useful for troubleshooting network issues
Start-Process -FilePath 'C:\Program Files\Wireshark\tshark.exe' -ArgumentList "-i $i -b filesize:100000 -w $filename" -NoNewWindow