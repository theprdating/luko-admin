from PIL import Image
import os

src     = r'D:\Startup\Luko\app\assets\images\app_icon_white.png'
base    = r'D:\Startup\Luko\app\android\app\src\main\res'

# height=240dp, width=169dp (ratio 2018:2861)
# 比之前 160dp 大 50%，保留更多細節
sizes = [
    ('drawable-mdpi',    169, 240),   # 1x
    ('drawable-hdpi',    254, 360),   # 1.5x
    ('drawable-xhdpi',   338, 480),   # 2x
    ('drawable-xxhdpi',  507, 720),   # 3x
    ('drawable-xxxhdpi', 676, 960),   # 4x
]

orig = Image.open(src).convert('RGBA')
print(f'Original: {orig.size[0]}x{orig.size[1]}px')

for folder, w, h in sizes:
    dest = os.path.join(base, folder, 'app_icon_white.png')
    # LANCZOS (Sinc) — best quality for downscaling
    resized = orig.resize((w, h), Image.LANCZOS)
    resized.save(dest, 'PNG', optimize=True)
    print(f'OK {folder}: {w}x{h}px')

print('Done.')
