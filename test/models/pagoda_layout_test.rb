# This app is a raft. — 이 앱도 뗏목이다.
require "test_helper"

class PagodaLayoutTest < ActiveSupport::TestCase
  setup do
    @sutra = heart_sutra
    @user = users(:one)
  end

  test "탑의 칸은 경의 글자 수와 같다 — 다섯 층과 꼭대기" do
    assert_equal @sutra.total, PagodaLayout.capacity
    assert_equal 5, PagodaLayout.floors.size
    assert_equal @sutra.total, PagodaLayout.cells.last.pos, "경의 마지막 자가 꼭대기에 앉지 않는다"
  end

  test "한 행에 열 칸을 넘지 않고 아래가 넓다" do
    cols = PagodaLayout::FLOORS.map(&:first)

    assert_operator cols.max, :<=, 10
    assert_equal cols.sort.reverse, cols, "위층이 아래층보다 넓다"
    assert_equal cols.uniq, cols, "넓이가 같은 층이 있다"
  end

  test "칸은 겹치지 않고 그림틀 안에 있다" do
    width, height = PagodaLayout::VIEW
    spots = PagodaLayout.cells.map { |cell| [ cell.x, cell.y ] }

    assert_equal spots.uniq.size, spots.size
    assert PagodaLayout.cells.all? { |c| c.x >= 0 && c.y >= 0 && c.x + c.size <= width && c.y + c.size <= height }
  end

  test "층은 빈틈없이 이어서 채워진다" do
    edges = PagodaLayout.floors.map { |floor| [ floor.first, floor.last ] }

    assert_equal 1, edges.first.first
    edges.each_cons(2) { |(_, last), (first, _)| assert_equal last + 1, first }
  end

  # 빈 격자가 보이면 몇 칸 남았는지가 세어진다 — 숫자 금지의 취지.
  # 그래서 쓰지 않은 칸은 서버를 떠나지 않는다.
  test "장면에는 쓴 칸만 실린다 — 빈 칸의 자리는 나가지 않는다" do
    write_through(3)
    scene = PagodaLayout.scene(@user.copyings.includes(:sutra_char))

    assert_equal [ 1, 2, 3 ], scene[:cells].map { |cell| cell[:pos] }
    assert_equal PagodaLayout.floors.size, scene[:eaves].size, "처마는 층마다 하나"
  end

  test "탑의 칸에는 사용자가 쓴 획이 그대로 실린다 — 활자로 대신 채우지 않는다" do
    write_through(1)
    cell = PagodaLayout.scene(@user.copyings.includes(:sutra_char))[:cells].first

    assert_equal @user.copyings.first.glyph_paths, cell[:paths]
  end

  test "한 층이 차면 처마 양 끝에 풍경이 걸린다" do
    first_floor = PagodaLayout.floors.first
    write_through(first_floor.last - 1)
    assert_empty PagodaLayout.scene(@user.copyings.includes(:sutra_char))[:bells]

    fresh = @user.copyings.create!(sutra_char: @user.pagoda.next_char, glyph_paths: [ [ [ 0.5, 0.5 ] ] ])
    bells = PagodaLayout.scene(@user.copyings.includes(:sutra_char), fresh: fresh)[:bells]

    assert_equal 2, bells.size
    assert bells.all? { |bell| bell[:fresh] }, "방금 층을 채웠는데 풍경이 새로 걸리지 않는다"
    assert_equal PagodaLayout::VIEW[0], bells.sum { |bell| bell[:x] }, "풍경이 탑의 가운데를 두고 짝을 이루지 않는다"
  end

  private
    def write_through(pos)
      today = @user.today
      rows = @sutra.chars.where(pos: 1..pos).map do |char|
        { user_id: @user.id, sutra_char_id: char.id, copied_on: today - (pos - char.pos + 1),
          glyph_paths: [ [ [ 0.5, 0.5 ] ] ], created_at: Time.current, updated_at: Time.current }
      end
      Copying.insert_all!(rows)
    end
end
