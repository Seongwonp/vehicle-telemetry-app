"""assets/logo_icon.png(RGBA)에서 Android 런처 아이콘과 시작 화면 이미지를 만든다. 실행: py -3 tool/make_android_icons.py (Pillow 필요)."""
from pathlib import Path
from PIL import Image

APP = Path(r"D:\vehicle-telemetry-app")
RES = APP / "android/app/src/main/res"
logo = Image.open(APP / "assets/logo_icon.png").convert("RGBA")
logo = logo.crop(logo.getbbox())  # 투명 여백 제거

DENS = {"mdpi": 1, "hdpi": 1.5, "xhdpi": 2, "xxhdpi": 3, "xxxhdpi": 4}


# 런처 아이콘용 흰 로고 — 가는 선의 파란 로고는 흰 바탕 48dp에서 거의 안 보였다(2026-09-16 에뮬레이터).
white_logo = Image.new("RGBA", logo.size, (255, 255, 255, 0))
white_logo.putalpha(logo.getchannel("A"))
BRAND = (36, 87, 214, 255)  # app_theme.dart primary #2457D6


def place(canvas_px: int, logo_width_px: int, bg=(0, 0, 0, 0), src=None) -> Image.Image:
    src = src or logo
    canvas = Image.new("RGBA", (canvas_px, canvas_px), bg)
    w = logo_width_px
    h = round(src.height * w / src.width)
    scaled = src.resize((w, h), Image.LANCZOS)
    canvas.alpha_composite(scaled, ((canvas_px - w) // 2, (canvas_px - h) // 2))
    return canvas


for name, d in DENS.items():
    # 적응형 아이콘 전경: 108dp 캔버스. 원형 마스크(지름 72dp) 안에 모서리까지 들어가는 최대 폭 68dp
    # (가로:세로 약 3.2:1이라 모서리 (34, 10.6)dp가 반지름 36dp 안이다).
    fg = place(round(108 * d), round(68 * d), src=white_logo)
    (RES / f"mipmap-{name}").mkdir(parents=True, exist_ok=True)
    fg.save(RES / f"mipmap-{name}/ic_launcher_foreground.png", optimize=True)

    # 적응형을 모르는 기기(API 25 이하)용 48dp 아이콘: 브랜드 파랑 바탕 위 흰 로고.
    legacy = place(round(48 * d), round(42 * d), bg=BRAND, src=white_logo)
    legacy.save(RES / f"mipmap-{name}/ic_launcher.png", optimize=True)

    # Android 12+ 시작 화면 아이콘: 240dp 캔버스, 원 지름 160dp 안(폭 150dp).
    splash = place(round(240 * d), round(150 * d))
    (RES / f"drawable-{name}").mkdir(parents=True, exist_ok=True)
    splash.save(RES / f"drawable-{name}/splash_icon.png", optimize=True)

    # Android 11 이하 시작 화면: 가운데 로고 비트맵(폭 160dp).
    w = round(160 * d)
    h = round(logo.height * w / logo.width)
    logo.resize((w, h), Image.LANCZOS).save(RES / f"drawable-{name}/splash_logo.png", optimize=True)

print("ok", logo.size)
