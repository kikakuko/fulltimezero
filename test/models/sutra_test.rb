# This app is a raft. — 이 앱도 뗏목이다.
require "test_helper"

# 경전은 파일에서 온다. 이 테스트도 기대값을 파일에서 읽는다 —
# 테스트에 글자를 적어 두면 그것이 곧 코드에 적은 셈이 되므로.
class SutraTest < ActiveSupport::TestCase
  setup do
    @file = YAML.load_file(Sutra::HEART_FILE)
    @sutra = heart_sutra
  end

  test "경의 모든 자와 구절이 파일에서 들어온다" do
    assert_equal @file["chars"].size, @sutra.chars.count
    assert_equal @file["phrases"].size, @sutra.phrases.count
    assert_equal @file["sutra"]["total"], @sutra.total

    [ @file["chars"].first, @file["chars"].last ].each do |row|
      char = @sutra.chars.find_by!(pos: row["pos"])

      %w[glyph reading sense_here gloss_en nth total].each do |key|
        assert_equal row[key], char[key], "#{row["pos"]}번 자리의 #{key} 가 파일과 다르다"
      end
    end
  end

  test "구절이 경 전체를 빈틈도 겹침도 없이 덮는다" do
    covered = @sutra.phrases.flat_map { |phrase| phrase.span.to_a }

    assert_equal (1..@sutra.total).to_a, covered
  end

  test "모든 자가 제 구절 안에 있다" do
    @sutra.chars.includes(:phrase).each do |char|
      assert_includes char.phrase.span, char.pos, "#{char.pos}번 자리가 제 구절 밖에 있다"
    end
  end

  test "소리를 옮긴 자에만 원어가 붙는다" do
    expected = @file["chars"].count { |row| row["sanskrit"] }

    assert_equal expected, @sutra.chars.count(&:transliterated?)
  end

  test "다시 심어도 늘지 않는다" do
    assert_no_difference [ -> { Sutra.count }, -> { SutraPhrase.count }, -> { SutraChar.count } ] do
      Sutra.seed_from(Sutra::HEART_FILE)
    end
  end

  test "파일에 모르는 키가 생기면 조용히 버리지 않고 터진다" do
    with_changed_file(->(data) { data["sutra"]["mystery"] = "모르는 값" }) do |path|
      assert_raises(ActiveModel::UnknownAttributeError) { Sutra.seed_from(path) }
    end
  end

  test "글자 수가 total 과 다르면 터진다" do
    with_changed_file(->(data) { data["chars"].pop }) do |path|
      assert_raises(ArgumentError) { Sutra.seed_from(path) }
    end
  end

  private
    def with_changed_file(change)
      data = YAML.load_file(Sutra::HEART_FILE)
      change.call(data)

      Tempfile.create([ "sutra", ".yml" ]) do |file|
        file.write(data.to_yaml)
        file.flush
        yield file.path
      end
    end
end
