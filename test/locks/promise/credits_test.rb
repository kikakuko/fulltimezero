# This app is a raft. — 이 앱도 뗏목이다.
require "test_helper"

# 빌려온 것의 출처는 반드시 밝힌다 — 약속이다.
#
# 공공누리 제3유형(출처표시 + 변경금지)으로 열어 준 것을 쓰면서 출처를 지우면
# 이용조건을 어기는 것이고, 내어 준 곳에 대한 배신이다. 결이 아니라 약속인
# 까닭이다 — 자리를 옮길 수는 있어도 지울 수는 없다.
#
# 쓰는 화면에는 한 줄만 두고(도상 곁에 설명을 두지 않는다, §2), 전문은
# 「쓰인 것들」에 둔다. 그 한 줄이 그리로 간다.
class CreditsTest < ActionDispatch::IntegrationTest
  include Screens

  # 공공누리가 반드시 들어가라고 한 셋.
  MUST = { "기관명" => "국립경주박물관", "저작물명" => "성덕대왕신종", "이용조건" => "공공누리" }.freeze

  test "음원을 쓰는 동안 그 출처가 화면에 선다" do
    skip "아직 음원이 없다" unless Object.new.extend(BellHelper).bell_file(:temple)

    sign_in_as users(:one)

    I18n.available_locales.each do |locale|
      get credits_path(locale: locale)
      assert_response :success

      notice = Nokogiri::HTML(response.body).css(".credit").text
      MUST.each do |what, word|
        assert_includes notice, word, "쓰인 것들(#{locale})의 표기에 #{what} 이 없다"
      end
    end
  end

  test "쓰는 자리에서 그 자리로 가는 길이 있다" do
    skip "아직 음원이 없다" unless Object.new.extend(BellHelper).bell_file(:temple)

    sign_in_as users(:one)
    get bells_path

    assert_select "a[href=?]", credits_path(locale: :ko), { count: 1 },
      "범종각의 출처 한 줄이 전문으로 가지 않는다"
    assert_includes Nokogiri::HTML(response.body).text, "국립경주박물관",
      "범종각에 내어 준 곳이 보이지 않는다"
  end

  test "쓰인 것들은 계정 없이도 열린다 — 손님도 출처를 볼 수 있다" do
    I18n.available_locales.each do |locale|
      get credits_path(locale: locale)

      assert_response :success, "쓰인 것들(#{locale}) 이 계정을 묻는다"
    end
  end

  # 자리는 비어 있어도 된다. 다만 빌려온 것이 있으면 그 줄이 있어야 한다.
  test "빌려온 것마다 한 줄이 있다" do
    get credits_path

    page = Nokogiri::HTML(response.body)
    borrowed = Object.new.extend(BellHelper).bell_file(:temple) ? 1 : 0

    assert_equal borrowed, page.css(".credit").size, "빌려온 것과 적힌 줄의 수가 다르다"
  end
end
