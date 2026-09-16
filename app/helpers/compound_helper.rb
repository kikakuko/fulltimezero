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
    when :courtyard then "#clearing"
    when :gate then threshold_path
    end
  end
end
