# This app is a raft. — 이 앱도 뗏목이다.
#
# 탑의 그림을 화면에 들여온다. 그림 파일은 손으로 그린 것이고, 여기서는
# 그것을 그대로 심기만 한다 — 좌표도 곡선도 이 쪽에서 만들지 않는다.
#
# 파일로 불러오지 않고 심는 까닭: 장면은 잠깐이고, 그때 가서 그림을
# 부르면 탑이 한 박자 늦게 선다. 색은 그림에 없다(CSS 가 준다) — 주사 탑의
# 붉은빛도 :root 의 세 값에서 온다.
module PagodaHelper
  ART = Rails.root.join("app/assets/images/pagoda_cinnabar.svg")

  # 화면에 심을 때는 이름공간(xmlns)을 뗀다. HTML 안의 SVG 에는 필요 없고,
  # 남겨 두면 화면이 바깥 주소를 품은 것처럼 보인다(제6조 검사).
  # 파일 자체는 그대로 두어 혼자서도 열리는 그림으로 남긴다.
  def pagoda_art
    @pagoda_art ||= ART.read.sub(/ xmlns="[^"]*"/, "").gsub(/<!--.*?-->\s*/m, "").html_safe
  end
end
