"""產生一張占位用的測試圖片（取代 ChatGPT 生成的素材），只用 Pillow，圖上只有英文與圖形。"""
import os

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
OUT_DIR = os.path.join(HERE, "assets")
os.makedirs(OUT_DIR, exist_ok=True)

W, H = 1280, 720
img = Image.new("RGB", (W, H))
px = img.load()
for y in range(H):
    for x in range(W):
        px[x, y] = (int(40 + 80 * x / W), int(60 + 100 * y / H), 160)

d = ImageDraw.Draw(img)
d.ellipse((140, 140, 520, 520), fill=(255, 205, 60), outline=(255, 255, 255), width=8)
d.rectangle((640, 220, 1140, 600), fill=(235, 235, 245), outline=(255, 255, 255), width=6)
for i in range(4):
    x0 = 680 + i * 115
    d.rectangle((x0, 280, x0 + 60, 540), fill=(120, 120, 170))
d.text((60, 40), "TEST IMAGE PLACEHOLDER", fill=(255, 255, 255))

out = os.path.join(OUT_DIR, "test_image.png")
img.save(out)
print("saved", out)
