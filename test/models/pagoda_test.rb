# This app is a raft. — 이 앱도 뗏목이다.
require "test_helper"

class PagodaTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
    @sutra = heart_sutra
  end

  test "아직 한 자도 쓰지 않았으면 첫 자가 기다린다" do
    pagoda = @user.pagoda

    assert_equal 0, pagoda.last_pos
    assert_equal @sutra.chars.first, pagoda.next_char
    refute pagoda.complete?
  end

  test "경을 다 쓰면 탑이 완성되고 다음 자는 없다" do
    today = @user.today
    rows = @sutra.chars.map.with_index do |char, i|
      { user_id: @user.id, sutra_char_id: char.id, copied_on: today - (@sutra.total - i),
        glyph_paths: [ [ [ 0.5, 0.5 ] ] ], created_at: Time.current, updated_at: Time.current }
    end
    Copying.insert_all!(rows)

    pagoda = @user.pagoda
    assert_equal @sutra.total, pagoda.last_pos
    assert pagoda.complete?
    assert_nil pagoda.next_char
  end

  test "남의 사경은 내 탑에 쌓이지 않는다" do
    other = users(:two)
    other.copyings.create!(sutra_char: other.pagoda.next_char, glyph_paths: [ [ [ 0.5, 0.5 ] ] ])

    assert_equal 0, @user.pagoda.last_pos
  end
  # 탑신의 바탕은 기둥선을 따라 사다리꼴이다 — 아래가 넓고 위가 좁다.
  # 이것은 「함」이다. 몇 푼 좁은지는 결이고(pagoda_layout_test), 좁다는 것은 기능이다.
  ART = Rails.root.join("app/assets/images/pagoda.svg")

  test "탑신의 바탕은 층마다 위가 아래보다 좁다" do
    tops = washes.map { |wash| wash[:top_right] - wash[:top_left] }
    bottoms = washes.map { |wash| wash[:bottom_right] - wash[:bottom_left] }

    assert_equal 5, washes.size, "탑신이 다섯 층이 아니다"
    washes.each_with_index do |_, floor|
      assert_operator tops[floor], :<, bottoms[floor], "#{floor + 1}층의 윗변이 아랫변보다 좁지 않다"
    end

    assert_equal tops.sort.reverse, tops, "위층이 아래층보다 넓다"
  end

  test "탑신의 네 꼭짓점은 그 층 기둥선의 끝이다" do
    washes.zip(pillars).each_with_index do |(wash, pillar), floor|
      [ %i[bottom_left bottom_left], %i[bottom_right bottom_right],
        %i[top_left top_left], %i[top_right top_right] ].each do |corner, end_point|
        assert_in_delta pillar[end_point], wash[corner], 0.5,
          "#{floor + 1}층 바탕의 #{corner} 가 기둥선에서 벗어났다"
      end
    end
  end

  private
    def numbers(path) = path.scan(/-?\d+(?:\.\d+)?/).map(&:to_f)

    # 사다리꼴: M윗왼 윗y H윗오 L아랫오 아랫y H아랫왼 L윗왼 윗y Z
    def washes
      ART.read.scan(/pagoda__wash" d="([^"]+)"/).flatten.map do |path|
        x = numbers(path)
        { top_left: x[0], top_right: x[2], bottom_right: x[3], bottom_left: x[5] }
      end
    end

    # 기둥선 둘: M아랫왼 아랫y L윗왼 윗y M아랫오 아랫y L윗오 윗y
    def pillars
      ART.read.scan(/pagoda__pillar" d="([^"]+)"/).flatten.map do |path|
        x = numbers(path)
        { bottom_left: x[0], top_left: x[2], bottom_right: x[4], top_right: x[6] }
      end
    end
end
