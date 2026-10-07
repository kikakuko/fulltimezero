# This app is a raft. — 이 앱도 뗏목이다.
#
# 아홉 자리의 결 — 글의 자물쇠와 흩어 놓은 돌의 차례.
require "test_helper"
require_relative "../../test_helpers/copy_locks"

class AbidingFormTest < ActiveSupport::TestCase
  setup { @abidings = nine_abidings }

  # 육력 · 사작의의 이름은 옛글의 것이라 「가르침」 자물쇠에서 뺀다(SPIRIT §5).
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

  # 장경각의 발자국에서도 사다리가 아니다. 돌은 footprint.svg 의 돌 모양 아홉 자리에
  # 놓이고, 차례를 따르지 않으며, 등지(아홉째)는 발자국 가운데에 있지 않다.
  test "발자국 안의 돌도 차례를 따르지 않고, 등지는 가운데에 없다" do
    xs = Abiding::FOOTPRINT.sort.map { |_, (x, _)| x }
    ys = Abiding::FOOTPRINT.sort.map { |_, (_, y)| y }

    [ xs, ys ].each do |axis|
      assert_not_equal axis.sort, axis
      assert_not_equal axis.sort.reverse, axis
      turns = axis.each_cons(2).map { |a, b| b <=> a }.each_cons(2).count { |a, b| a != b }
      assert_operator turns, :>=, 3, "발자국 안의 돌이 거의 한 줄이다"
    end

    svg = Rails.root.join("app/assets/images/footprint.svg").read
    shapes = svg.scan(/<path id="Vector_\d+"[^>]*d="([^"]+)"[^>]*fill="#F4F1EA"/).map do |(d)|
      nums = d.scan(/-?\d+\.?\d*/).map(&:to_f)
      xs2, ys2 = nums.each_slice(2).to_a.transpose
      [ ((xs2.min + xs2.max) / 2).round, ((ys2.min + ys2.max) / 2).round ]
    end
    assert_equal shapes.sort, Abiding::FOOTPRINT.values.sort, "돌의 자리가 그림의 돌 모양과 다르다"

    middle = [ 195, 300 ]
    nearest = Abiding::FOOTPRINT.min_by { |_, (x, y)| (x - middle[0])**2 + (y - middle[1])**2 }.first
    assert_not_equal Abiding::COUNT, nearest, "등지가 발자국 가운데에 있다"
  end
end
