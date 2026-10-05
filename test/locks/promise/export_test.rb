# This app is a raft. — 이 앱도 뗏목이다.
require "test_helper"

class ExportTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
    @user.rests.create!(rested_on: @user.today, duration: "a_while",
                        texture: "sat_still", note: "창가에서")
    @user.sittings.create!(mode: "nothing")
    @user.plans.create!(planned_on: @user.today, what: "치과")
    @user.clearings.create!(cleared_on: @user.today + 1)
  end

  test "쉼도 앉음도 일정도 비움도 빠짐없이 들고 나간다" do
    data = JSON.parse(Export.new(@user).json)

    assert_equal 1, data["rests"].size
    assert_equal 1, data["sittings"].size
    assert_equal 1, data["plans"].size
    assert_equal 1, data["cleared_days"].size
    assert_equal @user.email_address, data.dig("account", "email_address")
  end

  test "「무엇에서 쉬려 하는가」에 적은 한 줄도 사용자의 것이다" do
    @user.update!(what_moves: "끝나지 않는 생각")

    assert_equal "끝나지 않는 생각", JSON.parse(Export.new(@user).json).dig("account", "what_moves")
  end

  test "미륵의 장면을 본 날도 들고 나간다" do
    @user.update!(maitreya_seen_on: Date.new(2026, 9, 17))

    assert_equal "2026-09-17", JSON.parse(Export.new(@user).json).dig("account", "maitreya_seen_on")
  end

  test "쉼의 결과 메모까지 남김없이 담긴다 — 반쪽짜리 내보내기는 내보내기가 아니다" do
    rest = JSON.parse(Export.new(@user).json)["rests"].first

    assert_equal "a_while", rest["duration"]
    assert_equal "sat_still", rest["texture"]
    assert_equal "창가에서", rest["note"]
    assert_equal @user.today.iso8601, rest["rested_on"]
  end

  test "남의 기록은 한 줄도 담기지 않는다" do
    other = users(:two)
    other.rests.create!(rested_on: other.today, duration: "one_breath", note: "남의 것")

    assert_not_includes Export.new(@user).markdown, "남의 것"
    assert_not_includes Export.new(@user).json, "남의 것"
  end

  test "앱의 것은 사용자의 것이 아니므로 담지 않는다" do
    keys = JSON.parse(Export.new(@user).json).keys

    assert_equal %w[exported_on account rests sittings plans cleared_days copyings], keys
  end

  # 데이터는 언제든 통째로 들고 나갈 수 있다(제7조 — 개정하지 않는 조항).
  # 사용자에게 딸린 것이 새로 생겼는데 내보내기에 자리가 없으면 깨진다.
  test "사용자의 것은 빠짐없이 내보낸다" do
    owned = User.reflect_on_all_associations(:has_many).map(&:name) - [ :sessions ]

    assert_equal owned.sort, Export::SECTIONS.keys.sort,
      "사용자에게 딸린 것 가운데 내보내기에 빠진 것이 있다"
    assert_equal Export::SECTIONS.values.map(&:to_s).sort,
      (JSON.parse(Export.new(@user).json).keys - %w[exported_on account]).sort
  end

  test "사경한 자도 획까지 들고 나간다" do
    heart_sutra
    @user.copyings.create!(sutra_char: @user.pagoda.next_char, glyph_paths: [ [ [ 0.2, 0.3 ] ] ])
    copying = JSON.parse(Export.new(@user).json)["copyings"].first

    assert_equal 1, copying["pos"]
    assert_equal [ [ [ 0.2, 0.3 ] ] ], copying["glyph_paths"]
    assert_includes Export.new(@user).markdown, copying["glyph"]
  end

  test "사람이 읽는 쪽은 사용자의 언어로 적힌다" do
    @user.update!(locale: "ko")
    assert_includes Export.new(@user).markdown, "한동안"

    @user.update!(locale: "en")
    assert_includes Export.new(@user).markdown, "a while"
  end

  test "비어 있는 자리는 아예 두지 않는다 — 없음도 하나의 지표다" do
    empty = users(:two)
    markdown = Export.new(empty).markdown

    assert_includes markdown, empty.email_address
    assert_not_includes markdown, "##"
    assert_no_match(/없음|none|empty/i, markdown)
  end

  test "파일 이름에 내려받은 날이 적힌다" do
    export = Export.new(@user, on: Date.new(2026, 9, 9))

    assert_equal "fulltimezero-2026-09-09.md", export.filename("md")
    assert_equal "fulltimezero-2026-09-09.json", export.filename("json")
  end

  test "다른 도구가 읽을 수 있는 데이터다" do
    assert_nothing_raised { JSON.parse(Export.new(@user).json) }
  end
end
