# This app is a raft. — 이 앱도 뗏목이다.
#
# 현판 시안(2026-11-06, docs/M-landing-design.md 11절) — 크레딧 0. 그림 연장(MonoRouter)을 부르지 않는다. Pillow 로만.
# 현판은 그림에서 비워 두고 앱이 글자를 얹는다(AI 가 글자를 그리지 않는다). 여기서는 그 얹음을 미리 본다.
#   python3 script/art/hyeonpan.py
# 글꼴 원본은 tmp/fonts/ 에만 받는다(저장소 밖): 마루부리 — 네이버 한글한글 아름답게(maruburi.zip),
# 본명조(Noto Serif KR) · 동해독도 — google/fonts 저장소의 ofl/ 폴더.
import os
from PIL import Image, ImageDraw, ImageFont, ImageStat

R = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..')) + '/'
ART = R + 'tmp/art/'
FONTS = R + 'tmp/fonts/'
GATE = ART + 'gate-d3c-fixed-1.jpeg'
B = ART + 'gate-b-1.jpeg'

# 현판 자리(896×1200 의 화소) — 안쪽 판. 바깥 테는 370–534 × 657–700.
BOARD = (376, 661, 526, 692)
PAPER, INK = (0xf5, 0xef, 0xe2), (0x1c, 0x1a, 0x17)   # :root 의 --paper · --ink. 금빛은 없다(§2)
NOTO = FONTS + 'notoserifkr/NotoSerifKR.ttf'
FACES = {
  '마루부리 Bold': (FONTS + 'maruburi/TTF/MaruBuri-Bold.ttf', None),
  '본명조 Bold(Noto Serif KR)': (NOTO, 700),
  '동해독도(붓)': (FONTS + 'eastseadokdo/EastSeaDokdo-Regular.ttf', None),
}
TEXTS = {'(가)': 'fulltimezero', '(나)': '풀타임제로', '(다)': '零山 休門'}
RTL = '門休 山零'   # (다)를 오른쪽에서 왼쪽으로 읽게 놓은 것 — 零山休門 을 거꾸로 적는다
LABEL = ImageFont.truetype('/System/Library/Fonts/AppleSDGothicNeo.ttc', 26)


def luminance(rgb):
  def ch(c):
    c /= 255
    return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4
  r, g, b = (ch(c) for c in rgb)
  return 0.2126 * r + 0.7152 * g + 0.0722 * b


def contrast(a, b):
  la, lb = sorted((luminance(a), luminance(b)), reverse=True)
  return (la + 0.05) / (lb + 0.05)


def face(path, weight, size):
  font = ImageFont.truetype(path, size)
  if weight:
    font.set_variation_by_axes([weight])
  return font


def has_all(path, text):
  from fontTools.ttLib import TTFont
  cmap = TTFont(path, fontNumber=0).getBestCmap()
  return all(ord(c) in cmap for c in text if not c.isspace())


def letter(img, scale, text, path, weight, color):
  """판 안에 글자를 얹는다 — 좌우 여백 10%, 높이는 판의 62% 까지."""
  x0, y0, x1, y1 = (v * scale for v in BOARD)
  bw, bh = x1 - x0, y1 - y0
  size = int(bh * 0.62)
  while True:
    f = face(path, weight, size)
    l, t, r, b = f.getbbox(text)
    if (r - l) <= bw * 0.8 and (b - t) <= bh * 0.62 or size < 6:
      break
    size -= 1
  d = ImageDraw.Draw(img)
  cx, cy = (x0 + x1) / 2, (y0 + y1) / 2
  d.text((cx - (l + r) / 2, cy - (t + b) / 2), text, font=f, fill=color)


def plaque_panel(text, path, weight, scale=6, around=(330, 630, 572, 724)):
  """현판 둘레를 키운 한 칸. 그림을 키운 뒤 글자를 그 크기에서 얹는다(앱이 벡터 글자를 얹는 것과 같다)."""
  base = Image.open(GATE).convert('RGB')
  big = base.resize((base.width * scale, base.height * scale), Image.LANCZOS)
  letter(big, scale, text, path, weight, PAPER)
  return big.crop(tuple(v * scale for v in around))


# 1) 아홉 장 + 오른쪽에서 왼쪽 한 장
board_rgb = tuple(round(v) for v in ImageStat.Stat(Image.open(GATE).convert('RGB').crop((380, 664, 522, 689))).mean)
print('현판 바탕 평균', board_rgb, '· 한지빛 글씨 대비 %.1f : 1 · 먹빛 글씨 대비 %.1f : 1' % (contrast(PAPER, board_rgb), contrast(INK, board_rgb)))
cells = []
for tk, text in TEXTS.items():
  for fk, (path, weight) in FACES.items():
    note = ''
    use, w = path, weight
    if not has_all(path, text):
      use, w, note = NOTO, 700, ' — 이 글꼴에 한자가 없다, 본명조로 메움'
    cells.append((f'{tk} {text} · {fk}{note}', plaque_panel(text, use, w)))
cells.append((f'(다) 오른쪽에서 왼쪽으로 · 본명조 Bold — 「{RTL}」', plaque_panel(RTL, NOTO, 700)))
pw, ph = cells[0][1].size
cols, gap, top = 3, 16, 44
rows = (len(cells) + cols - 1) // cols
sheet = Image.new('RGB', (cols * pw + (cols + 1) * gap, rows * (ph + top + gap) + gap), (242, 238, 228))
d = ImageDraw.Draw(sheet)
for i, (label, im) in enumerate(cells):
  x, y = gap + (i % cols) * (pw + gap), gap + (i // cols) * (ph + top + gap)
  d.text((x, y + 6), label, fill=(40, 40, 40), font=LABEL)
  sheet.paste(im, (x, y + top))
sheet.save(ART + 'hyeonpan.jpg', quality=88)
print('hyeonpan.jpg', sheet.size)

# 2) B → D3c 겹침에 현판 글자를 얹은 판 — 글자는 제자리에 그대로 있다
b = Image.open(B).convert('RGB')
g = Image.open(GATE).convert('RGB')
frames = []
for t in (0, 0.4, 0.8, 1.2, 1.6):
  a = t / 1.6
  f = Image.blend(b, g, a)
  scale = 2
  f = f.resize((f.width * scale, f.height * scale), Image.LANCZOS)
  letter(f, scale, '零山 休門', NOTO, 700, PAPER)
  full = f.resize((300, 402), Image.LANCZOS)
  near = f.crop((330 * scale, 600 * scale, 572 * scale, 740 * scale)).resize((300, 174), Image.LANCZOS)
  frames.append((t, a, full, near))
W = 5 * 300 + 6 * 10
fade = Image.new('RGB', (W, 402 + 174 + 70), (242, 238, 228))
d = ImageDraw.Draw(fade)
small = ImageFont.truetype('/System/Library/Fonts/AppleSDGothicNeo.ttc', 16)
for i, (t, a, full, near) in enumerate(frames):
  x = 10 + i * 310
  fade.paste(full, (x, 10))
  fade.paste(near, (x, 422))
  d.text((x, 606), f'{t:.1f}s B {1 - a:.2f} / D3c {a:.2f}', fill=(60, 60, 60), font=small)
fade.save(ART + 'gate-hyeonpan-fade.jpg', quality=88)
print('gate-hyeonpan-fade.jpg', fade.size)
