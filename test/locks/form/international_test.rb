# This app is a raft. — 이 앱도 뗏목이다.
#
# 나라 밖으로 펼칠 때 — 공개 화면마다 같은 화면의 다른 언어 주소(hreflang: ko · en · x-default)와
# 링크 그림(og:image)이 있다. 그림은 로케일마다 og/<locale>.png, 없으면 ko 로 떨어진다.
# 둘 다 자기 주소다. 「결」 쪽이다 — 언어가 늘거나 그림이 오면 바뀐다.
require "test_helper"

class InternationalTest < ActionDispatch::IntegrationTest
  include Screens

  test "공개 페이지마다 og:image 와 hreflang 이 있다" do
    I18n.available_locales.each do |locale|
      OPEN_PAGES.each do |page|
        get public_send(page, locale: locale)
        head = Nokogiri::HTML(response.body).at_css("head")

        image = head.at_css("meta[property='og:image']")
        assert image, "#{page}(#{locale}) 에 og:image 가 없다"
        assert_match %r{\Ahttps?://#{Regexp.escape(request.host)}(?::\d+)?/assets/og/(?:#{I18n.available_locales.join("|")})-\h+\.png\z}, image["content"],
          "#{page}(#{locale}) 의 og:image 가 자기 주소의 og 그림이 아니다"

        hreflangs = head.css("link[rel=alternate][hreflang]").to_h { |link| [ link["hreflang"], link["href"] ] }
        assert_equal (I18n.available_locales.map(&:to_s) + [ "x-default" ]).sort, hreflangs.keys.sort, "#{page}(#{locale}) 의 hreflang 이 언어마다 서지 않았다"
        I18n.available_locales.each do |other|
          assert_match %r{\Ahttps?://#{Regexp.escape(request.host)}(?::\d+)?/#{other}(?:/|\z)}, hreflangs[other.to_s], "#{page}(#{locale}) 의 #{other} 주소가 그 언어가 아니다"
        end
        assert_equal hreflangs[I18n.default_locale.to_s], hreflangs["x-default"], "#{page}(#{locale}) 의 x-default 가 기본 언어가 아니다"
      end
    end
  end

  test "로케일의 그림이 없으면 ko 로 떨어지고, ko 한 장은 있다" do
    assert Rails.root.join("app/assets/images/og/ko.png").exist?, "ko 의 og 그림이 없다"

    get about_path(locale: :en)
    expected = Rails.root.join("app/assets/images/og/en.png").exist? ? "en" : "ko"
    assert_match %r{/og/#{expected}-\h+\.png\z}, css_select("meta[property='og:image']").first["content"]
  end
end
