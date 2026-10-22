# This app is a raft. — 이 앱도 뗏목이다.
#
# 순위도 친구도 공유 자랑도 없다(docs/legal/none.md). 쉼은 남과 견주는 것이 아니다 —
# 줄 세우는 판, 따르는 사람, 자랑하러 내보내는 길, 데려오라는 초대가 들어오면 이 앱은
# 다른 앱이 된다(SPIRIT §1 · §2). 라우트 · 뷰 · 로케일 카피에 그 낱말이 없음을 잠근다.
#
# 낱말은 뜻으로 고른다. Rails 의 shared/ 부분 틀, 「다음 달(following)」, 「뒤를 따른다
# (follows)」 같은 보통 말은 걸지 않는다.
require "test_helper"

class ComparingTest < ActiveSupport::TestCase
  WORDS = /\b(?:rank|ranks|ranking|rankings|leaderboards?|friends?|follow|followers?|share|shares|sharing|invites?|invitations?)\b|순위|친구|공유|초대/i

  # 걸리되 그 뜻이 아닌 자리. 늘리기 전에 묻는다.
  ALLOWED = {
    "about.none.lines" => "「순위도 친구도 공유 자랑도 없다」 — 없다고 적은 줄이다",
    "today.done" => "「Today's share is done」 — 오늘의 몫(portion)이다. 나누는 길이 아니다"
  }.freeze

  test "라우트에 순위 · 친구 · 공유 · 초대의 길이 없다" do
    routes = Rails.application.routes.routes.map { |route| [ route.name, route.path.spec.to_s, route.defaults[:controller] ].compact.join(" ") }

    assert_empty routes.grep(WORDS), "견주고 자랑하는 길이 라우트에 있다"
  end

  test "뷰에 순위 · 친구 · 공유 · 초대의 낱말이 없다" do
    offenders = Rails.root.glob("app/views/**/*").select(&:file?).filter_map do |path|
      words = path.read.scan(WORDS)
      "#{path.relative_path_from(Rails.root)}: #{words.uniq.join(", ")}" if words.any?
    end

    assert_empty offenders, "견주고 자랑하는 낱말이 뷰에 있다"
  end

  test "로케일 카피에 순위 · 친구 · 공유 · 초대의 낱말이 없다" do
    offenders = %w[ko en].flat_map do |locale|
      leaves(YAML.load_file(Rails.root.join("config/locales/#{locale}.yml")).fetch(locale)).filter_map do |key, text|
        next if ALLOWED.any? { |allowed, _| key == allowed || key.start_with?("#{allowed}.") }

        "#{locale}.#{key}: #{text}" if text.match?(WORDS)
      end
    end

    assert_empty offenders, "견주고 자랑하는 낱말이 카피에 있다"
  end

  test "비켜 둔 자리가 아직 그 뜻으로 있다" do
    assert_match(/순위도 친구도 공유 자랑도 없다/, I18n.t("about.none.lines", locale: :ko).join)
    assert_match(/\bshare\b/, I18n.t("today.done", locale: :en), "비켜 둔 자리가 바뀌었다 — ALLOWED 에서 지운다")
  end

  private
    def leaves(node, path = [])
      case node
      when Hash then node.flat_map { |key, value| leaves(value, path + [ key ]) }
      when Array then node.each_with_index.flat_map { |value, index| leaves(value, path + [ index ]) }
      else [ [ path.join("."), node.to_s ] ]
      end
    end
end
