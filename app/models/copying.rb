# This app is a raft. — 이 앱도 뗏목이다.
#
# 사경 한 자. 탑의 한 칸이다.
#
# 절대 규칙:
#   - 하루에 한 자. 몫이 끝나면 다음 자는 내일 온다(제2조).
#   - 간격이 벌어져도 아무 일도 일어나지 않는다. 한 해를 쉬었다 와도
#     탑은 그 높이 그대로이고, 다음 자가 기다리고 있을 뿐이다.
#     되돌림·초기화·감점을 두지 않는다(§3 쌓인 것은 무너지지 않는다).
#   - 글씨를 채점하지 않는다. glyph_paths 는 사용자가 그은 획 그대로
#     남을 뿐, 정답과 견주지 않는다(제3조).
#   - glyph_paths 가 비어 있으면 종이에 쓴 것이다. 화면에 쓴 자와
#     똑같이 탑을 쌓는다(§3 화면은 종이로 가는 문).
class Copying < ApplicationRecord
  # 한 자에 그을 수 있는 획과 점의 끝. 넘치는 입력을 막을 뿐, 잘 썼는지와는 상관없다.
  MOST_STROKES = 64
  MOST_POINTS = 1000

  belongs_to :user
  belongs_to :sutra_char

  validates :copied_on, presence: true, uniqueness: { scope: :user_id }
  validates :sutra_char_id, uniqueness: { scope: :user_id }
  validate :comes_in_turn, on: :create
  validate :strokes_are_strokes

  before_validation :stamp_day, on: :create

  def on_paper? = glyph_paths.nil?

  private
    def stamp_day
      self.copied_on ||= user&.today
    end

    # 경은 처음부터 차례로 쓴다. 건너뛰지도, 앞질러 가지도 않는다.
    def comes_in_turn
      return unless user && sutra_char

      errors.add(:sutra_char, :out_of_turn) unless sutra_char == user.pagoda(sutra: sutra_char.sutra).next_char
    end

    # 획이 있다면 획의 목록이어야 한다. 모양이 맞는지만 볼 뿐, 잘 썼는지는 보지 않는다.
    # 한 획은 점의 목록, 한 점은 [x, y] — 쓰는 자리 안에서의 비율이다.
    # 빈 목록은 받지 않는다. 한 획도 긋지 않았다면 그것은 화면에 쓴 것이 아니다.
    def strokes_are_strokes
      return if glyph_paths.nil?

      errors.add(:glyph_paths, :invalid) unless strokes?(glyph_paths)
    end

    def strokes?(paths)
      paths.is_a?(Array) && paths.size.between?(1, MOST_STROKES) &&
        paths.all? { |stroke| points?(stroke) }
    end

    def points?(stroke)
      stroke.is_a?(Array) && stroke.size.between?(1, MOST_POINTS) &&
        stroke.all? { |point| point.is_a?(Array) && point.size == 2 && point.all?(Numeric) }
    end
end
