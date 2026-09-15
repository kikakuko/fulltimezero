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

  # 예외를 만들지 않는다. 걸리면 데이터의 낱말을 고친다.
  # nth · total 은 세는 수라 화면에 쓰지 않으므로 여기서도 보지 않는다.
  test "사경 화면에 나갈 글은 모두 자물쇠를 통과한다" do
    lines = @sutra.attributes.slice("title_han", "title_ko", "edition", "translation_note").map { |k, v| [ "경.#{k}", v ] }
    @sutra.phrases.each { |p| %w[han ko en].each { |k| lines << [ "구절#{p.number}.#{k}", p[k] ] } }
    @sutra.chars.each do |c|
      %w[glyph reading sense_here gloss_en].each { |k| lines << [ "자#{c.pos}.#{k}", c[k] ] }
      c.sanskrit.to_h.each { |k, v| lines << [ "자#{c.pos}.sanskrit.#{k}", v ] }
    end

    broken = lines.filter_map do |where, line|
      locks = CopyLocks.breaks(line.to_s)
      "#{where} #{locks.inspect} #{line.to_s[0, 40]}" if locks.any?
    end

    assert_empty broken, "화면에 나갈 경전 글이 자물쇠에 걸린다"
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
