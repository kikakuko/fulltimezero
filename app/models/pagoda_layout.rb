# This app is a raft. — 이 앱도 뗏목이다.
#
# 탑의 임시 배치. 나중에 통째로 갈아 끼울 수 있게 여기 한 곳에만 둔다 —
# 아래 상수들을 바꾸면 탑의 모양이 바뀌고, 그리는 쪽은 손대지 않는다.
#
# 오층. 한 행에 열 칸을 넘지 않고 아래가 넓다. 다섯 층이 이백쉰아홉
# 칸을 받고, 경의 마지막 자는 꼭대기(상륜)에 앉는다.
#
# 빈 칸은 화면으로 보내지 않는다. 쓴 자리의 좌표만 나간다 — 빈 격자가
# 보이면 몇 칸 남았는지가 세어지고, 그것은 숫자 금지의 취지에 걸린다.
# 탑의 윤곽선은 칸이 아니라 층으로 그린다.
class PagodaLayout
  VIEW = [ 300, 940 ].freeze # 그림틀 너비 · 높이
  PITCH = 24                # 칸과 칸 사이
  GLYPH = 22                # 한 자가 차지하는 크기
  EAVE = 18                 # 층과 층 사이, 처마가 들어가는 틈
  OVERHANG = 16             # 처마가 층 밖으로 나가는 길이
  GROUND = 900              # 탑이 서는 땅

  # 아래층부터 위로 — [한 행의 칸, 행]
  FLOORS = [ [ 10, 7 ], [ 9, 7 ], [ 8, 6 ], [ 7, 6 ], [ 6, 6 ] ].freeze

  Floor = Data.define(:first, :last, :x, :y, :width, :height) do
    def eave_path
      x0 = x - OVERHANG
      x1 = x + width + OVERHANG
      top = y - 4

      "M #{x0} #{top - 3} Q #{x0 + 6} #{top} #{x0 + 14} #{top} " \
        "L #{x1 - 14} #{top} Q #{x1 - 6} #{top} #{x1} #{top - 3}"
    end

    def outline_path = "M #{x} #{y + height} V #{y} H #{x + width} V #{y + height}"

    # 풍경은 처마 양 끝에 하나씩 걸린다.
    def bells_at = [ x - OVERHANG, x + width + OVERHANG ].map { |edge| { x: edge, y: y - 7 } }
  end

  Cell = Data.define(:pos, :x, :y, :size)

  class << self
    def floors = geometry[:floors]
    def cells = geometry[:cells]
    def finial = geometry[:finial]

    # 층들이 받는 칸의 수 + 꼭대기 한 칸.
    def capacity = cells.size

    # 쓴 사경만으로 탑의 장면을 만든다. fresh 는 방금 올린 자.
    # 칸마다 사용자가 쓴 획이 그대로 실린다.
    def scene(copyings, fresh: nil)
      written = copyings.sort_by { |copying| copying.sutra_char.pos }
      last = written.last&.sutra_char&.pos.to_i

      {
        view: VIEW,
        outline: floors.map(&:outline_path) + [ finial[:pole] ],
        eaves: floors.map(&:eave_path),
        bells: floors.select { |floor| last >= floor.last }.flat_map do |floor|
          floor.bells_at.map { |bell| bell.merge(fresh: fresh&.sutra_char&.pos == floor.last) }
        end,
        cells: written.map { |copying| cell_of(copying, fresh: copying == fresh) }
      }
    end

    private
      def cell_of(copying, fresh:)
        cell = cells.fetch(copying.sutra_char.pos - 1)

        { pos: cell.pos, x: cell.x, y: cell.y, size: cell.size, glyph: copying.sutra_char.glyph,
          paths: copying.glyph_paths, fresh: fresh }
      end

      def geometry
        @geometry ||= build
      end

      def build
        middle = VIEW[0] / 2.0
        ground = GROUND
        cells = []
        floors = FLOORS.map do |cols, rows|
          width = cols * PITCH
          left = middle - width / 2.0
          first = cells.size + 1

          rows.times do |row|
            cols.times do |col|
              cells << Cell.new(pos: cells.size + 1, x: left + col * PITCH + (PITCH - GLYPH) / 2.0,
                                y: ground - (row + 1) * PITCH + (PITCH - GLYPH) / 2.0, size: GLYPH)
            end
          end

          floor = Floor.new(first: first, last: cells.size, x: left, y: ground - rows * PITCH,
                            width: width, height: rows * PITCH)
          ground = floor.y - EAVE
          floor
        end

        # 꼭대기 — 경의 마지막 자가 앉는 자리와 그 아래 기둥.
        top = ground - GLYPH - 12
        cells << Cell.new(pos: cells.size + 1, x: middle - GLYPH / 2.0, y: top, size: GLYPH)

        { floors: floors.freeze, cells: cells.freeze,
          finial: { pole: "M #{middle} #{ground + EAVE - 4} V #{top + GLYPH}" } }.freeze
      end
  end
end
