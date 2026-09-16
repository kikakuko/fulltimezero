# This app is a raft. — 이 앱도 뗏목이다.
#
# 데이터 파일(경전 · 아홉 자리)의 언어별 칸 — 규칙은 여기 한 곳에 있다.
#
#   기본 칸은 한국어다.            one_line, what_happens …
#   다른 언어는 <칸>_<언어> 로 붙는다.  one_line_en, one_line_ja, one_line_zh …
#   그 언어의 칸이 없으면 영어로 보이고, 영어도 없으면 한국어로 보인다.
#   한국어에만 뜻이 있는 칸(훈음처럼)은 korean_only 로 적고, 다른 언어에서는
#   비운다 — 없는 것을 억지로 채우지 않는다.
#
# 셋째 언어가 오면 파일에 <칸>_<언어> 를 더하는 것으로 끝난다. 기계 번역은
# 없다 — 그 언어로 쓰는 사람이 쓴다.
module Localized
  extend ActiveSupport::Concern

  class_methods do
    # localized :one_line, :sit_hint            → one_line_here, sit_hint_here
    # localized korean_only: %i[reading]         → reading_here (한국어 밖에서는 nil)
    def localized(*fields, korean_only: [])
      fields.each { |field| define_method("#{field}_here") { localized_value(field) } }
      korean_only.each { |field| define_method("#{field}_here") { public_send(field) if I18n.locale == :ko } }
    end
  end

  # 지금 언어의 칸 → 영어 칸 → 한국어 칸. 있는 것 가운데 첫 것.
  def localized_value(field)
    locale = I18n.locale.to_s
    chain = locale == "ko" ? [ "#{field}_ko", field.to_s ] : [ "#{field}_#{locale}", "#{field}_en", "#{field}_ko", field.to_s ]

    chain.each do |name|
      next unless respond_to?(name)

      value = public_send(name)
      return value if value.present?
    end

    nil
  end
end
