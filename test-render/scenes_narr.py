"""旁白驅動測試用的公式段：由環境變數 SEG_IDX、SEG_DUR 指定第幾段與總長（秒，需 >= 4）。
動畫共 3 秒（標題、方程式、轉換），其餘時間靜止（模擬旁白講解中畫面停留）。"""
import os
from manim import *

CJK_FONT = "Noto Sans CJK TC"


class ST9_NarrFormula(Scene):
    def construct(self):
        i = int(os.environ["SEG_IDX"])
        T = float(os.environ["SEG_DUR"])
        a, b, c = i % 9 + 1, 2 * (i % 7) + 3, i % 5 + 5
        title = Text("第 " + str(i + 1) + " 段推導", font=CJK_FONT, font_size=40).to_edge(UP)
        e1 = MathTex(str(a) + "x^2 + " + str(b) + "x + " + str(c) + " = 0").scale(1.2)
        e2 = MathTex(r"x = \frac{-" + str(b) + r" \pm \sqrt{" + str(b * b - 4 * a * c) + "}}{" + str(2 * a) + "}").scale(1.2)
        self.play(Write(title), run_time=1.0)
        self.play(Write(e1), run_time=1.0)
        self.play(ReplacementTransform(e1, e2), run_time=1.0)
        self.wait(T - 3.0)
