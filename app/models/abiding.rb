# This app is a raft. — 이 앱도 뗏목이다.
#
# 아홉 자리 — 구주심(九住心). 무착 『성문지』와 『대승장엄경론』에서 온다.
#
# 머문다(住)는 것은 더 가지 않는다는 것, 곧 그침이다. 그러니 아홉 자리는
# 오르는 사다리가 아니라 쉼이 깊어지는 아홉 가지 결이다(SPIRIT §0).
#
# 절대 규칙:
#   - 사용자를 판정하는 데 쓰지 않는다. 쉰 날의 수로 자리를 부여하지
#     않고, 어느 자리를 몇 번 골랐는지 세지 않는다.
#   - 처음부터 아홉이 다 열려 있다. 잠긴 자리도, 다음 자리도 없다.
#   - 코끼리의 흰빛은 활동의 흔적이고 여기와 이어지지 않는다(§0).
#
# 글자 하나, 풀이 한 줄도 코드에 적지 않는다. 값은 data/ 의 파일에서만
# 들어온다. 파일의 키가 곧 칸의 이름이라, 모르는 키가 생기면 시드가 터진다.
class Abiding < ApplicationRecord
  FILE = Rails.root.join("data/nine_abidings.yml")
  COUNT = 9

  # 화면에 아홉을 흩어 놓는 자리 — 「흩어 놓은 돌」. 백 곱하기 육십의 뜰에서
  # 왼쪽 위가 (0, 0). 순서가 읽히지 않게 놓는다: 가로로도 세로로도 차례를
  # 따르지 않는다(abiding_test 가 지킨다). 사다리가 아니다.
  STONES = {
    1 => [ 18, 40 ], 2 => [ 40, 52 ], 3 => [ 8, 20 ], 4 => [ 56, 38 ], 5 => [ 30, 28 ],
    6 => [ 76, 50 ], 7 => [ 62, 12 ], 8 => [ 84, 26 ], 9 => [ 46, 8 ]
  }.freeze

  has_many :sittings, dependent: :nullify

  validates :pos, inclusion: { in: 1..COUNT }, uniqueness: true

  scope :in_order, -> { order(:pos) }

  # 주소에는 자리의 차례를 쓴다 — 주소는 카피가 아니다.
  def to_param = pos.to_s

  def stone = STONES.fetch(pos)

  # 이 자리의 이름 — 한국어는 한글, 영어는 풀이.
  def name = I18n.locale == :en ? gloss_en : ko

  # 로케일에 맞는 글. 영어는 번역이 아니라 그 언어로 쓴 문장이다.
  %w[one_line what_happens what_to_do power engagement hindrance image sit_hint].each do |field|
    define_method("#{field}_here") { I18n.locale == :en ? public_send("#{field}_en") : public_send(field) }
  end

  class << self
    # 이 길 전체가 말하는 것. 한 문단이라 표에 넣지 않는다 — 파일이 곧 원본이다.
    def epigraph(locale = I18n.locale)
      epigraphs.fetch(locale == :en ? "epigraph_en" : "epigraph")
    end

    def epigraphs
      @epigraphs ||= YAML.load_file(FILE).slice("epigraph", "epigraph_en").freeze
    end

    # 몇 번을 돌려도 같은 결과가 된다.
    def seed_from(path = FILE)
      rows = YAML.load_file(path).fetch("stages")

      raise ArgumentError, "#{path}: 자리가 #{rows.size}개다 — 아홉이어야 한다" unless rows.size == COUNT

      transaction do
        rows.map do |row|
          abiding = find_or_initialize_by(pos: row.fetch("pos"))
          abiding.update!(row.except("pos"))
          abiding
        end
      end
    end
  end
end
