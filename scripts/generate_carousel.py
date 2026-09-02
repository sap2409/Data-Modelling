#!/usr/bin/env python3
"""Generate LinkedIn carousel slides (1080x1080) for Momentum."""

from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = Path(__file__).resolve().parents[1]
ASSETS = ROOT / "assets"
OUTPUT = ROOT / "carousel"
OUTPUT.mkdir(exist_ok=True)

W, H = 1080, 1080
NAVY = (8, 58, 138)
NAVY_MID = (14, 90, 196)
NAVY_DARK = (4, 32, 82)
WHITE = (255, 255, 255)
OFF_WHITE = (246, 249, 255)
LIGHT_BLUE = (219, 232, 255)
SOFT_BLUE = (236, 243, 255)
GRAY = (90, 104, 128)
MUTED = (160, 176, 200)

FONT_BOLD = "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"
FONT_REG = "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"

TODAY = ASSETS / "2A910C17-16F7-4DE2-8CDC-BF75801B7480_L0_001.jpg"
LIBRARY = ASSETS / "C08D48A5-C0F1-4939-BD9E-8E62C4CD53E2_L0_001.jpg"
INSIGHTS = ASSETS / "757200F4-AA45-446C-978E-F79CDEDAEBC0_L0_001.jpg"
MACROS = ASSETS / "45367CCC-5457-49FC-8E49-70A56A7882DE_L0_001.jpg"


def load_font(size: int, bold: bool = False) -> ImageFont.FreeTypeFont:
    return ImageFont.truetype(FONT_BOLD if bold else FONT_REG, size)


def gradient_fill(img: Image.Image, top: tuple[int, int, int], bottom: tuple[int, int, int]) -> None:
    px = img.load()
    for y in range(H):
        t = y / (H - 1)
        color = (
            int(top[0] * (1 - t) + bottom[0] * t),
            int(top[1] * (1 - t) + bottom[1] * t),
            int(top[2] * (1 - t) + bottom[2] * t),
        )
        for x in range(W):
            px[x, y] = color


def wrap_text(text: str, font: ImageFont.FreeTypeFont, max_width: int) -> list[str]:
    words = text.split()
    lines: list[str] = []
    current: list[str] = []
    for word in words:
        trial = " ".join(current + [word])
        if font.getlength(trial) <= max_width:
            current.append(word)
        else:
            if current:
                lines.append(" ".join(current))
            current = [word]
    if current:
        lines.append(" ".join(current))
    return lines


def text_size(font: ImageFont.FreeTypeFont, text: str) -> tuple[int, int]:
    bbox = font.getbbox(text)
    return bbox[2] - bbox[0], bbox[3] - bbox[1]


def draw_centered_text(
    draw: ImageDraw.ImageDraw,
    text: str,
    y: int,
    font: ImageFont.FreeTypeFont,
    fill: tuple[int, int, int],
    max_width: int = 920,
    line_gap: int = 10,
) -> int:
    lines = wrap_text(text, font, max_width)
    cy = y
    for i, line in enumerate(lines):
        tw, th = text_size(font, line)
        draw.text(((W - tw) // 2, cy), line, font=font, fill=fill)
        cy += th + line_gap
    return cy


def rounded_shot(path: Path, target_h: int, radius: int = 48) -> Image.Image:
    shot = Image.open(path).convert("RGBA")
    # Trim a thin status-bar crop so more UI is visible.
    crop_top = int(shot.height * 0.012)
    shot = shot.crop((0, crop_top, shot.width, shot.height))
    scale = target_h / shot.height
    target_w = max(1, int(shot.width * scale))
    shot = shot.resize((target_w, target_h), Image.Resampling.LANCZOS)
    mask = Image.new("L", shot.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, target_w - 1, target_h - 1], radius=radius, fill=255)
    shot.putalpha(mask)
    return shot


def paste_phone(base: Image.Image, shot: Image.Image, y: int, x: int | None = None) -> tuple[int, int]:
    target_w, target_h = shot.size
    pad = 10
    frame_w, frame_h = target_w + pad * 2, target_h + pad * 2
    if x is None:
        x = (W - frame_w) // 2

    shadow = Image.new("RGBA", (frame_w + 50, frame_h + 50), (0, 0, 0, 0))
    ImageDraw.Draw(shadow).rounded_rectangle(
        [18, 22, frame_w + 18, frame_h + 22],
        radius=56,
        fill=(8, 30, 70, 70),
    )
    shadow = shadow.filter(ImageFilter.GaussianBlur(16))
    base.paste(shadow, (x - 18, y - 10), shadow)

    overlay = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay)
    draw.rounded_rectangle(
        [x, y, x + frame_w - 1, y + frame_h - 1],
        radius=54,
        fill=(255, 255, 255, 255),
        outline=(210, 222, 240, 255),
        width=3,
    )
    base.paste(overlay, (0, 0), overlay)
    base.paste(shot, (x + pad, y + pad), shot)
    return x, y + frame_h


def slide_chip(draw: ImageDraw.ImageDraw, num: int, total: int, fill: tuple[int, int, int] = NAVY) -> None:
    label = f"{num} / {total}"
    font = load_font(22, bold=True)
    tw, th = text_size(font, label)
    x, y = W - tw - 70, 36
    draw.rounded_rectangle([x - 16, y - 8, x + tw + 16, y + th + 10], radius=18, fill=SOFT_BLUE)
    draw.text((x, y), label, font=font, fill=fill)


def make_cover() -> Image.Image:
    img = Image.new("RGB", (W, H))
    gradient_fill(img, NAVY_MID, NAVY_DARK)
    overlay = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    od = ImageDraw.Draw(overlay)
    od.ellipse([640, -160, 1240, 440], fill=(255, 255, 255, 22))
    od.ellipse([-280, 760, 360, 1280], fill=(255, 255, 255, 16))
    img.paste(overlay, (0, 0), overlay)
    draw = ImageDraw.Draw(img)

    kicker_font = load_font(24, bold=True)
    kicker = "PRODUCTIVITY + HEALTH, ONE APP"
    kw, kh = text_size(kicker_font, kicker)
    kx = (W - kw) // 2
    draw.rounded_rectangle([kx - 22, 56, kx + kw + 22, 56 + kh + 20], radius=22, fill=(255, 255, 255, 255))
    draw.text((kx, 66), kicker, font=kicker_font, fill=NAVY)

    draw_centered_text(draw, "Your day shouldn't need 4 apps.", 130, load_font(58, bold=True), WHITE, max_width=920, line_gap=8)
    draw_centered_text(
        draw,
        "Momentum puts time-blocking, a reusable activity library, live steps, and macro targets on one calm dashboard.",
        280,
        load_font(28),
        LIGHT_BLUE,
        max_width=880,
        line_gap=8,
    )

    shot = rounded_shot(TODAY, target_h=520, radius=42)
    paste_phone(img, shot, y=430)

    draw = ImageDraw.Draw(img)
    draw_centered_text(draw, "Swipe to see the product  →", 1008, load_font(24, bold=True), LIGHT_BLUE)
    return img


def make_feature_slide(
    kicker: str,
    headline: str,
    subline: str,
    screenshot: Path,
    slide_num: int,
    total: int,
) -> Image.Image:
    img = Image.new("RGB", (W, H), OFF_WHITE)
    draw = ImageDraw.Draw(img)
    draw.rectangle([0, 0, W, 10], fill=NAVY)

    kicker_font = load_font(22, bold=True)
    kw, kh = text_size(kicker_font, kicker)
    kx = (W - kw) // 2
    draw.rounded_rectangle([kx - 16, 32, kx + kw + 16, 32 + kh + 16], radius=16, fill=SOFT_BLUE)
    draw.text((kx, 40), kicker, font=kicker_font, fill=NAVY)

    hy = draw_centered_text(draw, headline, 86, load_font(44, bold=True), NAVY, max_width=940, line_gap=6)
    draw_centered_text(draw, subline, hy + 10, load_font(26), GRAY, max_width=900, line_gap=6)

    shot = rounded_shot(screenshot, target_h=700, radius=44)
    paste_phone(img, shot, y=278)
    slide_chip(draw, slide_num, total)
    return img


def make_cta() -> Image.Image:
    img = Image.new("RGB", (W, H))
    gradient_fill(img, NAVY, NAVY_DARK)
    overlay = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    ImageDraw.Draw(overlay).ellipse([700, 700, 1280, 1280], fill=(255, 255, 255, 18))
    img.paste(overlay, (0, 0), overlay)
    draw = ImageDraw.Draw(img)

    draw_centered_text(draw, "Structure without the noise.", 90, load_font(52, bold=True), WHITE, max_width=900)

    items = [
        ("1", "Plan the day", "Reusable blocks from your library"),
        ("2", "Stay in motion", "Live steps, distance, and calories"),
        ("3", "Hit your fuel", "Macros calculated for your goal"),
    ]
    y = 230
    item_font = load_font(30, bold=True)
    body_font = load_font(24)
    num_font = load_font(28, bold=True)
    for num, title, body in items:
        draw.rounded_rectangle([90, y, 990, y + 110], radius=28, fill=(255, 255, 255, 255))
        draw.ellipse([120, y + 28, 184, y + 92], fill=NAVY)
        nw, nh = text_size(num_font, num)
        draw.text((152 - nw // 2, y + 60 - nh // 2), num, font=num_font, fill=WHITE)
        draw.text((214, y + 26), title, font=item_font, fill=NAVY)
        draw.text((214, y + 64), body, font=body_font, fill=GRAY)
        y += 128

    btn = "Comment MOMENTUM for early access"
    btn_font = load_font(30, bold=True)
    tw, th = text_size(btn_font, btn)
    bx1 = (W - tw - 72) // 2
    by1 = 780
    draw.rounded_rectangle([bx1, by1, bx1 + tw + 72, by1 + 72], radius=36, fill=WHITE)
    draw.text((bx1 + 36, by1 + (72 - th) // 2 - 2), btn, font=btn_font, fill=NAVY)

    draw_centered_text(
        draw,
        "Save this · Share it with someone who still switches between planner, steps, and macros.",
        890,
        load_font(24),
        MUTED,
        max_width=860,
        line_gap=8,
    )
    return img


def main() -> None:
    slides: list[tuple[str, Image.Image]] = [
        ("01-cover.png", make_cover()),
        (
            "02-today.png",
            make_feature_slide(
                "TODAY",
                "See the whole day at a glance",
                "Completed vs pending, steps, macros, and today's flow — one screen.",
                TODAY,
                2,
                6,
            ),
        ),
        (
            "03-library.png",
            make_feature_slide(
                "LIBRARY",
                "Build your activity library once",
                "Deep work, health, and personal blocks — search, filter, reuse every day.",
                LIBRARY,
                3,
                6,
            ),
        ),
        (
            "04-insights.png",
            make_feature_slide(
                "INSIGHTS",
                "Track movement without extra apps",
                "Live step counting, distance, and calories while Momentum stays open.",
                INSIGHTS,
                4,
                6,
            ),
        ),
        (
            "05-macros.png",
            make_feature_slide(
                "MACROS",
                "Know your numbers. Hit your targets.",
                "Built-in calculator for calories, protein, carbs, and fat — with daily progress.",
                MACROS,
                5,
                6,
            ),
        ),
        ("06-cta.png", make_cta()),
    ]

    pdf_pages: list[Image.Image] = []
    for filename, img in slides:
        out = OUTPUT / filename
        img.save(out, "PNG", optimize=True)
        pdf_pages.append(img.convert("RGB"))
        print(f"Wrote {out}")

    pdf_path = OUTPUT / "Momentum-LinkedIn-Carousel.pdf"
    pdf_pages[0].save(
        pdf_path,
        save_all=True,
        append_images=pdf_pages[1:],
        resolution=150,
    )
    print(f"Wrote {pdf_path}")


if __name__ == "__main__":
    main()
