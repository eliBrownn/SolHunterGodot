"""Render the Godot world-plan proof. Pillow is used only for atlas presentation."""
import argparse
from collections import Counter
import json
import math
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont

PAPER = "#f2efe5"
INK = "#20393e"
MUTED = "#53696a"
PALETTE = [
    ("Meadow", "#c3c786", (195, 199, 134)),
    ("Woodland", "#527c5e", (82, 124, 94)),
    ("Heath", "#c7aa81", (199, 170, 129)),
    ("Marsh", "#79ac9d", (121, 172, 157)),
    ("Ocean", "#395f77", (57, 95, 119)),
    ("Coast", "#dfc894", (223, 200, 148)),
    ("Desert", "#d6a15e", (214, 161, 94)),
    ("Jungle", "#286b49", (40, 107, 73)),
    ("Savanna", "#b2a35a", (178, 163, 90)),
    ("Alpine", "#b8b2a9", (184, 178, 169)),
    ("Tundra", "#b9bfc3", (185, 191, 195)),
    ("Taiga", "#537d78", (83, 125, 120)),
    ("Lake", "#4998b6", (73, 152, 182)),
]
OCEAN = 4
LAKE = 12
RIVER = (75, 154, 187)
IRRIGATED = (157, 229, 129)
INTAKE = (255, 238, 160)


def fonts():
    for directory in (Path("C:/Windows/Fonts"), Path("/usr/share/fonts/truetype/dejavu")):
        if (directory / "georgia.ttf").exists():
            return (
                ImageFont.truetype(str(directory / "georgia.ttf"), 43),
                ImageFont.truetype(str(directory / "segoeui.ttf"), 17),
                ImageFont.truetype(str(directory / "segoeuib.ttf"), 17),
                ImageFont.truetype(str(directory / "segoeui.ttf"), 14),
            )
        if (directory / "DejaVuSerif.ttf").exists():
            return (
                ImageFont.truetype(str(directory / "DejaVuSerif.ttf"), 43),
                ImageFont.truetype(str(directory / "DejaVuSans.ttf"), 17),
                ImageFont.truetype(str(directory / "DejaVuSans-Bold.ttf"), 17),
                ImageFont.truetype(str(directory / "DejaVuSans.ttf"), 14),
            )
    return tuple(ImageFont.load_default(size=size) for size in (43, 17, 17, 14))


def blend(first, second, weight):
    return tuple(round(a + (b - a) * weight) for a, b in zip(first, second))


def atlas_layers(plan):
    w, h = plan["width"], plan["height"]
    heights, biomes = plan["elevation"], plan["biome"]
    mask = Image.new("L", (w, h))
    mask.putdata([0 if biome == OCEAN else 255 for biome in biomes])
    shelf = mask.filter(ImageFilter.GaussianBlur(6)).tobytes()
    edge = mask.filter(ImageFilter.MinFilter(3)).tobytes()
    colors, relief = [], []
    for z in range(h):
        for x in range(w):
            i = z * w + x
            biome = biomes[i]
            if biome == OCEAN:
                sea = blend((47, 83, 108), (115, 163, 167), min(1, shelf[i] / 104))
                colors.append(sea)
                relief.append(blend((61, 96, 108), (110, 150, 148), min(1, shelf[i] / 100)))
                continue
            if biome == LAKE:
                colors.append(PALETTE[LAKE][2])
                relief.append(PALETTE[LAKE][2])
                continue
            y = heights[i]
            dx = heights[z * w + min(w - 1, x + 1)] - heights[z * w + max(0, x - 1)]
            dz = heights[min(h - 1, z + 1) * w + x] - heights[max(0, z - 1) * w + x]
            light = max(0.60, min(1.24, 1.0 + (dx + dz * 0.85) * 9.0))
            rock = max(0, min(1, (y - 0.42) / 0.47))
            tint = blend(PALETTE[biome][2], (224, 216, 198), rock * 0.48)
            if edge[i] == 0:
                light *= 0.76
            colors.append(tuple(min(255, round(value * light)) for value in tint))
            topo = blend((196, 195, 164), (100, 81, 69), y)
            contour = 0.9 if int(y * 14) != int(heights[min(h - 1, z + 1) * w + x] * 14) else 1.0
            relief.append(tuple(min(255, round(value * light * contour)) for value in topo))
    layers = []
    for pixels in (colors, relief):
        image = Image.new("RGB", (w, h))
        image.putdata(pixels)
        layers.append(image)
    return layers


def overlay_water(image, plan, show_fields=True, crop=None):
    width = plan["width"]
    left, top, right, bottom = crop or (0, 0, width, plan["height"])
    scale = image.width / (right - left)
    draw = ImageDraw.Draw(image, "RGBA")
    intakes = Counter(index - 1 for index in plan.get("irrigation", ()) if index)

    def point(index):
        return ((index % width - left + 0.5) * scale, (index // width - top + 0.5) * scale)

    def visible(index):
        return left <= index % width < right and top <= index // width < bottom

    if show_fields:
        for index, intake in enumerate(plan.get("irrigation", ())):
            if intake and visible(index):
                x, y = point(index)
                half = scale * 0.46
                bounds = (x - half, y - half, x + half, y + half)
                if scale >= 4:
                    draw.rectangle(bounds, outline=(*IRRIGATED, 200))
                else:
                    draw.rectangle(bounds, fill=(*IRRIGATED, 68))
    for index, flow in enumerate(plan.get("river_flow", ())):
        if not flow or plan["biome"][index] == LAKE:
            continue
        outlet = plan["downstream"][index]
        if not visible(index) and not visible(outlet):
            continue
        thickness = max(1, round(scale * (0.36 + 0.21 * math.log(flow / 125.0))))
        draw.line((point(index), point(outlet)), fill=(*RIVER, 235), width=thickness)
    if show_fields:
        radius = max(2, round(scale * 0.6))
        for intake in intakes:
            if visible(intake):
                x, y = point(intake)
                draw.ellipse((x - radius, y - radius, x + radius, y + radius), fill=INTAKE)
    return intakes


def render(plan, number, target):
    title, body, bold, small = fonts()
    atlas, relief = atlas_layers(plan)
    page = Image.new("RGB", (1730, 1116), PAPER)
    draw = ImageDraw.Draw(page)
    draw.text((40, 23), "SOLHUNTER  /  WORLD GENERATION STUDY", font=bold, fill=MUTED)
    draw.text((38, 47), "Continents, climates & waterways", font=title, fill=INK)
    draw.text((42, 102), f"PROOF {number:02d}     /     SEED {plan['seed']}     /     PLAN v{plan['version']}", font=small, fill=MUTED)
    draw.line((40, 129, 1690, 129), fill="#a0aaa1")
    overview = atlas.resize((1200, 900), Image.Resampling.BICUBIC)
    intakes = overlay_water(overview, plan)
    page.paste(overview, (40, 146))
    draw.rectangle((39, 145, 1240, 1046), outline="#253e45", width=2)
    # Compass is editorial framing. The geometry and biome colors come from the export.
    draw.ellipse((57, 163, 112, 218), fill="#21434d", outline="#88a7a7")
    draw.text((79, 168), "N", font=small, fill=PAPER)
    draw.polygon([(84, 188), (77, 204), (84, 200), (91, 204)], fill=PAPER)
    x, sidebar = 1270, 420
    draw.text((x, 147), "01  /  RELIEF & DRAINAGE", font=bold, fill=INK)
    relief = relief.resize((sidebar, 315), Image.Resampling.BICUBIC)
    overlay_water(relief, plan, show_fields=False)
    page.paste(relief, (x, 177))
    draw.rectangle((x - 1, 176, x + sidebar, 492), outline="#a0aaa1")
    draw.text((x, 505), "River networks descend through basins to the sea.", font=small, fill=MUTED)
    draw.text((x, 548), "02  /  BIOMES", font=bold, fill=INK)
    counts = Counter(plan["biome"])
    total = plan["width"] * plan["height"]
    land = total - counts[OCEAN] - counts[LAKE]
    for slot, index in enumerate((0, 1, 2, 3, 5, 6, 7, 8, 9, 10, 11, LAKE, OCEAN)):
        name, color, _ = PALETTE[index]
        col = x + slot // 7 * 220
        y = 580 + slot % 7 * 25
        draw.rounded_rectangle((col, y, col + 18, y + 15), radius=2, fill=color, outline="#64766c")
        draw.text((col + 27, y - 2), name, font=body, fill=INK)
        draw.text((col + 193, y), f"{counts[index] / total:.1%}", anchor="ra", font=small, fill=MUTED)
    draw.line((x, 759, x + sidebar, 759), fill="#a0aaa1")
    draw.text((x, 773), "03  /  IRRIGATION DETAIL", font=bold, fill=INK)
    if intakes:
        intake = max(intakes, key=intakes.get)
        center_x, center_y = intake % plan["width"], intake // plan["width"]
        left = max(0, min(atlas.width - 60, center_x - 30))
        top = max(0, min(atlas.height - 25, center_y - 12))
        box = (left, top, left + 60, top + 25)
        detail = atlas.crop(box).resize((sidebar, 175), Image.Resampling.BICUBIC)
        overlay_water(detail, plan, crop=box)
        page.paste(detail, (x, 804))
        draw.rectangle((x - 1, 803, x + sidebar, 979), outline="#a0aaa1")
        scale = overview.width / atlas.width
        draw.rectangle((40 + box[0] * scale, 146 + box[1] * scale,
                        40 + box[2] * scale, 146 + box[3] * scale), outline="#f8e8ad", width=2)
    for offset, (label, color) in enumerate((("River", RIVER), ("Irrigated land", IRRIGATED), ("Intake", INTAKE))):
        left = x + offset * 139
        draw.rectangle((left, 995, left + 15, 1008), fill=color, outline="#64766c")
        draw.text((left + 22, 991), label, font=small, fill=INK)
    draw.text((x, 1026), f"{len(intakes)} intakes  /  {sum(intakes.values()):,} irrigated map samples", font=small, fill=MUTED)
    draw.line((40, 1065, 1690, 1065), fill="#a0aaa1")
    width = plan["width"] * plan["cells_per_sample"]
    height = plan["height"] * plan["cells_per_sample"]
    draw.text((40, 1078), f"{width:,} × {height:,} world cells   •   {land / total:.1%} dry land   •   {plan['cells_per_sample']} world cells per map sample side", font=small, fill=MUTED)
    draw.text((1690, 1078), "PROCEDURAL PROPOSAL", anchor="ra", font=small, fill=MUTED)
    page.save(target)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("folder", type=Path)
    args = parser.parse_args()
    paths = sorted(args.folder.glob("seed-*.json"))
    if not paths:
        parser.error("The folder has no exported world plans.")
    for number, path in enumerate(paths, 1):
        plan = json.loads(path.read_text(encoding="utf-8"))
        render(plan, number, args.folder / f"world-map-{plan['seed']}.png")


if __name__ == "__main__":
    main()
