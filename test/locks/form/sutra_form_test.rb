# This app is a raft. — 이 앱도 뗏목이다.
#
# 경의 결 — 사경 화면에 나갈 글이 카피의 자물쇠를 지난다.
require "test_helper"

class SutraFormTest < ActiveSupport::TestCase
  setup do
    @file = YAML.load_file(Sutra::HEART_FILE)
    @sutra = heart_sutra
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
