# This app is a raft. — 이 앱도 뗏목이다.
#
# 코끼리 — 선방의 몸. 길가 바위에 앉아 있다. 흰빛과 고요가 **지금까지 앉은 시간
# 하나**에서 나온다.
#
#   w = 1 − exp(−T / 150)      T = 끝난 앉음의 시간을 모두 더한 것(시간 단위)
#   r = max(1 − w, 바닥)        r 은 뒤척임. 처음엔 크고 앉은 만큼 잦아든다.
#
# 절대 규칙:
#   - **걷지 않는다.** 코끼리의 자리는 어떤 값에도 매이지 않는다 — 바위 하나다.
#     들어설 때 가장자리에서 바위까지 걸어오는 것은 자리의 변화가 아니라 문턱이다.
#   - **줄지 않는다.** 앉은 시간은 쌓이기만 한다. 잊음은 달의 것이고(§2),
#     코끼리는 몸이라 지나간 것을 잃지 않는다(elephant_promise_test 가 지킨다).
#   - **끝에 닿지 않는다.** 백오십 시간에 예순세 푼, 천 시간에도 하나에 못 미친다.
#     몇 해를 앉아도 먹 한 점은 남고, 뒤척임 한 점은 남는다 — 완성이 없다는 뜻이다(§3).
#   - **희어질수록 길은 옅어진다.** 걸은 적이 없다는 것을 그림이 말한다.
#   - **한 번의 앉음은 눈에 띄지 않을 만큼만 옮긴다.** 고요해짐은 앉는 동안이 아니라
#     앉음과 앉음 사이에서 보인다. 그래서 앉는 동안에는 시작할 때의 값으로 멎는다.
#   - **아홉 굽이에 이름이 붙지 않는다.** 굽이는 길의 모양이고, 아홉의 이름과 글은
#     장경각에 있다.
#   - 끝난 앉음만 센다. 정함 없이 앉은 것도 실제 앉은 시간으로 센다.
#   - 숫자는 화면에 나가지 않는다. 흰빛은 그림의 밝기로, 뒤척임은 흔들림의 폭으로만 보인다.
class Elephant
  # 한 시간을 세는 자. 백오십 시간에 예순세 푼까지 온다 — 느리게 오래 간다.
  SOAK_HOURS = 150.0
  # 뒤척임의 바닥. 아무리 앉아도 이만큼은 남는다 — 멎은 몸은 몸이 아니다.
  RESTLESS_LEAST = 0.03

  # 길의 틀과 굽이 아홉 — 배경 그림(elephant_field.webp) 속 흰 길의 굽이마다
  # 한 점. 그리는 쪽(elephant_controller.js)과 같은 값이어야 한다
  # (elephant_flow_test 가 지킨다). 길의 모양일 뿐이다 — 코끼리는 이 위를 가지
  # 않고, 희어질수록 이 길을 한지빛으로 덮는 데에만 쓴다. 이름이 붙지 않는다.
  VIEW = [ 864, 1184 ].freeze
  ANCHORS = [
    [ 555, 1085 ], [ 175, 905 ], [ 660, 770 ], [ 300, 640 ], [ 640, 555 ],
    [ 325, 470 ], [ 575, 395 ], [ 355, 320 ], [ 464, 150 ]
  ].freeze

  Reading = Data.define(:whiteness, :restlessness)

  def self.for(user)
    w = whiteness(user)

    Reading.new(whiteness: w, restlessness: restlessness(w))
  end

  # 뒤척임 — 흰빛의 반대. 바닥 아래로 내려가지 않는다.
  def self.restlessness(whiteness) = [ 1 - whiteness, RESTLESS_LEAST ].max

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
