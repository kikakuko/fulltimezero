# This app is a raft. — 이 앱도 뗏목이다.
#
# 탑의 칸 배치. 탑의 그림은 app/assets/images/pagoda.svg 가 맡고,
# 여기서는 그 그림의 층에 맞춰 글자가 앉을 자리만 센다. 그림을 다시 그리면
# 아래 상수만 고친다 — 그리는 쪽은 손대지 않는다.
#
# 오층. 한 행에 열 칸을 넘지 않고 아래가 넓다. 다섯 층이 이백쉰아홉
# 칸을 받고, 경의 마지막 자는 꼭대기(상륜)에 앉는다.
#
# 층의 높이는 그 층이 받는 줄 수로 정해진다 — 줄 수 × 칸 + 숨 하나.
# 숨(BREATH)은 처마 바로 아래의 빈 자리다. 글씨가 처마에 붙지 않는다.
# 칸은 각 층의 아래쪽에 붙어 앉고, 남는 숨은 처마 밑에 놓인다.
#
# 빈 칸은 화면으로 보내지 않는다. 쓴 자리의 좌표만 나간다 — 빈 격자가
# 보이면 몇 칸 남았는지가 세어지고, 그것은 숫자 금지의 취지에 걸린다.
class PagodaLayout
  VIEW = [ 390, 980 ].freeze # 그림틀 — 탑 그림의 viewBox 와 같다
  PITCH = 24                # 칸과 칸 사이
  GLYPH = 22                # 한 자가 차지하는 크기
  BREATH = 12               # 처마 바로 아래의 숨
  GROUND = 910              # 기단 윗선 — 첫 층의 칸이 앉는 바닥
  CROWN = 8                 # 꼭대기 한 자가 앉는 높이 — 상륜 위, 보주의 자리

  # 아래층부터 위로 — [한 행의 칸, 행]
  FLOORS = [ [ 10, 7 ], [ 9, 7 ], [ 8, 6 ], [ 7, 6 ], [ 6, 6 ] ].freeze

  Floor = Data.define(:layer, :first, :last, :x, :y, :width, :height)

  Cell = Data.define(:pos, :x, :y, :size)

  class << self
    def floors = geometry[:floors]
    def cells = geometry[:cells]

    # 층들이 받는 칸의 수 + 꼭대기 한 칸.
    def capacity = cells.size

    def floor_of(pos) = floors.find { |floor| pos.between?(floor.first, floor.last) }

    # 쓴 사경만으로 탑의 장면을 만든다. fresh 는 방금 올린 자, today 는 사용자의 오늘.
    # 칸마다 사용자가 쓴 획이 그대로 실린다. 오늘 쓴 한 자만 today 로 실려 주사로
    # 찍힌다 — 하루에 한 자만 쓰므로 탑에는 언제나 붉은 점이 하나뿐이다. 날이 바뀌면
    # 그 자는 today 로 실리지 않아 먹으로 마른다.
    #
    # 탑의 윤곽은 여기서 그리지 않는다. 어느 층이 찼는지만 알려 주면,
    # 그리는 쪽이 그 층의 풍경만 남기고 나머지 풍경은 지운다.
    def scene(copyings, fresh: nil, today: nil)
      written = copyings.sort_by { |copying| copying.sutra_char.pos }
      last = written.last&.sutra_char&.pos.to_i
      landing = fresh && floor_of(fresh.sutra_char.pos)

      {
        view: VIEW,
        floors: {
          filled: floors.select { |floor| last >= floor.last }.map(&:layer),
          fresh: (landing.layer if landing && fresh.sutra_char.pos == landing.last)
        },
        cells: written.map { |copying| cell_of(copying, fresh: copying == fresh, today: today && copying.copied_on == today) }
      }
    end

    private
      def cell_of(copying, fresh:, today:)
        cell = cells.fetch(copying.sutra_char.pos - 1)

        { pos: cell.pos, x: cell.x, y: cell.y, size: cell.size, glyph: copying.sutra_char.glyph,
          paths: copying.glyph_paths, fresh: fresh, today: today }
      end

      def geometry
        @geometry ||= build
      end

      def build
        middle = VIEW[0] / 2.0
        bottom = GROUND
        cells = []

        floors = FLOORS.each_with_index.map do |(cols, rows), index|
          width = cols * PITCH
          left = middle - width / 2.0
          first = cells.size + 1

          rows.times do |row|
            cols.times do |col|
              cells << Cell.new(pos: cells.size + 1, x: left + col * PITCH + (PITCH - GLYPH) / 2.0,
                                y: bottom - (row + 1) * PITCH + (PITCH - GLYPH) / 2.0, size: GLYPH)
            end
          end

          height = rows * PITCH + BREATH
          floor = Floor.new(layer: index + 1, first: first, last: cells.size,
                            x: left, y: bottom - height, width: width, height: height)
          bottom = floor.y
          floor
        end

        # 꼭대기 — 경의 마지막 자가 상륜 위 보주의 자리에 앉는다.
        cells << Cell.new(pos: cells.size + 1, x: middle - GLYPH / 2.0, y: CROWN, size: GLYPH)

        { floors: floors.freeze, cells: cells.freeze }.freeze
      end
  end
end
