"""
產生 12 張接近 ChatGPT 圖像尺寸（1536x1024）的測試 PNG，放在 assets/stress/。
奇數編號的圖帶透明背景（RGBA，模擬去背的人物／金錢素材），偶數編號為不透明 RGB。
內容是模糊的隨機雜訊，檔案大小接近真實生成圖，不含任何文字。
"""
import os

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

HERE = os.path.dirname(os.path.abspath(__file__))
OUT_DIR = os.path.join(HERE, "assets", "stress")
os.makedirs(OUT_DIR, exist_ok=True)

W, H = 1536, 1024
rng = np.random.default_rng(42)

for i in range(12):
    noise = rng.integers(0, 256, (H, W, 3), dtype=np.uint8)
    img = Image.fromarray(noise).filter(ImageFilter.GaussianBlur(2))
    d = ImageDraw.Draw(img)
    d.ellipse((300, 150, 1236, 874), outline=(255, 255, 255), width=10)
    if i % 2 == 1:
        img = img.convert("RGBA")
        mask = Image.new("L", (W, H), 0)
        ImageDraw.Draw(mask).ellipse((300, 150, 1236, 874), fill=255)
        img.putalpha(mask)
    path = os.path.join(OUT_DIR, f"img_{i:02d}.png")
    img.save(path)

total = sum(os.path.getsize(os.path.join(OUT_DIR, f)) for f in os.listdir(OUT_DIR))
print(f"saved 12 images to {OUT_DIR}, total {total/1e6:.1f} MB")
