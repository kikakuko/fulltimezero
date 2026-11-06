# This app is a raft. — 이 앱도 뗏목이다.
#
# 그림의 참조 장부(docs/art-sources.md)의 결 — 인용 장부(Citation::CHECKED 의 license 칸)처럼,
# 참조 그림마다 이용 조건이 적혀 있고 그것이 허락된 것 안에 있어야 한다. 남의 그림을 연장에 넣는
# 일이라 조건이 비면 그 순간 출처에 대한 정직이 무너진다. 씀은 퍼블릭 도메인 · CC0 · CC BY ·
# 공공누리 제1유형만, CC BY-SA 는 미룸. 결과 그림은 쓴 참조를 번호로 잇는다.
require "test_helper"

class ArtSourcesTest < ActiveSupport::TestCase
  LEDGER = Rails.root.join("docs/art-sources.md")
  COLUMNS = %w[번호 전각 무엇 소장처 주소 이용\ 조건 해상도 확인한\ 날 씀].freeze
  USABLE = /\A(?:퍼블릭 도메인(?:\(저작권 제한 없음\))?|CC0|CC BY \d\.\d|공공누리 제1유형)\z/
  DEFERRED = /\ACC BY-SA \d\.\d\z/
  HALLS = %w[선방 장경각 미륵당 사경실 범종각 일주문 천왕문 불이문 마당 조감도].freeze

  def section(title) = LEDGER.read[/^## #{title}\n(.*?)(?=^## |\z)/m, 1].to_s

  def rows(text) = text.lines.grep(/^\|/).map { |line| line.strip.delete_prefix("|").delete_suffix("|").split("|").map(&:strip) }

  def references
    table = rows(section("참조"))
    assert_equal COLUMNS, table.first, "참조 장부의 칸이 바뀌었다"
    table.drop(2).map { |cells| COLUMNS.zip(cells).to_h }
  end

  test "참조마다 모든 칸이 차 있고, 이용 조건은 허락된 것 안에 있다" do
    assert_not_empty references

    references.each do |row|
      label = row["번호"]
      assert_match(/\AR\d{2}\z/, label)
      (COLUMNS - %w[소장처]).each { |column| assert row[column].present?, "#{label} 의 #{column} 칸이 비었다" }
      assert row["소장처"].present?, "#{label} 의 소장처 칸이 비었다 — 모르면 「—」"
      assert_includes HALLS, row["전각"], "#{label} 의 전각이 장부의 것이 아니다"
      assert_match(%r{\Ahttps://}, row["주소"], "#{label} 의 주소가 주소가 아니다")
      assert_match(/\A\d{4}-\d{2}-\d{2}\z/, row["확인한 날"], "#{label} 의 확인한 날이 날짜가 아니다")
      assert_match(/\A\d+×\d+\z/, row["해상도"], "#{label} 의 해상도가 가로×세로가 아니다")

      case row["씀"]
      when "씀" then assert_match USABLE, row["이용 조건"], "#{label} 은 씀인데 조건이 허락된 것 밖이다: #{row["이용 조건"]}"
      when "미룸" then assert_match DEFERRED, row["이용 조건"], "#{label} 은 미룸인데 CC BY-SA 가 아니다"
      else flunk "#{label} 의 씀 칸은 씀 · 미룸 둘 가운데 하나다"
      end
    end
    assert_equal references.size, references.map { |row| row["번호"] }.uniq.size, "번호가 겹친다"
  end

  test "변경 금지 · 상업 금지 자료는 장부에 없다" do
    assert_no_match(/공공누리 제?[234]유형|CC BY-(?:NC|ND)|NoDerivs|비영리/, section("참조"), "참조에 넣을 수 없는 조건이 있다")
  end

  test "예경당은 비워 두고, 사경실은 방의 꼴로만 쓴다" do
    assert_empty references.select { |row| row["전각"] == "예경당" }, "예경당의 참조가 골라졌다 — 무엇을 하는 전각인지 먼저 정한다"
    references.select { |row| row["전각"] == "사경실" }.each do |row|
      assert row["무엇"].start_with?("방의 꼴"), "#{row["번호"]} — 사경실 참조가 방의 꼴이 아니다"
      assert_no_match(/감지|금니|사경 유물|다라니/, row["무엇"], "#{row["번호"]} — 감지 · 금니의 색을 들인다(§2)")
    end
  end

  test "결과 그림은 쓴 참조를 장부의 번호로 잇고, 씀인 것만 쓴다" do
    table = rows(section("결과 그림"))
    assert_equal %w[그림 전각 쓴\ 참조 만든\ 날 들였나], table.first, "결과 그림 장부의 칸이 바뀌었다"
    usable = references.select { |row| row["씀"] == "씀" }.map { |row| row["번호"] }

    table.drop(2).each do |picture, _hall, used, made, taken|
      assert used.present?, "#{picture} 의 쓴 참조 칸이 비었다 — 참조 없이 만들었으면 「없음」"
      assert_match(/\A\d{4}-\d{2}-\d{2}\z/, made, "#{picture} 의 만든 날이 날짜가 아니다")
      # 물러남 — 한때 들였다가 다른 그림으로 갈음해 앱에서 뺀 것(2026-11-06). 들인 내력은 지우지 않는다.
      assert_includes %w[예 아니오 물러남], taken
      used.scan(/R\d{2}/).each { |label| assert_includes usable, label, "#{picture} 이 장부에 없거나 미룸인 참조 #{label} 을 썼다" }
    end
  end
end
