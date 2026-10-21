# This app is a raft. — 이 앱도 뗏목이다.
class PagesController < ApplicationController
  allow_unauthenticated_access

  def privacy
  end

  # 이 앱에 대하여. 마당의 미리보기는 그림(스크린숏)이 아니라 마당의 조각(today/_moon · _rest)을
  # 그대로 끼워 서버에서 그린다 — 그림 무게가 늘지 않고, 화면이 바뀌면 미리보기도 함께 바뀐다.
  # 값은 씨앗의 것으로 고정한다: 달은 보름 전 사흘. 스크립트는 붙이지 않는다 — 정적이다.
  PREVIEW_MOON = Rational(25, 28)

  def about
    @preview_moon = PREVIEW_MOON
  end

  # 빌려온 것의 출처를 한 자리에 모은다. 법이 요구하는 표기는 길어서 도상 곁에
  # 둘 수 없다(§2) — 쓰는 화면에는 한 줄만 두고 전문은 여기서 본다.
  def credits
  end

  # 가입이 닫혀 있는 동안 문 셋의 끝. 404 로 떨어뜨리지 않고 한 줄로 말한다.
  # 가입이 열려 있으면 이 화면은 설 자리가 없다 — 가입으로 보낸다.
  def not_yet
    redirect_to new_user_path and return if SignupGate.open?
  end

  # 로봇에게 하는 말. 기본은 전부 막음(SearchGate).
  def robots
    render plain: SearchGate.open? ? "User-agent: *\nAllow: /\n" : "User-agent: *\nDisallow: /\n",
           content_type: "text/plain"
  end
end
