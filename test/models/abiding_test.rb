# This app is a raft. — 이 앱도 뗏목이다.
#
# 아홉 자리. 오르는 사다리가 아니라 쉼이 깊어지는 아홉 가지 결이다.
require "test_helper"
require_relative "../test_helpers/copy_locks"

class AbidingTest < ActiveSupport::TestCase
  setup { @abidings = nine_abidings }

  test "자리는 아홉이고, 처음부터 다 열려 있다" do
    assert_equal Abiding::COUNT, @abidings.size
    assert_equal (1..9).to_a, @abidings.map(&:pos)
    assert_no_match(/locked|open_at|unlock|required|reached/, Abiding.column_names.join(" "), "잠기는 자리가 있다")
  end

  # 값은 파일에서만 온다. 몇 번을 심어도 같은 아홉이다.
  test "몇 번을 심어도 같은 아홉이다" do
    Abiding.seed_from
    Abiding.seed_from

    assert_equal Abiding::COUNT, Abiding.count
  end

  test "모르는 칸이 파일에 생기면 시드가 터진다" do
    path = Rails.root.join("tmp/abidings_with_stranger.yml")
    data = YAML.load_file(Abiding::FILE)
    data["stages"].first["score"] = 1
    path.write(data.to_yaml)

    assert_raises(ActiveModel::UnknownAttributeError) { Abiding.seed_from(path) }
  ensure
    path.delete if path.exist?
  end

  # 육력(六力)과 사작의(四作意)의 이름은 무착 『성문지』의 낱말이다 — 앱이
  # 사용자에게 하는 말이 아니라 옛글의 이름이므로 가르침의 자물쇠 밖이다.
  # 「인용 원문은 예외다. 옛글의 낱말은 옛글의 것이다」(SPIRIT §5).
  # 새 예외가 아니라 있는 규칙의 적용이다. 숫자 · 느낌표 · 이모지는 그대로 건다.
  CLASSICAL = %w[power engagement].freeze

  # 화면에 나가는 글에는 카피와 같은 자물쇠를 건다 — 가르침 · 숫자 · 느낌표 · 이모지.
  test "아홉 자리의 글은 자물쇠를 다 지난다" do
    fields = %w[ko gloss_en one_line what_happens what_to_do power engagement hindrance image sit_hint] +
             %w[one_line_en what_happens_en what_to_do_en power_en engagement_en hindrance_en image_en sit_hint_en]

    @abidings.each do |abiding|
      fields.each do |field|
        broken = CopyLocks.breaks(abiding.public_send(field))
        broken -= [ "가르침" ] if CLASSICAL.include?(field.delete_suffix("_en"))

        assert_empty broken, "#{abiding.ko}.#{field} 이 자물쇠에 걸린다"
      end
    end

    I18n.available_locales.each { |locale| assert_empty CopyLocks.breaks(Abiding.epigraph(locale)), "#{locale} 머리글이 자물쇠에 걸린다" }
  end

  # 사다리가 아니다. 돌은 흩어 놓는다 — 가로로도 세로로도 차례를 따르지 않는다.
  test "흩어 놓은 돌은 차례를 따르지 않는다" do
    xs = Abiding::STONES.sort.map { |_, (x, _)| x }
    ys = Abiding::STONES.sort.map { |_, (_, y)| y }

    [ xs, ys ].each do |axis|
      assert_not_equal axis.sort, axis, "돌이 한쪽으로 오른다"
      assert_not_equal axis.sort.reverse, axis, "돌이 한쪽으로 내려간다"
      turns = axis.each_cons(2).map { |a, b| b <=> a }.each_cons(2).count { |a, b| a != b }
      assert_operator turns, :>=, 3, "돌이 거의 한 줄이다"
    end

    assert_equal 9, Abiding::STONES.values.uniq.size
    Abiding::STONES.values.each { |x, y| assert x.between?(0, 100) && y.between?(0, 60), "돌이 뜰 밖에 있다" }
  end

  # 자리는 사람을 판정하지 않는다. 쉰 날의 수로 자리를 부여하는 코드가 없다.
  test "쉰 날의 수로 자리를 부여하지 않는다" do
    sources = Rails.root.glob("app/**/*.rb").map(&:read).join

    assert_no_match(/Abiding\.(?:for|of|reached|current|assign|by_count|from_days)/, sources,
      "코드가 사용자에게 자리를 부여한다")
    assert_no_match(/sittings\.(?:group|count)\([^)]*abiding/, sources, "자리별로 앉음을 센다")
  end
end
