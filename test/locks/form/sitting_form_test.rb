# This app is a raft. — 이 앱도 뗏목이다.
#
# 앉기의 결 — 두 길이 같은 무게로 서는 것, 무위에 달이 없는 것, 부품 다섯.
# 앉기가 도는지는 기능 쪽이다 — test/integration/sitting_flow_test.rb.
require "test_helper"

class SittingFormTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    sign_in_as @user
  end

  test "나가며 묻는 자리에는 붙잡는 것이 없다" do
    post nothing_path
    patch sitting_path(@user.sittings.last)
    follow_redirect!

    assert_select "header.chrome", false, "나가는 길에 헤더가 남아 있다"
    assert_select ".locales", false
  end

  test "앉음은 쉼으로 환산되지 않는다" do
    assert_no_difference -> { @user.rests.count } do
      post sittings_path, params: { sitting: { length: "tea" } }
      patch sitting_path(@user.sittings.last)
    end
  end

  # 달은 마당의 것이다. 앉는 동안에는 없고, 앉고 난 뒤에 그날의 달을 본다(§2).
  test "앉는 동안에는 달이 없다 — 앉고 난 뒤에 그날의 달을 본다" do
    post sittings_path, params: { sitting: { length: "tea" } }
    follow_redirect!

    assert_select ".night", count: 1
    assert_select ".night .moon", false, "앉는 동안 달이 떠 있다"
    assert_select ".night .elephant-field", count: 1, message: "앉는 동안 길이 없다"

    sitting = users(:one).sittings.last
    patch sitting_path(sitting)
    follow_redirect!

    assert_select ".moon", count: 1, message: "앉고 난 뒤에 그날의 달이 없다"
  end

  # 굽이는 길의 모양이다. 이름이 붙으면 아홉으로 세는 것이 되고, 그것은 §5 가 막는다.
  # 자리를 고르는 돌도 같다(2026-10-08) — 이름뿐 아니라 abiding 을 고르는 입력 자체가
  # 두 화면에 없고, 씨앗이 남긴 abiding 값도 화면 어디에도 나오지 않는다.
  # 아홉의 이름과 글은 장경각에만 있다.
  test "선방과 앉는 중에 아홉의 이름도, 고르는 돌도, 고른 자리도 없다" do
    user = users(:one)
    names = Abiding.in_order.map(&:name)
    user.sittings.create!(mode: "sitting", abiding: Abiding.in_order.last, ended_at: Time.current)

    get new_sitting_path
    assert_select ".elephant-field__station", false, "선방의 굽이에 이름이 붙었다"
    assert_select ".stones, .stone", false, "선방에 자리 고르는 돌이 있다"
    assert_select "input[name='sitting[abiding]']", false, "선방에 자리를 고르는 입력이 있다"
    names.each { |name| assert_no_match(/#{Regexp.escape(name)}/, visible_text, "선방에 「#{name}」이 보인다") }

    post sittings_path, params: { sitting: { length: "tea", abiding: Abiding.in_order.first.pos } }
    follow_redirect!
    assert_select ".elephant-field__station", false, "앉는 중의 굽이에 이름이 붙었다"
    assert_select ".stones, .stone", false, "앉는 중에 돌이 있다"
    names.each { |name| assert_no_match(/#{Regexp.escape(name)}/, visible_text, "앉는 중에 「#{name}」이 보인다") }
    assert_nil user.sittings.last.abiding, "고르는 길을 걷었는데 앉음에 자리가 남는다"

    assert_no_match(/station/, Rails.root.join("app/models/elephant.rb").read, "자리를 세는 셈이 되살아났다")
  end

  test "무위에는 달이 없다 — 타이머의 어둠과 결이 다르다" do
    post nothing_path
    follow_redirect!

    assert_select ".void"
    assert_select ".void .moon", false, "무위에 달이 떠 있다"
    assert_select ".night", false
    assert_match I18n.t("nothing.line"), visible_text
  end

  test "오늘 이미 고요했다면 물음이 조름이 되지 않는다" do
    get today_path
    assert_match I18n.t("today.question"), visible_text

    post nothing_path
    get today_path

    assert_match I18n.t("today.already_quiet"), visible_text
    assert_no_match(/#{I18n.t("today.question")}/, visible_text)
  end

  # 앉기의 자리에 두 길이 같은 무게로 선다. 무위를 2차 메뉴로 내려 두면
  # 그것은 곁가지가 된다.
  test "앉는다와 아무것도 하지 않는다가 나란히 선다" do
    get new_sitting_path

    assert_select ".ways button[form=sitting-form]", text: I18n.t("sittings.new.submit"), count: 1
    assert_select ".ways button[form=nothing-form]", text: I18n.t("sittings.new.nothing"), count: 1
    assert_select "form#sitting-form[action=?]", sittings_path, count: 1
    assert_select "form#nothing-form[action=?]", nothing_path, count: 1
    assert_select ".ways button.button-primary", count: 2, message: "두 길이 같은 먹 알약이 아니다"
  end

  # 톤 정비 — 앉기의 부품. 산수는 먹틀에, 두 길은 먹 알약 둘, 나오는 길은 조용한 버튼.
  test "앉기는 부품 다섯으로 선다 — 옛 버튼 없이" do
    get new_sitting_path
    assert_select ".elephant-field.ink-frame", count: 1
    assert_select ".button-primary", count: 2
    assert_select ".verse", false

    post sittings_path, params: { sitting: { length: SittingLength::DEFAULT } }
    follow_redirect!
    assert_select ".night .leave button.button-quiet", count: 1

    post nothing_path
    follow_redirect!
    assert_select ".void .leave button.button-quiet", count: 1
    patch sitting_path(Sitting.order(:id).last)
    follow_redirect!
    assert_select "a.button-primary", count: 1
    assert_select "a.button-quiet", count: 1
  end

  private
    def visible_text
      Nokogiri::HTML(response.body).css("body").text.gsub(/\s+/, " ")
    end
end
