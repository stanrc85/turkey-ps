$src = @'
using System;
using System.Runtime.InteropServices;

namespace PInvoke
{
    public static class NativeMethods 
    {
        [DllImport("user32.dll")]
        [return: MarshalAs(UnmanagedType.Bool)]
        public static extern bool GetWindowRect(IntPtr hWnd, out RECT lpRect);
    }

    [StructLayout(LayoutKind.Sequential)]
    public struct RECT
    {
        public int Left;        // x position of upper-left corner
        public int Top;         // y position of upper-left corner
        public int Right;       // x position of lower-right corner
        public int Bottom;      // y position of lower-right corner
    }
}
'@


Add-Type -TypeDefinition $src
Add-Type -AssemblyName System.Drawing

# Get a process object from which we will get the main window bounds
$procList = Get-Process -name iexplore
#$iseProc = Get-Process -id $pid
foreach ($iseProc in $procList){

$bmpScreenCap = $g = $null
try {
    $rect = new-object PInvoke.RECT
    if ([PInvoke.NativeMethods]::GetWindowRect($iseProc.MainWindowHandle, [ref]$rect))
    {
        $width = $rect.Right - $rect.Left + 1
        $height = $rect.Bottom - $rect.Top + 1
        $bmpScreenCap = new-object System.Drawing.Bitmap $width,$height
        $g = [System.Drawing.Graphics]::FromImage($bmpScreenCap)
        $g.CopyFromScreen($rect.Left, $rect.Top, 0, 0, $bmpScreenCap.Size, 
                          [System.Drawing.CopyPixelOperation]::SourceCopy)
        $bmpScreenCap.Save("$home\$iseProc.screenshot.bmp")
    }
}
finally {
    if ($bmpScreenCap) { $bmpScreenCap.Dispose() }
    if ($g) { $g.Dispose() }
}
}