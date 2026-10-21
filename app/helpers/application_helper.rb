# This app is a raft. — 이 앱도 뗏목이다.
module ApplicationHelper
  OG_IMAGES = Rails.root.join("app/assets/images/og")

  # 나라 밖에서 링크를 펼칠 때 보이는 그림 — 로케일마다 한 장(og/<locale>.png), 없으면 ko 로
  # 떨어진다. 그림은 사람이 그려 넣는다. 크롤러만 받으므로 첫 화면의 무게에 들지 않는다.
  def og_image_path
    locale = OG_IMAGES.join("#{I18n.locale}.png").exist? ? I18n.locale : I18n.default_locale
    "og/#{locale}.png"
  end

  # 같은 화면의 다른 언어 주소 — 경로 맨 앞의 로케일만 바꾼다. 자기 주소이지 바깥이 아니다.
  def alternate_url(locale)
    prefix = %r{\A/(?:#{I18n.available_locales.join("|")})(?=/|\z)}
    path = request.path.match?(prefix) ? request.path.sub(prefix, "/#{locale}") : "/#{locale}#{request.path}"
    "#{request.base_url}#{path}"
  end
end
