Add-Type -AssemblyName System.Drawing

$src     = 'D:\Startup\Luko\app\assets\images\app_icon_white.png'
$baseDir = 'D:\Startup\Luko\app\android\app\src\main\res'
$orig    = [System.Drawing.Image]::FromFile($src)

$sizes = @(
    @{ dir='drawable-mdpi';    w=113; h=160 },
    @{ dir='drawable-hdpi';    w=170; h=240 },
    @{ dir='drawable-xhdpi';   w=226; h=320 },
    @{ dir='drawable-xxhdpi';  w=339; h=480 },
    @{ dir='drawable-xxxhdpi'; w=452; h=640 }
)

foreach ($s in $sizes) {
    $w    = [int]$s.w
    $h    = [int]$s.h
    $dest = Join-Path (Join-Path $baseDir $s.dir) 'app_icon_white.png'

    $bmp = New-Object System.Drawing.Bitmap($w, $h)
    $g   = [System.Drawing.Graphics]::FromImage($bmp)
    $g.InterpolationMode  = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.SmoothingMode      = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $g.PixelOffsetMode    = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $g.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
    $g.Clear([System.Drawing.Color]::Transparent)
    $g.DrawImage($orig, 0, 0, $w, $h)
    $bmp.Save($dest, [System.Drawing.Imaging.ImageFormat]::Png)
    $g.Dispose()
    $bmp.Dispose()
    Write-Host "OK $($s.dir): ${w}x${h}px"
}
$orig.Dispose()
Write-Host 'Done.'
