# This app is a raft. — 이 앱도 뗏목이다.
#
# 경전. 앱의 것이지 사용자의 것이 아니다.
#
# 글자 하나, 풀이 한 줄도 코드에 적지 않는다. 값은 data/ 의 파일에서만
# 들어온다. 파일의 키가 곧 칸의 이름이라, 파일에 모르는 키가 생기면
# 조용히 버리지 않고 시드가 터진다.
class Sutra < ApplicationRecord
  HEART = "heart_sutra"
  HEART_FILE = Rails.root.join("data/heart_sutra.yml")

  has_many :phrases, -> { order(:number) }, class_name: "SutraPhrase", dependent: :destroy
  has_many :chars, -> { order(:pos) }, class_name: "SutraChar", dependent: :destroy

  validates :slug, presence: true, uniqueness: true
  validates :total, numericality: { greater_than: 0 }

  def self.heart = find_by!(slug: HEART)

  # 몇 번을 돌려도 같은 결과가 된다.
  def self.seed_from(path)
    data = YAML.load_file(path)
    meta = data.fetch("sutra")
    chars = data.fetch("chars")

    unless chars.size == meta.fetch("total")
      raise ArgumentError, "#{path}: 글자가 #{chars.size}개인데 total 은 #{meta["total"]}"
    end

    transaction do
      sutra = find_or_initialize_by(slug: meta.fetch("id"))
      sutra.update!(meta.except("id"))

      phrases = data.fetch("phrases").to_h do |row|
        phrase = sutra.phrases.find_or_initialize_by(number: row.fetch("id"))
        phrase.update!(han: row.fetch("han"), ko: row.fetch("ko"), en: row.fetch("en"),
                       start_pos: row.fetch("start"), end_pos: row.fetch("end"))
        [ row.fetch("id"), phrase ]
      end

      chars.each do |row|
        char = sutra.chars.find_or_initialize_by(pos: row.fetch("pos"))
        char.update!(row.except("pos", "phrase")
                        .reverse_merge("sanskrit" => nil)
                        .merge("phrase" => phrases.fetch(row.fetch("phrase"))))
      end

      sutra
    end
  end
end
