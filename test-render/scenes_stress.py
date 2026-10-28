"""
壓力測試場景：
ST1_Images12：12 張大圖（含透明背景），每張淡入、緩慢推近、淡出，共約 60 秒
ST3_Long10min：30 段公式推導，每段約 20 秒，共約 600 秒（10 分鐘），用來測長時間算繪
（ST2 保留給「4K 版 S1/S2/S3」，直接使用 scenes.py，不另外寫）
"""
import glob
import os

from manim import *

CJK_FONT = "Noto Sans CJK TC"
HERE = os.path.dirname(os.path.abspath(__file__))
STRESS_DIR = os.path.join(HERE, "assets", "stress")


class ST1_Images12(Scene):
    def construct(self):
        title = Text("圖片素材壓力測試", font=CJK_FONT, font_size=40).to_edge(UP)
        self.add(title)
        paths = sorted(glob.glob(os.path.join(STRESS_DIR, "img_*.png")))
        if not paths:
            raise RuntimeError("no stress images found, run make_stress_assets.py first")
        for p in paths:
            img = ImageMobject(p).scale_to_fit_height(5.2).shift(DOWN * 0.4)
            cap = Text(os.path.basename(p), font_size=26).to_edge(DOWN)
            self.play(FadeIn(img), FadeIn(cap), run_time=1)
            self.play(img.animate.scale(1.12).shift(LEFT * 0.5), run_time=3, rate_func=linear)
            self.play(FadeOut(img), FadeOut(cap), run_time=1)


class ST3_Long10min(Scene):
    def construct(self):
        for i in range(30):
            a, b, c = i + 1, 2 * i + 3, i + 5
            disc = b * b - 4 * a * c
            title = Text("第 " + str(i + 1) + " 段推導", font=CJK_FONT, font_size=40).to_edge(UP)
            eqs = [
                MathTex(str(a) + "x^2 + " + str(b) + "x + " + str(c) + " = 0"),
                MathTex(r"x^2 + \frac{" + str(b) + "}{" + str(a) + r"}x = -\frac{" + str(c) + "}{" + str(a) + "}"),
                MathTex(r"x = \frac{-" + str(b) + r" \pm \sqrt{" + str(disc) + "}}{" + str(2 * a) + "}"),
            ]
            self.play(Write(title), run_time=1)
            prev = None
            for eq in eqs:
                eq.scale(1.2)
                if prev is None:
                    self.play(Write(eq), run_time=2)
                else:
                    self.play(ReplacementTransform(prev, eq), run_time=2)
                self.wait(4)
                prev = eq
            self.play(FadeOut(title), FadeOut(prev), run_time=1)


class ST4_Long33min(Scene):
    """100 段公式推導，每段約 20 秒，共約 2000 秒（約 33 分鐘），用於測 4K 長時間算繪與單次背景指令上限。"""

    def construct(self):
        for i in range(100):
            a, b, c = i % 9 + 1, 2 * (i % 7) + 3, i % 5 + 5
            disc = b * b - 4 * a * c
            title = Text("第 " + str(i + 1) + " 段推導", font=CJK_FONT, font_size=40).to_edge(UP)
            eqs = [
                MathTex(str(a) + "x^2 + " + str(b) + "x + " + str(c) + " = 0"),
                MathTex(r"x^2 + \frac{" + str(b) + "}{" + str(a) + r"}x = -\frac{" + str(c) + "}{" + str(a) + "}"),
                MathTex(r"x = \frac{-" + str(b) + r" \pm \sqrt{" + str(disc) + "}}{" + str(2 * a) + "}"),
            ]
            self.play(Write(title), run_time=1)
            prev = None
            for eq in eqs:
                eq.scale(1.2)
                if prev is None:
                    self.play(Write(eq), run_time=2)
                else:
                    self.play(ReplacementTransform(prev, eq), run_time=2)
                self.wait(4)
                prev = eq
            self.play(FadeOut(title), FadeOut(prev), run_time=1)


class ST5_ImagesStatic(Scene):
    """12 張圖，只淡入、靜止 3 秒、淡出（無逐格位移縮放），共約 60 秒。與 ST1 比較動態對耗時的影響。"""

    def construct(self):
        paths = sorted(glob.glob(os.path.join(STRESS_DIR, "img_*.png")))
        if not paths:
            raise RuntimeError("no stress images found")
        for p in paths:
            img = ImageMobject(p).scale_to_fit_height(5.2)
            self.play(FadeIn(img), run_time=1)
            self.wait(3)
            self.play(FadeOut(img), run_time=1)


class ST6_ImagesStaticJpg(Scene):
    """同 ST5，但使用事先縮到 1920 寬的 JPEG（img_*.jpg），比較素材格式與尺寸的影響。"""

    def construct(self):
        paths = sorted(glob.glob(os.path.join(STRESS_DIR, "jpg", "img_*.jpg")))
        if not paths:
            raise RuntimeError("no jpg images found")
        for p in paths:
            img = ImageMobject(p).scale_to_fit_height(5.2)
            self.play(FadeIn(img), run_time=1)
            self.wait(3)
            self.play(FadeOut(img), run_time=1)


class ST7_Chunk(Scene):
    """ST4 的分段版：由環境變數 SEG_START、SEG_COUNT 指定從第幾段（0 起算）開始、共幾段。內容與 ST4 對應的段完全相同。"""

    def construct(self):
        start = int(os.environ.get("SEG_START", "0"))
        count = int(os.environ.get("SEG_COUNT", "20"))
        for i in range(start, start + count):
            a, b, c = i % 9 + 1, 2 * (i % 7) + 3, i % 5 + 5
            disc = b * b - 4 * a * c
            title = Text("第 " + str(i + 1) + " 段推導", font=CJK_FONT, font_size=40).to_edge(UP)
            eqs = [
                MathTex(str(a) + "x^2 + " + str(b) + "x + " + str(c) + " = 0"),
                MathTex(r"x^2 + \frac{" + str(b) + "}{" + str(a) + r"}x = -\frac{" + str(c) + "}{" + str(a) + "}"),
                MathTex(r"x = \frac{-" + str(b) + r" \pm \sqrt{" + str(disc) + "}}{" + str(2 * a) + "}"),
            ]
            self.play(Write(title), run_time=1)
            prev = None
            for eq in eqs:
                eq.scale(1.2)
                if prev is None:
                    self.play(Write(eq), run_time=2)
                else:
                    self.play(ReplacementTransform(prev, eq), run_time=2)
                self.wait(4)
                prev = eq
            self.play(FadeOut(title), FadeOut(prev), run_time=1)
