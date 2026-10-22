# This app is a raft. — 이 앱도 뗏목이다.
#
# 조감도의 전각이 어디로 이어지는지. 길은 여기, 자리는 Compound 에.
module CompoundHelper
  def compound_path_for(hall)
    case hall.key
    when :sitting then new_sitting_path
    when :maitreya then days_path
    when :copying then new_copying_path
    when :lecture then guide_path
    when :bowing then bows_path
    when :bell then bells_path
    when :courtyard then "#rest"
    when :gate then threshold_path
    end
  end

  # 전각의 전면 그림 — 있는 것은 둘뿐이다(선방 · 미륵당). 카드를 여는 손짓에 이 한 장을 미리
  # 받는다. 소리는 여기 없다 — 소리는 누르는 그 순간에만 받는다(bell_loading_test).
  PICTURES = { sitting: "elephant_field.webp", maitreya: "mireukdang.webp" }.freeze

  def compound_picture_for(hall)
    PICTURES[hall.key] && image_path(PICTURES[hall.key])
  end
end
