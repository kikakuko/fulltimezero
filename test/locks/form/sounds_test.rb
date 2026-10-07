# This app is a raft. — 이 앱도 뗏목이다.
#
# 소리의 무게 — 그림과 따로 잰다.
#
# 종성은 파일이 먼저다(BellHelper). 파일이 들어오면 그 무게가 앱의 첫 화면까지
# 따라오므로 상한을 둔다. 범종은 여운을 듣는 소리라 앉기의 종보다 길고, 그래서
# 넉넉히 잡되 한없이 두지는 않는다. Opus 로 넣으면 한 벌에 오십~백오십 KB 안쪽이다.
require "test_helper"

class SoundsTest < ActiveSupport::TestCase
  SOUNDS = Rails.root.join("app/assets/sounds")
  # 합계 바이트. 늘리려면 왜 늘어야 하는지 먼저 따진다.
  MOST = 400_000

  test "소리의 합계가 정해 둔 무게를 넘지 않는다" do
    return assert true, "아직 음원이 없다" unless SOUNDS.exist?

    files = SOUNDS.children.reject { |file| file.directory? || file.basename.to_s.start_with?(".") }
    total = files.sum(&:size)

    assert_operator total, :<=, MOST,
      "소리가 #{total} 바이트다(상한 #{MOST}). 줄이거나, 왜 늘어야 하는지 정하고 상한을 고친다."
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

  # 아직 걸리지 않았으면 치지 않는다 — 합성음이 범종인 척하지 않는다.
  test "음원이 없으면 치는 손잡이가 서지 않는다" do
    assert_nil Object.new.extend(BellHelper).bell_file(:temple),
      "범종의 음원이 들어왔다. docs/SOURCES.md 에 출처와 라이선스를 적어라."
  end
end
