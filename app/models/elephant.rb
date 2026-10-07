# This app is a raft. — 이 앱도 뗏목이다.
#
# 코끼리 — 선방의 몸. 흰빛과 길 위의 자리가 **지금까지 앉은 시간 하나**에서 나온다.
#
#   w = 1 − exp(−T / 150)      T = 끝난 앉음의 시간을 모두 더한 것(시간 단위)
#
# 절대 규칙:
#   - **줄지 않는다.** 앉은 시간은 쌓이기만 한다. 잊음은 달의 것이고(§2),
#     코끼리는 몸이라 지나간 것을 잃지 않는다(elephant_promise_test 가 지킨다).
#   - **끝에 닿지 않는다.** 백오십 시간에 예순세 푼, 천 시간에도 하나에 못 미친다.
#     몇 해를 앉아도 먹 한 점은 남는다 — 완성이 없다는 뜻이다(§3).
#   - **한 번의 앉음은 눈에 띄지 않을 만큼만 옮긴다.** 희어짐은 앉는 동안이 아니라
#     앉음과 앉음 사이에서 보인다. 그래서 앉는 동안에는 시작할 때의 값으로 멎는다.
#   - **아홉 굽이에 이름이 붙지 않는다.** 굽이는 길의 모양이고, 아홉의 이름과 글은
#     장경각에 있다. 흰빛이 아홉 중 어디인지를 불러 주는 것은 §5 의 단계 매김이다.
#   - 끝난 앉음만 센다. 정함 없이 앉은 것도 실제 앉은 시간으로 센다.
#   - 숫자는 화면에 나가지 않는다. 흰빛은 그림의 밝기로만 보인다.
class Elephant
  # 한 시간을 세는 자. 백오십 시간에 예순세 푼까지 온다 — 느리게 오래 간다.
  SOAK_HOURS = 150.0

  # 길의 틀과 굽이 아홉 — 배경 그림(elephant_field.webp) 속 흰 길의 굽이마다
  # 한 점. 그리는 쪽(elephant_controller.js)과 같은 값이어야 한다
  # (elephant_flow_test 가 지킨다). 길의 모양일 뿐 이름이 붙지 않는다.
  VIEW = [ 864, 1184 ].freeze
  ANCHORS = [
    [ 555, 1085 ], [ 175, 905 ], [ 660, 770 ], [ 300, 640 ], [ 640, 555 ],
    [ 325, 470 ], [ 575, 395 ], [ 355, 320 ], [ 464, 150 ]
  ].freeze

  Reading = Data.define(:whiteness, :yesterday) do
    def moved? = whiteness != yesterday
  end

  def self.for(user, today: nil)
    today ||= user.today

    Reading.new(whiteness: whiteness(user), yesterday: whiteness(user, ending: today - 1))
  end

  # 앉은 시간이 쌓일수록 희어진다. 쌓이기만 하므로 내려가는 길이 없다.
  def self.whiteness(user, ending: nil)
    1 - Math.exp(-hours(user, ending: ending) / SOAK_HOURS)
  end

  # 끝난 앉음의 시간을 모두 더한다(시간 단위). 무위는 세지 않는다 —
  # 무위는 형상이 풀리는 자리이지 몸이 쌓이는 자리가 아니다.
  def self.hours(user, ending: nil)
    sat = user.sittings.where(mode: "sitting").where.not(ended_at: nil)
    sat = sat.where(sat_on: ..ending) if ending

    sat.sum("strftime('%s', ended_at) - strftime('%s', created_at)").to_f / 3600
  end
end
