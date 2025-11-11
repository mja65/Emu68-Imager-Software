function Confirm-Scaling {
    param (

    )

   
    try {
        [void][DPI]
        
    } catch {
        
        Add-Type @'
            using System;
            using System.Runtime.InteropServices;
            using System.Drawing;
        
            public class DPI {
                [DllImport("gdi32.dll")]
                static extern int GetDeviceCaps(IntPtr hdc, int nIndex);
            
                public enum DeviceCap {
                    VERTRES = 10,
                    DESKTOPVERTRES = 117
                }
            
                // Calculates the desktop scaling ratio (e.g., 1.25 for 125% scaling)
                public static float scaling() {
                    Graphics g = Graphics.FromHwnd(IntPtr.Zero);
                    IntPtr desktop = g.GetHdc();
                    int LogicalScreenHeight = GetDeviceCaps(desktop, (int)DeviceCap.VERTRES);
                    int PhysicalScreenHeight = GetDeviceCaps(desktop, (int)DeviceCap.DESKTOPVERTRES);
            
                    // Release the device context handle and dispose of the Graphics object
                    g.ReleaseHdc(desktop); 
                    g.Dispose();
                    
                    return (float)PhysicalScreenHeight / (float)LogicalScreenHeight;
                }
            }
'@ -ReferencedAssemblies 'System.Drawing.dll'
    }

    $ScalingRatio = [Math]::Round([DPI]::scaling(), 2) * 100

    if ($ScalingRatio -ne 100){
        Write-Warning "You have the scale and layout of your desktop set to to $($ScalingRatio)%! Setting this to anything other than 100% will result in issues! Use of the GUI will be affected."
        return $false
    }
    else {
        return $true
    }
}