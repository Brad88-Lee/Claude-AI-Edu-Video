"""
測試場景：三個獨立場景，合計約 55 秒。
S1：中文標題 + 公式推導（驗證 MathTex / LaTeX / dvisvgm / CJK Text）
S2：靜態圖 + 以 xelatex + ctex 排版的中文 Tex（驗證 CJK 進 LaTeX 的路徑）
S3：座標軸與曲線（Axes 數字標籤會走 LaTeX）
每個場景獨立算繪，失敗時不會互相影響。
"""
import os

from manim import *

CJK_FONT = "Noto Sans CJK TC"
HERE = os.path.dirname(os.path.abspath(__file__))
ASSET = os.path.join(HERE, "assets", "test_image.png")


class S1_Formula(Scene):
    def construct(self):
        title = Text("二次方程式公式推導", font=CJK_FONT, font_size=44).to_edge(UP)
        self.play(Write(title), run_time=1.5)

        steps = [
            MathTex(r"ax^2 + bx + c = 0"),
            MathTex(r"x^2 + \frac{b}{a}x = -\frac{c}{a}"),
            MathTex(r"\left(x + \frac{b}{2a}\right)^2 = \frac{b^2 - 4ac}{4a^2}"),
            MathTex(r"x = \frac{-b \pm \sqrt{b^2 - 4ac}}{2a}"),
        ]
        captions = [
            "從一般式出發",
            "兩邊同除以 a 並移項",
            "配方：兩邊加上 (b/2a) 的平方",
            "開根號並整理，得到公式解",
        ]

        prev_eq, prev_cap = None, None
        for eq, cap in zip(steps, captions):
            eq.scale(1.2)
            cap_m = Text(cap, font=CJK_FONT, font_size=30).to_edge(DOWN)
            if prev_eq is None:
                self.play(Write(eq), FadeIn(cap_m), run_time=2)
            else:
                self.play(
                    ReplacementTransform(prev_eq, eq),
                    ReplacementTransform(prev_cap, cap_m),
                    run_time=2,
                )
            self.wait(3)
            prev_eq, prev_cap = eq, cap_m

        box = SurroundingRectangle(prev_eq, color=YELLOW)
        self.play(Create(box), run_time=1)
        self.wait(3)
        self.play(FadeOut(*self.mobjects), run_time=1)


class S2_ImageAndCJKTex(Scene):
    def construct(self):
        tpl = TexTemplate(tex_compiler="xelatex", output_format=".xdv")
        tpl.add_to_preamble(r"\usepackage[UTF8,fontset=none]{ctex}")
        tpl.add_to_preamble(r"\setCJKmainfont{Noto Sans CJK TC}")

        img = ImageMobject(ASSET).scale_to_fit_height(4).to_edge(LEFT, buff=0.8)
        head = Text("複利：時間的力量", font=CJK_FONT, font_size=42).to_edge(UP)
        t1 = Tex(r"本金 $P$、年利率 $r$、期數 $n$", tex_template=tpl, font_size=38)
        f1 = MathTex(r"A = P(1+r)^n", font_size=60)
        group = VGroup(t1, f1).arrange(DOWN, buff=0.6).to_edge(RIGHT, buff=0.8)

        self.play(Write(head), FadeIn(img), run_time=2)
        self.play(Write(t1), run_time=2)
        self.play(Write(f1), run_time=2)
        self.wait(2)

        f2 = MathTex(r"A = Pe^{rt}", font_size=60).move_to(f1)
        self.play(Indicate(f1), run_time=1.5)
        self.play(ReplacementTransform(f1, f2), img.animate.scale(1.15), run_time=2)
        self.wait(2)
        self.play(FadeOut(*self.mobjects), run_time=1)


class S3_Graph(Scene):
    def construct(self):
        title = Text("複利成長曲線", font=CJK_FONT, font_size=40).to_edge(UP)
        axes = Axes(
            x_range=[0, 10, 1],
            y_range=[0, 80, 20],
            x_length=9,
            y_length=4.5,
            axis_config={"include_numbers": True},
        ).shift(DOWN * 0.5)
        curve = axes.plot(lambda n: 10 * 1.2 ** n, x_range=[0, 10], color=YELLOW)
        label = MathTex(r"A = 10(1.2)^n", font_size=40).to_corner(UR).shift(DOWN * 1.2)

        n = ValueTracker(0)
        dot = always_redraw(
            lambda: Dot(
                axes.c2p(n.get_value(), 10 * 1.2 ** n.get_value()), color=RED
            )
        )

        self.play(Write(title), Create(axes), run_time=2.5)
        self.play(Create(curve), Write(label), run_time=3)
        self.add(dot)
        self.play(n.animate.set_value(10), run_time=6, rate_func=linear)
        self.wait(4)
        self.play(FadeOut(*self.mobjects), run_time=1)
