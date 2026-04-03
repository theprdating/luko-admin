# WPF 渲染管線 — 比 GDI+ 品質更高（使用 Windows Imaging Component）
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase

$srcPath = 'D:\Startup\Luko\app\assets\images\app_icon_white.png'
$baseDir = 'D:\Startup\Luko\app\android\app\src\main\res'

# 目標：height=240dp (width=169dp), 比上一次的160dp更大 → 保留更多細節
# 2018:2861 ratio, height=240 -> width = 240*(2018/2861) = 169.3dp
$sizes = @(
    @{ dir='drawable-mdpi';    w=169; h=240 },
    @{ dir='drawable-hdpi';    w=254; h=360 },
    @{ dir='drawable-xhdpi';   w=338; h=480 },
    @{ dir='drawable-xxhdpi';  w=507; h=720 },
    @{ dir='drawable-xxxhdpi'; w=676; h=960 }
)

# 載入原始圖（用 WPF BitmapImage，保持原始 DPI）
$uri    = [Uri]("file:///" + $srcPath.Replace('\', '/'))
$bitmap = New-Object System.Windows.Media.Imaging.BitmapImage
$bitmap.BeginInit()
$bitmap.UriSource          = $uri
$bitmap.CreateOptions      = [System.Windows.Media.Imaging.BitmapCreateOptions]::PreservePixelFormat
$bitmap.CacheOption        = [System.Windows.Media.Imaging.BitmapCacheOption]::OnLoad
$bitmap.EndInit()
$bitmap.Freeze()

foreach ($s in $sizes) {
    $w    = [int]$s.w
    $h    = [int]$s.h
    $dest = Join-Path (Join-Path $baseDir $s.dir) 'app_icon_white.png'

    # 用 DrawingVisual + RenderTargetBitmap 渲染
    $rtb = New-Object System.Windows.Media.Imaging.RenderTargetBitmap(
        $w, $h, 96, 96,
        [System.Windows.Media.PixelFormats]::Pbgra32
    )
    $dv  = New-Object System.Windows.Media.DrawingVisual
    $ctx = $dv.RenderOpen()
    $ctx.DrawImage($bitmap, [System.Windows.Rect]::new(0, 0, $w, $h))
    $ctx.Close()
    $rtb.Render($dv)

    # 存成 PNG
    $enc = New-Object System.Windows.Media.Imaging.PngBitmapEncoder
    $enc.Frames.Add([System.Windows.Media.Imaging.BitmapFrame]::Create($rtb))
    $fs  = [System.IO.FileStream]::new($dest, [System.IO.FileMode]::Create)
    $enc.Save($fs)
    $fs.Close()

    Write-Host "OK $($s.dir): ${w}x${h}px (= \$([int]($w/([float]$s.dir.Split('-')[1].Replace('mdpi','1').Replace('hdpi','1.5').Replace('xhdpi','2').Replace('xxhdpi','3').Replace('xxxhdpi','4'))))dp)"
}
Write-Host 'Done.'
