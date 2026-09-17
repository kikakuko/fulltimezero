# This app is a raft. — 이 앱도 뗏목이다.
#
# 내보내기. 선택 기능이 아니라 의무다(SPIRIT 제7조).
#
# 강을 건넜으면 뗏목은 두고 간다. 두고 가려면 들고 갈 것을 먼저
# 돌려받아야 한다. 그러므로 이 화면에는 붙잡는 장치가 없다 —
# 확인도, 사유를 묻는 것도, 「정말 떠나시겠습니까」도 없다.
# 눌러서 받는다. 그것으로 끝이다.
#
# 여기 담기는 것은 사용자의 것뿐이다. 앱이 지닌 것(경전 원문 같은
# 씨앗 데이터)은 사용자의 것이 아니므로 담지 않는다.
#
# 여기에는 날짜가 숫자로 적힌다. 숫자 금지는 **화면**의 규정이고,
# 이것은 화면이 아니라 들고 나가는 파일이다. 사람이 읽고 다른 도구가
# 읽을 수 있어야 하므로 날짜는 날짜대로 적는다.
class Export
  # 사용자의 것은 빠짐없이 내보낸다. 사용자에게 딸린 것이 새로 생기면
  # 여기에 자리를 만들어야 한다 — 그러지 않으면 export_test 가 깨진다.
  # 세션은 누구의 것인지 말고 아무것도 담지 않으므로 내보낼 것이 없다.
  SECTIONS = {
    rests: :rests, sittings: :sittings, plans: :plans,
    clearings: :cleared_days, copyings: :copyings
  }.freeze

  attr_reader :user, :on

  def initialize(user, on: nil)
    @user = user
    @on = on || user.today
  end

  def filename(extension) = "fulltimezero-#{on.iso8601}.#{extension}"

  def json
    JSON.pretty_generate(
      exported_on: on.iso8601,
      account: account,
      rests: rests,
      sittings: sittings,
      plans: plans,
      cleared_days: clearings,
      copyings: copyings
    )
  end

  def markdown
    sections = [
      heading,
      section(t("settings.export.rests"), rest_lines),
      section(t("settings.export.sittings"), sitting_lines),
      section(t("settings.export.plans"), plan_lines),
      section(t("settings.export.cleared"), clearing_lines),
      section(t("settings.export.copyings"), copying_lines)
    ]

    sections.compact.join("\n\n") + "\n"
  end

  private
    def account
      {
        email_address: user.email_address,
        locale: user.locale,
        time_zone: user.time_zone,
        what_moves: user.what_moves,
        maitreya_seen_on: user.maitreya_seen_on&.iso8601,
        joined_on: user.created_at.in_time_zone(user.time_zone).to_date.iso8601
      }
    end

    def rests
      user.rests.chronological.map do |rest|
        { rested_on: rest.rested_on.iso8601, duration: rest.duration,
          texture: rest.texture, note: rest.note }
      end
    end

    def sittings
      user.sittings.chronological.map do |sitting|
        { sat_on: sitting.sat_on.iso8601, mode: sitting.mode, abiding: sitting.abiding&.ko }
      end
    end

    def plans
      user.plans.order(:planned_on, :created_at).map do |plan|
        { planned_on: plan.planned_on.iso8601, what: plan.what }
      end
    end

    def clearings
      user.clearings.order(:cleared_on).map { |clearing| clearing.cleared_on.iso8601 }
    end

    # 사경한 자 — 쓴 획 그대로.
    def copyings
      copied.map do |copying|
        { copied_on: copying.copied_on.iso8601, pos: copying.sutra_char.pos,
          glyph: copying.sutra_char.glyph, glyph_paths: copying.glyph_paths }
      end
    end

    def copied = user.copyings.includes(:sutra_char).order(:copied_on)

    # ── 사람이 읽는 쪽 ──

    def heading
      [ "# #{t("app.name")}", "",
        "#{t("settings.export.taken_on")}: #{on.iso8601}",
        "#{t("users.email")}: #{user.email_address}",
        "#{t("settings.time_zone")}: #{user.time_zone}" ].join("\n")
    end

    # 비어 있는 자리는 아예 두지 않는다. 없는 것을 「없음」이라고
    # 적어 두면 그것도 하나의 지표가 된다.
    def section(title, lines)
      body = lines.dup
      body.pop while body.last == ""

      return if body.empty?

      ([ "## #{title}", "" ] + body).join("\n")
    end

    def rest_lines
      user.rests.chronological.map do |rest|
        words = [ t("rests.durations.#{rest.duration}") ]
        words << t("rests.textures.#{rest.texture}") if rest.texture
        words << rest.note if rest.note

        "- #{rest.rested_on.iso8601} · #{words.join(" · ")}"
      end
    end

    def sitting_lines
      user.sittings.chronological.map do |sitting|
        kind = sitting.nothing? ? t("sittings.new.nothing") : t("sittings.sitting")

        "- #{sitting.sat_on.iso8601} · #{kind}"
      end
    end

    def plan_lines
      user.plans.order(:planned_on, :created_at).group_by(&:planned_on).flat_map do |date, plans|
        [ "### #{date.iso8601}", "" ] + plans.map { |plan| "- #{plan.what}" } + [ "" ]
      end
    end

    def clearing_lines
      user.clearings.order(:cleared_on).map { |clearing| "- #{clearing.cleared_on.iso8601}" }
    end

    def copying_lines
      copied.map { |copying| "- #{copying.copied_on.iso8601} · #{copying.sutra_char.glyph}" }
    end

    def t(key) = I18n.t(key, locale: user.locale)
end
