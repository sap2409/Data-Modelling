#!/usr/bin/env python3
"""Generate LinkedIn carousel slides for Momentum app."""

from __future__ import annotations

import os
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont, ImageFilter

ROOT = Path(__file__).resolve().parents[1]
ASSETS = ROOT / "assets"
OUTPUT = ROOT / "carousel"
OUTPUT.mkdir(exist_ok=True)

W, H = 1080, 1080
NAVY = (0, 71, 171)
NAVY_DARK = (0, 45, 110)
WHITE = (255, 255, 255)
LIGHT_BLUE = (230, 240, 255)
GRAY = (120, 130, 150)
ACCENT_GREEN = (34, 197, 94)

FONT_BOLD = "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"
FONT_REG = "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"


def load_font(size: int, bold: bool = False) -> ImageFont.FreeTypeFont:
    return ImageFont.truetype(FONT_BOLD if bold else FONT_REG, size)


def gradient_bg(draw: ImageDraw.ImageDraw, top: tuple, bottom: tuple) -> None:
    for y in range(H):
        t = y / H
        r = int(top[0] * (1 - t) + bottom[0] * t)
        g = int(top[1] * (1 - t) + bottom[1] * t)
        b = int(top[2] * (1 - t) + bottom[2] * t)
        draw.line([(0, y), (W, y)], fill=(r, g, b))


def wrap_text(text: str, font: ImageFont.FreeTypeFont, max_width: int) -> list[str]:
    words = text.split()
    lines: list[str] = []
    current: list[str] = []
    for word in words:
        trial = " ".join(current + [word])
        if font.getbbox(trial)[2] <= max_width:
            current.append(word)
        else:
            if current:
                lines.append(" ".join(current))
            current = [word]
    if current:
        lines.append(" ".join(current))
    return lines


def draw_centered_text(
    draw: ImageDraw.ImageDraw,
    text: str,
    y: int,
    font: ImageFont.FreeTypeFont,
    fill: tuple,
    max_width: int = 920,
    line_gap: int = 12,
) -> int:
    lines = wrap_text(text, font, max_width)
    line_heights = [font.getbbox(line)[3] - font.getbbox(line)[1] for line in lines]
    total_h = sum(line_heights) + line_gap * (len(lines) - 1)
    cy = y
    for i, line in enumerate(lines):
        bbox = font.getbbox(line)
        tw = bbox[2] - bbox[0]
        draw.text(((W - tw) // 2, cy), line, font=font, fill=fill)
        cy += line_heights[i] + line_gap
    return cy


def add_phone_screenshot(base: Image.Image, screenshot_path: Path, y_offset: int = 200) -> None:
    shot = Image.open(screenshot_path).convert("RGBA")
    target_h = 780
    scale = target_h / shot.height
    target_w = int(shot.width * scale)
    shot = shot.resize((target_w, target_h), Image.Resampling.LANCZOS)

    # Soft shadow
    shadow = Image.new("RGBA", (target_w + 40, target_h + 40), (0, 0, 0, 0))
    shadow_draw = ImageDraw.Draw(shadow)
    shadow_draw.rounded_rectangle(
        [20, 20, target_w + 20, target_h + 20],
        radius=36,
        fill=(0, 30, 80, 90),
    )
    shadow = shadow.filter(ImageFilter.GaussianBlur(18))
    sx = (W - target_w) // 2 - 10
    sy = y_offset - 6
    base.paste(shadow, (sx, sy), shadow)

    # Phone frame
    frame_pad = 14
    frame = Image.new("RGBA", (target_w + frame_pad * 2, target_h + frame_pad * 2), (0, 0, 0, 0))
    frame_draw = ImageDraw.Draw(frame)
    frame_draw.rounded_rectangle(
        [0, 0, target_w + frame_pad * 2 - 1, target_h + frame_pad * 2 - 1],
        radius=42,
        fill=WHITE + (255,),
        outline=(210, 220, 235, 255),
        width=3,
    )
    fx = (W - target_w - frame_pad * 2) // 2
    fy = y_offset - frame_pad
    base.paste(frame, (fx, fy), frame)
    base.paste(shot, ((W - target_w) // 2, y_offset), shot)


def slide_badge(draw: ImageDraw.ImageDraw, num: int, total: int) -> None:
    label = f"{num}/{total}"
    font = load_font(28)
    bbox = font.getbbox(label)
    tw, th = bbox[2] - bbox[0], bbox[3] - bbox[1]
    x, y = W - tw - 56, 48
    draw.rounded_rectangle(
        [x - 18, y - 10, x + tw + 18, y + th + 10],
        radius=20,
        fill=(255, 255, 255, 40),
    )
    draw.text((x, y), label, font=font, fill=LIGHT_BLUE)


def make_cover() -> Image.Image:
    img = Image.new("RGB", (W, H), NAVY)
    draw = ImageDraw.Draw(img)
    gradient_bg(draw, (0, 82, 190), NAVY_DARK)

    # Decorative circles
    draw.ellipse([720, -80, 1080, 220], fill=(255, 255, 255, 18))
    draw.ellipse([-120, 700, 280, 1100], fill=(255, 255, 255, 12))

    title_font = load_font(86, bold=True)
    sub_font = load_font(38)
    tag_font = load_font(30)

    draw_centered_text(draw, "Momentum", 180, title_font, WHITE)
    draw_centered_text(
        draw,
        "One app to plan your day, track your health, and stay in flow.",
        310,
        sub_font,
        LIGHT_BLUE,
        max_width=860,
    )

    # Feature pills
    pills = ["Time blocking", "Activity library", "Steps & macros", "Daily insights"]
    pill_font = load_font(26, bold=True)
    start_x = 90
    y = 520
    x = start_x
    for pill in pills:
        bbox = pill_font.getbbox(pill)
        pw = bbox[2] - bbox[0] + 44
        ph = 52
        draw.rounded_rectangle([x, y, x + pw, y + ph], radius=26, fill=WHITE)
        draw.text((x + 22, y + 12), pill, font=pill_font, fill=NAVY)
        x += pw + 16
        if x > W - 120:
            x = start_x
            y += 68

    draw_centered_text(draw, "Swipe →", 920, tag_font, LIGHT_BLUE)
    return img


def make_feature_slide(
    headline: str,
    subline: str,
    screenshot: Path,
    slide_num: int,
    total: int,
) -> Image.Image:
    img = Image.new("RGB", (W, H), WHITE)
    draw = ImageDraw.Draw(img)

    # Top brand bar
    draw.rectangle([0, 0, W, 8], fill=NAVY)

    headline_font = load_font(52, bold=True)
    sub_font = load_font(30)

    draw_centered_text(draw, headline, 56, headline_font, NAVY, max_width=940)
    draw_centered_text(draw, subline, 148, sub_font, GRAY, max_width=900)

    add_phone_screenshot(img, screenshot, y_offset=210)
    slide_badge(draw, slide_num, total)
    return img


def make_cta() -> Image.Image:
    img = Image.new("RGB", (W, H), NAVY)
    draw = ImageDraw.Draw(img)
    gradient_bg(draw, NAVY, (0, 35, 90))

    title_font = load_font(64, bold=True)
    body_font = load_font(34)
    cta_font = load_font(40, bold=True)

    draw_centered_text(draw, "Built for people who want structure without the noise.", 220, title_font, WHITE, max_width=900)
    draw_centered_text(
        draw,
        "Plan blocks. Track steps. Hit your macros. All in one calm dashboard.",
        420,
        body_font,
        LIGHT_BLUE,
        max_width=860,
    )

    # CTA button
    btn_text = "Comment MOMENTUM for early access"
    bbox = cta_font.getbbox(btn_text)
    tw = bbox[2] - bbox[0]
    bx1 = (W - tw - 80) // 2
    by1 = 640
    bx2 = bx1 + tw + 80
    by2 = by1 + 72
    draw.rounded_rectangle([bx1, by1, bx2, by2], radius=36, fill=WHITE)
    draw.text((bx1 + 40, by1 + 16), btn_text, font=cta_font, fill=NAVY)

    draw_centered_text(draw, "Save this post · Share with a friend who needs a better daily system", 820, load_font(26), GRAY)
    return img


def main() -> None:
    slides = [
        ("01-cover.png", None),
        (
            "02-today.png",
            {
                "headline": "See your whole day at a glance",
                "subline": "Completed vs pending, steps, macros, and today's flow — one screen.",
                "screenshot": ASSETS / "2A910C17-16F7-4DE2-8CDC-BF75801B7480_L0_001.jpg",
            },
        ),
        (
            "03-library.png",
            {
                "headline": "Build your activity library once",
                "subline": "Deep work blocks, health routines, and personal tasks — reusable every day.",
                "screenshot": ASSETS / "C08D48A5-C0F1-4939-BD9E-8E62C4CD53E2_L0_001.jpg",
            },
        ),
        (
            "04-insights.png",
            {
                "headline": "Track movement without extra apps",
                "subline": "Live step counting, distance, and calories while Momentum stays open.",
                "screenshot": ASSETS / "757200F4-AA45-446C-978E-F79CDEDAEBC0_L0_001.jpg",
            },
        ),
        (
            "05-macros.png",
            {
                "headline": "Know your numbers. Hit your targets.",
                "subline": "Built-in macro calculator with daily protein, carbs, and fat progress.",
                "screenshot": ASSETS / "45367CCC-5457-49FC-8E49-70A56A7882DE_L0_001.jpg",
            },
        ),
        ("06-cta.png", None),
    ]

    total = len(slides)
    for i, (filename, data) in enumerate(slides, start=1):
        if data is None:
            if filename.startswith("01"):
                img = make_cover()
            else:
                img = make_cta()
        else:
            img = make_feature_slide(
                data["headline"],
                data["subline"],
                data["screenshot"],
                i,
                total,
            )
        out = OUTPUT / filename
        img.save(out, "PNG", optimize=True)
        print(f"Wrote {out}")


if __name__ == "__main__":
    main()
