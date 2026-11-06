# This app is a raft. — 이 앱도 뗏목이다.
#
# 톤 시험(2026-11-06, docs/M-landing-design.md 10절) — 크레딧 0. 그림 연장(MonoRouter)을 부르지 않는다. Pillow 로만
# D 시안을 목표로 흰 끝 내림(흰 바탕 → 한지빛) · 감마 · 대비 · 채도를 맞춰 보고, 전 · 후 · D 를 tmp/art/tone-test.jpg 로 놓는다.
#   python3 script/art/tone_test.py
import itertools, os
from PIL import Image, ImageDraw, ImageFont, ImageStat, ImageEnhance, ImageChops
R=os.path.abspath(os.path.join(os.path.dirname(__file__),'..','..'))+'/'
D=R+'tmp/art/realism-d-ink-framed-1.jpeg'
SRC={'D3a':R+'docs/sources/art/gate-d3a.jpg','천왕문 left-b':R+'tmp/art/cheonwang-left-b-1.jpeg',
     '천왕문 right-b':R+'tmp/art/cheonwang-right-b-1.jpeg','선방 방 room3':R+'docs/sources/art/seonbang-room.jpg'}
HANJI=(244,238,226)   # 흰 바탕이 내려앉을 한지빛
def load(p,w):
    im=Image.open(p).convert('RGB'); return im.resize((w,round(im.height*w/im.width)),Image.LANCZOS)
def stats(im):
    L=im.convert('L'); st=ImageStat.Stat(L); r,g,b=im.split()
    C=ImageChops.subtract(ImageChops.lighter(ImageChops.lighter(r,g),b),ImageChops.darker(ImageChops.darker(r,g),b))
    h=L.histogram(); n=sum(h)
    mask=L.point(lambda v: 255 if v<178 else 0)
    return dict(밝기=st.mean[0]/255,채도=ImageStat.Stat(C,mask).mean[0]/255,대비=st.stddev[0]/255,흰바탕=sum(h[209:])/n)
def tone(im,c,s,g):
    im=ImageChops.multiply(im,Image.new('RGB',im.size,HANJI))        # 흰 끝 내림 — 흰 바탕을 한지빛으로
    lut=[round(255*(v/255)**g) for v in range(256)]; im=im.point(lut*3)  # 중간톤을 짙게
    im=ImageEnhance.Contrast(im).enhance(c)                           # 대비
    return ImageEnhance.Color(im).enhance(s)                          # 채도
t=stats(load(D,240)); rows=[]; outs={}
for k,p in SRC.items():
    small=load(p,240); before=stats(small)
    mix=0.6 if '선방' in k else 1.0          # 선방 방은 탱화가 주인공 — D 쪽으로 6할만
    goal={x:before[x]+(t[x]-before[x])*mix for x in t}
    best=None
    for c,s,g in itertools.product([1+i*0.1 for i in range(11)],[1.0+i*0.1 for i in range(11)],[1+i*0.1 for i in range(11)]):
        st=stats(tone(small,c,s,g))
        e=((st['밝기']-goal['밝기'])/0.05)**2+((st['채도']-goal['채도'])/0.03)**2+((st['대비']-goal['대비'])/0.03)**2+((st['흰바탕']-goal['흰바탕'])/0.05)**2
        if best is None or e<best[0]: best=(e,c,s,g,st)
    _,c,s,g,after=best; rows.append((k,before,after,goal,(c,s,g)))
    full=load(p,672); outs[k]=(full,tone(full,c,s,g))
print('D', {x:round(t[x],3) for x in t})
for k,b,a,goal,(c,s,g) in rows:
    print(k,'전',{x:round(b[x],3) for x in b},'후',{x:round(a[x],3) for x in a},'목표',{x:round(goal[x],3) for x in goal},'대비 %.1f 채도 %.1f 감마 %.1f'%(c,s,g))
dimg=load(D,672).resize((672,900)); H=900
font=ImageFont.truetype('/System/Library/Fonts/AppleSDGothicNeo.ttc',28)
sheet=Image.new('RGB',(672*3+40,(H+50)*len(outs)),(242,238,228)); dr=ImageDraw.Draw(sheet)
for i,(k,(b,a)) in enumerate(outs.items()):
    y=i*(H+50)
    for j,(im,lab) in enumerate([(b,'전'),(a,'후'),(dimg,'D 시안')]):
        sheet.paste(im.resize((672,H)),(j*(672+20),y+44)); dr.text((j*(672+20)+8,y+6),f'{k} — {lab}',fill=(40,40,40),font=font)
    a.save(R+'tmp/art/tone/'+k.split()[-1]+'-toned.jpg',quality=90)
sheet.save(R+'tmp/art/tone-test.jpg',quality=82); print(sheet.size)
