# This app is a raft. — 이 앱도 뗏목이다.
#
# 소리의 무게 — 그림과 따로, 그리고 둘로 갈라 잰다.
#
# 첫 화면에서 받는 소리와 들어갈 때 받는 소리는 값이 다르다.
#
#   처음에 받는 소리(앉기의 종 · bell-start · bell-end)는 첫 화면의 무게에 더해지므로
#   작아야 한다. 느린 망의 사용자를 지키는 자리다.
#
#   들어갈 때 받는 소리(범종 · bell-temple)는 범종각을 눌러 들어가 종을 칠 때에만
#   받는다. 첫 화면 무게에 한 바이트도 더하지 않으므로 넉넉히 둔다 — 여운을 듣는
#   소리라 길고, 자르면 그 소리가 아니다.
#
# 「범종은 첫 화면에서 받지 않는다」는 성질이라 기능 쪽에서 본다
# (test/integration/bell_loading_test.rb).
require "test_helper"

class SoundsTest < ActiveSupport::TestCase
  SOUNDS = Rails.root.join("app/assets/sounds")
  # 처음에 받는 소리의 합계. 종 둘이면 한 벌에 오십~백 KB 안쪽이다.
  EAGER_MOST = 250_000
  # 들어갈 때 받는 소리 하나의 무게. 범종은 여운이 길다.
  LAZY_MOST = 3_000_000
  # 들어갈 때 받는 것들 — 이름으로 가른다.
  LAZY = %w[temple].freeze

  test "처음에 받는 소리의 합계가 상한을 넘지 않는다" do
    total = eager.sum(&:size)

    assert_operator total, :<=, EAGER_MOST,
      "첫 화면에서 받는 소리가 #{total} 바이트다(상한 #{EAGER_MOST}). 첫 화면이 그만큼 늦어진다."
  end

  test "들어갈 때 받는 소리는 저마다 상한을 넘지 않는다" do
    assert lazy.all? { |file| file.size.positive? }, "빈 음원 파일이 있다"

    lazy.each do |file|
      assert_operator file.size, :<=, LAZY_MOST,
        "#{file.basename} 이 #{file.size} 바이트다(상한 #{LAZY_MOST})."
    end
  end

  test "소리는 저장소 안에 있다 — 바깥에서 불러오지 않는다(§6)" do
    views = Rails.root.glob("app/views/**/*.erb") + Rails.root.glob("app/javascript/**/*.js")
    outward = views.select { |file| file.read.match?(/(?:src|url)\s*[=:]\s*["']https?:\/\/[^"']*\.(?:ogg|mp3|wav|m4a|opus)/) }

    assert_empty outward.map { |file| file.relative_path_from(Rails.root).to_s },
      "바깥의 소리를 부른다"
  end

  # 범종은 앉기의 종과 다른 파일이다. 같은 소리를 쓰면 「앉기가 시작됐나」 하고
  # 헷갈린다 — 앉기 종은 시작과 끝을 알리고, 범종은 여운을 듣는 소리다.
  test "범종은 앉기의 종과 다른 자리에서 온다" do
    view = Rails.root.join("app/views/bells/show.html.erb").read

    assert_match(/bell_source\(:temple\)/, view, "범종이 제 음원을 쓰지 않는다")
    assert_no_match(/bell_source\(:start\)|bell_source\(:end\)/, view, "범종이 앉기의 종을 가져다 쓴다")
  end

  # 범종은 성덕대왕신종이다. 변경금지라 받은 그대로 두어야 한다 — 자르지도,
  # 형식을 바꾸지도, 다시 누르지도 않는다. 바이트 수가 받은 그대로인지로 본다.
  GIVEN = { name: "bell-temple.mp3", bytes: 1_422_732 }.freeze

  test "범종의 음원은 받은 그대로다 — 변경금지다" do
    file = Object.new.extend(BellHelper).bell_file(:temple)

    assert_equal GIVEN[:name], file, "범종의 음원이 없거나 형식이 바뀌었다"
    assert_equal GIVEN[:bytes], SOUNDS.join(file).size,
      "범종의 음원이 받은 그대로가 아니다. 공공누리 변경금지다 — 자르거나 다시 누르지 않는다."
  end

  test "음원의 출처가 문서와 화면에 함께 적혀 있다" do
    ours = Rails.root.join("docs/SOURCES.md").read
    view = Rails.root.join("app/views/bells/show.html.erb").read

    assert_includes ours, "성덕대왕신종", "SOURCES.md 에 음원의 출처가 없다"
    assert_includes ours, "공공누리", "SOURCES.md 에 이용 조건이 없다"
    assert_match(/t\("bells\.source"\)/, view, "화면에 출처가 보이지 않는다")
    %w[ko en].each do |locale|
      assert_match(/국립경주박물관|Gyeongju National Museum/, I18n.t("bells.source", locale: locale),
        "#{locale} 의 출처 한 줄에 내어 준 곳이 없다")
    end
  end

  private
    def files
      return [] unless SOUNDS.exist?

      SOUNDS.children.reject { |file| file.directory? || file.basename.to_s.start_with?(".") }
    end

    def lazy = files.select { |file| LAZY.any? { |name| file.basename.to_s.include?(name) } }
    def eager = files - lazy
end
