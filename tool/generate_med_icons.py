import os
from PIL import Image, ImageDraw, ImageFilter
import math

SIZE = 768  # Supersampling size
FINAL_SIZE = 192  # Target notification largeIcon size

def create_base():
    """Create a high-res canvas with transparent background and a soft colored container"""
    im = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    return im

def add_container(draw, bg_color1, bg_color2, border_color):
    """Draw a modern rounded squircle container with gradient look"""
    padding = 40
    r = 180
    # Draw shadow
    shadow_offset = 16
    draw.rounded_rectangle(
        [padding, padding + shadow_offset, SIZE - padding, SIZE - padding + shadow_offset],
        radius=r,
        fill=(0, 0, 0, 45)
    )
    # Main badge
    draw.rounded_rectangle(
        [padding, padding, SIZE - padding, SIZE - padding],
        radius=r,
        fill=bg_color1,
        outline=border_color,
        width=12
    )

def draw_tablet():
    im = create_base()
    draw = ImageDraw.Draw(im)
    # Teal badge
    add_container(draw, (13, 148, 136, 255), (15, 118, 110, 255), (45, 212, 191, 220))
    
    # Center tablet circle
    cx, cy, r = 384, 384, 180
    # Tablet drop shadow
    draw.ellipse([cx - r, cy - r + 14, cx + r, cy + r + 14], fill=(0, 0, 0, 50))
    # Tablet outer bevel
    draw.ellipse([cx - r, cy - r, cx + r, cy + r], fill=(241, 245, 249, 255), outline=(203, 213, 225, 255), width=10)
    # Tablet inner rim
    draw.ellipse([cx - r + 24, cy - r + 24, cx + r - 24, cy + r - 24], fill=(255, 255, 255, 255))
    # Score line in the middle
    draw.line([cx - r + 45, cy, cx + r - 45, cy], fill=(203, 213, 225, 255), width=14)
    # Highlight arc on top edge
    draw.arc([cx - r + 30, cy - r + 30, cx + r - 30, cy + r - 30], start=200, end=340, fill=(255, 255, 255, 200), width=16)
    return im

def draw_capsule():
    im = create_base()
    draw = ImageDraw.Draw(im)
    # Warm Orange & Coral badge
    add_container(draw, (234, 88, 12, 255), (194, 65, 12, 255), (251, 146, 60, 220))
    
    # Angled capsule at -45 deg
    # Let's draw on horizontal canvas and rotate
    cap_canvas = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    cap_draw = ImageDraw.Draw(cap_canvas)
    
    w, h = 320, 140
    x0, y0 = (SIZE - w) // 2, (SIZE - h) // 2
    # Shadow
    cap_draw.rounded_rectangle([x0, y0 + 14, x0 + w, y0 + h + 14], radius=h // 2, fill=(0, 0, 0, 45))
    # Base rounded rect
    cap_draw.rounded_rectangle([x0, y0, x0 + w, y0 + h], radius=h // 2, fill=(255, 255, 255, 255), outline=(226, 232, 240, 255), width=8)
    
    # Left half: Coral Red
    mid_x = x0 + w // 2
    # Mask left half with pill shape
    left_mask = Image.new("L", (SIZE, SIZE), 0)
    left_draw = ImageDraw.Draw(left_mask)
    left_draw.rounded_rectangle([x0, y0, x0 + w, y0 + h], radius=h // 2, fill=255)
    left_draw.rectangle([mid_x, 0, SIZE, SIZE], fill=0)
    
    coral_layer = Image.new("RGBA", (SIZE, SIZE), (239, 68, 68, 255))
    cap_canvas.paste(coral_layer, (0, 0), left_mask)
    
    # Divider line
    cap_draw.line([mid_x, y0, mid_x, y0 + h], fill=(30, 41, 59, 200), width=6)
    # Gloss highlight
    cap_draw.rounded_rectangle([x0 + 40, y0 + 20, mid_x - 30, y0 + 44], radius=12, fill=(255, 255, 255, 180))
    cap_draw.rounded_rectangle([mid_x + 30, y0 + 20, x0 + w - 40, y0 + 44], radius=12, fill=(255, 255, 255, 180))
    
    # Rotate by -45 degrees
    rotated = cap_canvas.rotate(-45, resample=Image.Resampling.BICUBIC)
    im.alpha_composite(rotated)
    return im

def draw_syrup():
    im = create_base()
    draw = ImageDraw.Draw(im)
    # Amber Honey badge
    add_container(draw, (217, 119, 6, 255), (180, 83, 9, 255), (252, 211, 77, 220))
    
    # Bottle Cap
    draw.rounded_rectangle([324, 150, 444, 200], radius=14, fill=(241, 245, 249, 255), outline=(203, 213, 225, 255), width=8)
    # Bottle Neck
    draw.rectangle([344, 200, 424, 240], fill=(226, 232, 240, 255))
    # Bottle Body
    draw.rounded_rectangle([254, 240, 514, 590], radius=50, fill=(254, 243, 199, 255), outline=(255, 255, 255, 255), width=10)
    # Amber Liquid Fill
    draw.rounded_rectangle([264, 340, 504, 580], radius=40, fill=(245, 158, 11, 240))
    
    # Prescription Label
    draw.rounded_rectangle([284, 360, 484, 510], radius=24, fill=(255, 255, 255, 255), outline=(226, 232, 240, 255), width=6)
    # Red cross on label
    draw.rectangle([364, 390, 404, 480], fill=(220, 38, 38, 255))
    draw.rectangle([334, 420, 434, 450], fill=(220, 38, 38, 255))
    return im

def draw_injection():
    im = create_base()
    draw = ImageDraw.Draw(im)
    # Blue / Indigo clinical badge
    add_container(draw, (37, 99, 235, 255), (29, 78, 216, 255), (96, 165, 250, 220))
    
    inj_canvas = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    idraw = ImageDraw.Draw(inj_canvas)
    
    # Draw horizontal syringe
    # Needle
    idraw.line([120, 384, 260, 384], fill=(226, 232, 240, 255), width=10)
    # Syringe Hub
    idraw.rounded_rectangle([250, 364, 280, 404], radius=6, fill=(148, 163, 184, 255))
    # Barrel
    idraw.rounded_rectangle([280, 324, 540, 444], radius=16, fill=(248, 250, 252, 230), outline=(255, 255, 255, 255), width=8)
    # Liquid inside barrel
    idraw.rounded_rectangle([286, 332, 440, 436], radius=10, fill=(56, 189, 248, 220))
    # Measurement tick lines
    for tx in range(320, 520, 40):
        idraw.line([tx, 332, tx, 362], fill=(239, 68, 68, 255), width=6)
    # Plunger stem
    idraw.line([440, 384, 630, 384], fill=(203, 213, 225, 255), width=18)
    # Plunger thumb flange
    idraw.rounded_rectangle([620, 344, 646, 424], radius=8, fill=(148, 163, 184, 255))
    # Barrel finger flanges
    idraw.rounded_rectangle([534, 304, 554, 464], radius=8, fill=(148, 163, 184, 255))
    
    # Rotate 45 degrees
    rotated = inj_canvas.rotate(45, resample=Image.Resampling.BICUBIC)
    im.alpha_composite(rotated)
    return im

def draw_drops():
    im = create_base()
    draw = ImageDraw.Draw(im)
    # Cyan Teal badge
    add_container(draw, (8, 145, 178, 255), (14, 116, 144, 255), (103, 232, 249, 220))
    
    # Large water drop
    # Top tip (384, 170), bottom rounded curve
    cx, cy = 384, 420
    r = 160
    draw.ellipse([cx - r, cy - r + 30, cx + r, cy + r + 30], fill=(255, 255, 255, 255), outline=(224, 242, 254, 255), width=8)
    # Triangle top
    draw.polygon([(384, 160), (cx - r + 24, cy + 40), (cx + r - 24, cy + 40)], fill=(255, 255, 255, 255))
    
    # Inner cyan gradient drop
    draw.ellipse([cx - r + 24, cy - r + 54, cx + r - 24, cy + r + 6], fill=(6, 182, 212, 255))
    draw.polygon([(384, 190), (cx - r + 40, cy + 36), (cx + r - 40, cy + 36)], fill=(6, 182, 212, 255))
    
    # Sheen highlight
    draw.arc([cx - r + 44, cy - r + 64, cx + r - 44, cy + r - 6], start=180, end=270, fill=(255, 255, 255, 220), width=16)
    return im

def draw_inhaler():
    im = create_base()
    draw = ImageDraw.Draw(im)
    # Sky Blue badge
    add_container(draw, (2, 132, 199, 255), (3, 105, 161, 255), (125, 211, 252, 220))
    
    # Metal canister on top
    draw.rounded_rectangle([324, 150, 444, 270], radius=16, fill=(203, 213, 225, 255), outline=(255, 255, 255, 255), width=8)
    # Inhaler L-body
    draw.rounded_rectangle([304, 240, 464, 520], radius=32, fill=(241, 245, 249, 255), outline=(255, 255, 255, 255), width=10)
    # Mouthpiece extending to the left
    draw.rounded_rectangle([190, 420, 360, 520], radius=24, fill=(226, 232, 240, 255), outline=(255, 255, 255, 255), width=8)
    # Mist puff circles
    draw.ellipse([120, 430, 160, 470], fill=(255, 255, 255, 200))
    draw.ellipse([80, 400, 130, 450], fill=(255, 255, 255, 160))
    draw.ellipse([80, 460, 130, 510], fill=(255, 255, 255, 160))
    return im

def draw_ointment():
    im = create_base()
    draw = ImageDraw.Draw(im)
    # Violet / Purple dermatological badge
    add_container(draw, (124, 58, 237, 255), (109, 40, 217, 255), (196, 181, 253, 220))
    
    # Tube body angled
    tube_c = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    tdraw = ImageDraw.Draw(tube_c)
    
    # Draw horizontal tube
    # Crimp end
    tdraw.line([160, 340, 160, 428], fill=(148, 163, 184, 255), width=16)
    # Main tube
    tdraw.polygon([(160, 348), (480, 334), (480, 434), (160, 420)], fill=(248, 250, 252, 255), outline=(255, 255, 255, 255))
    # Stripe on tube
    tdraw.polygon([(260, 344), (340, 340), (340, 428), (260, 424)], fill=(167, 139, 250, 255))
    # Nozzle & cap
    tdraw.rectangle([480, 360, 520, 408], fill=(203, 213, 225, 255))
    tdraw.rounded_rectangle([520, 344, 570, 424], radius=8, fill=(109, 40, 217, 255), outline=(255, 255, 255, 255), width=6)
    
    # Cream dollop
    tdraw.ellipse([570, 370, 610, 400], fill=(255, 255, 255, 240))
    
    rot = tube_c.rotate(-30, resample=Image.Resampling.BICUBIC)
    im.alpha_composite(rot)
    return im

def draw_supplement():
    im = create_base()
    draw = ImageDraw.Draw(im)
    # Emerald Nature badge
    add_container(draw, (16, 185, 129, 255), (5, 150, 105, 255), (110, 231, 183, 220))
    
    # Leaf shape 1
    # Stem from (384, 560) to (384, 220)
    draw.line([384, 560, 384, 220], fill=(255, 255, 255, 255), width=12)
    # Big leaf left
    draw.chord([210, 220, 430, 480], start=100, end=270, fill=(209, 250, 229, 255), outline=(255, 255, 255, 255), width=8)
    # Big leaf right
    draw.chord([338, 200, 558, 460], start=270, end=80, fill=(240, 253, 244, 255), outline=(255, 255, 255, 255), width=8)
    # Veins
    draw.line([384, 380, 310, 330], fill=(5, 150, 105, 255), width=8)
    draw.line([384, 320, 450, 270], fill=(5, 150, 105, 255), width=8)
    return im

def main():
    out_dir = r"android/app/src/main/res/drawable"
    os.makedirs(out_dir, exist_ok=True)
    
    generators = {
        "ic_med_tablet.png": draw_tablet,
        "ic_med_capsule.png": draw_capsule,
        "ic_med_syrup.png": draw_syrup,
        "ic_med_injection.png": draw_injection,
        "ic_med_drops.png": draw_drops,
        "ic_med_inhaler.png": draw_inhaler,
        "ic_med_ointment.png": draw_ointment,
        "ic_med_supplement.png": draw_supplement,
        "ic_med_other.png": draw_capsule,
    }
    
    for filename, gen_fn in generators.items():
        high_res = gen_fn()
        # Downscale with Lanczos for crystal-clear antialiasing
        final_img = high_res.resize((FINAL_SIZE, FINAL_SIZE), Image.Resampling.LANCZOS)
        out_path = os.path.join(out_dir, filename)
        final_img.save(out_path, format="PNG")
        print(f"Generated: {out_path} ({FINAL_SIZE}x{FINAL_SIZE})")

if __name__ == "__main__":
    main()
