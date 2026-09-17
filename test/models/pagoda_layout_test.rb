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
  end

  # 칸은 그림의 층에 맞춰 앉는다. 그림을 다시 그리면 이 값들이 함께 바뀐다.
  test "층은 그림의 자리에 선다 — 처마 아래 숨 한 칸을 두고" do
    drawing = Rails.root.join("app/assets/images/pagoda.svg").read
    doc = Nokogiri::XML(drawing)
    _, height = PagodaLayout::VIEW

    assert_match(/viewBox="0 0 #{PagodaLayout::VIEW[0]} #{height}"/, drawing, "그림틀이 그림과 다르다")
    base_top = numbers(doc.at_css(".pagoda__base")["d"])[1]
    assert_equal PagodaLayout::GROUND, base_top.round, "기단 윗선이 칸의 바닥에 있지 않다"

    PagodaLayout.floors.each do |floor|
      rows = PagodaLayout::FLOORS[floor.layer - 1].last
      cells = PagodaLayout.cells[(floor.first - 1)..(floor.last - 1)]

      assert_equal rows * PagodaLayout::PITCH + PagodaLayout::BREATH, floor.height
      assert_equal floor.y + PagodaLayout::BREATH, cells.map(&:y).min - (PagodaLayout::PITCH - PagodaLayout::GLYPH) / 2,
        "#{floor.layer}층의 칸이 처마 아래 숨을 두고 앉지 않는다"
      assert_equal floor.y + floor.height, cells.map { |cell| cell.y + PagodaLayout::GLYPH }.max +
        (PagodaLayout::PITCH - PagodaLayout::GLYPH) / 2, "#{floor.layer}층의 칸이 바닥에 붙어 앉지 않는다"

      eave = numbers(doc.at_css(".pagoda__floor[data-layer='#{floor.layer}'] .pagoda__eave")["d"]).each_slice(2).map(&:last)
      assert_includes (eave.min..eave.max), floor.y, "#{floor.layer}층의 처마가 그림의 그 자리에 없다"
    end
  end

  test "꼭대기 한 자는 칸의 층 밖, 상륜 위에 앉는다" do
    crown = PagodaLayout.cells.last

    assert_equal PagodaLayout.capacity, crown.pos
    assert_operator crown.y + crown.size, :<, PagodaLayout.floors.last.y, "꼭대기 자리가 다섯째 층 안에 있다"
    assert_in_delta PagodaLayout::VIEW[0] / 2.0, crown.x + crown.size / 2.0, 0.01
  end

  test "탑의 칸에는 사용자가 쓴 획이 그대로 실린다 — 활자로 대신 채우지 않는다" do
    write_through(1)
    cell = PagodaLayout.scene(@user.copyings.includes(:sutra_char))[:cells].first

    assert_equal @user.copyings.first.glyph_paths, cell[:paths]
  end

  # 풍경은 그림에 이미 걸려 있다. 여기서는 어느 층이 찼는지만 알려 준다.
  test "층이 차야 그 층의 풍경이 남는다" do
    first_floor = PagodaLayout.floors.first
    write_through(first_floor.last - 1)
    floors = PagodaLayout.scene(@user.copyings.includes(:sutra_char))[:floors]

    assert_empty floors[:filled], "차지 않은 층에 풍경이 걸린다"
    assert_nil floors[:fresh]

    fresh = @user.copyings.create!(sutra_char: @user.pagoda.next_char, glyph_paths: [ [ [ 0.5, 0.5 ] ] ])
    floors = PagodaLayout.scene(@user.copyings.includes(:sutra_char), fresh: fresh)[:floors]

    assert_equal [ 1 ], floors[:filled]
    assert_equal 1, floors[:fresh], "방금 찬 층이 어느 층인지 나가지 않는다"
  end

  test "층을 채우지 않은 날에는 흔들릴 풍경이 없다" do
    write_through(3)
    fresh = @user.copyings.create!(sutra_char: @user.pagoda.next_char, glyph_paths: [ [ [ 0.5, 0.5 ] ] ])

    assert_nil PagodaLayout.scene(@user.copyings.includes(:sutra_char), fresh: fresh)[:floors][:fresh]
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

  private
    def numbers(path) = path.scan(/-?\d+(?:\.\d+)?/).map(&:to_f)
end
