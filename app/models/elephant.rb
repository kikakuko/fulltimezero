# This app is a raft. — 이 앱도 뗏목이다.
#
# 코끼리 — 앉은 흔적. 오늘을 포함한 스물여드레 가운데 무엇이든 있었던 날
# (쉼 · 앉음 · 비움 · 사경)의 비율이 흰빛이다. 검은 코끼리가 희어진다.
#
# 절대 규칙:
#   - 아홉 자리와 잇지 않는다. 코끼리는 흔적이고 아홉 자리는 안내다.
#     코끼리의 자리를 골라 둔 자리로 옮기거나, 골라 둔 자리를 코끼리의
#     자리로 바꾸는 코드는 없다(elephant_test 가 지킨다).
#   - 리셋이 없다. 쉬지 않으면 창이 흘러가며 서서히 내려갈 뿐이다.
#     그것은 「무너짐」이 아니라 「잊음」이다(SPIRIT §3).
#   - 숫자는 화면에 나가지 않는다. 흰빛은 그림의 밝기로만 보인다.
class Elephant
  WINDOW_DAYS = 28

  # 길 위의 정거장 아홉 — 지명이지 경지가 아니다.
  STATIONS = 9

  # 길의 틀과 앵커 — 배경 그림(elephant_field.png) 속 흰 길의 굽이마다
  # 한 점. 그리는 쪽(elephant_controller.js)과 같은 값이어야 한다
  # (elephant_flow_test 가 지킨다). 정거장의 이름이 이 위에 선다.
  VIEW = [ 864, 1184 ].freeze
  ANCHORS = [
    [ 555, 1085 ], [ 175, 905 ], [ 660, 770 ], [ 300, 640 ], [ 640, 555 ],
    [ 325, 470 ], [ 575, 395 ], [ 355, 320 ], [ 450, 120 ]
  ].freeze

  Reading = Data.define(:whiteness, :yesterday) do
    # 지금 지나는 정거장 — 길을 아홉으로 나눠 가장 가까운 곳. 0 부터 8.
    def station = (whiteness * (STATIONS - 1)).round

    def moved? = whiteness != yesterday
  end

  def self.for(user, today: nil)
    today ||= user.today

    Reading.new(whiteness: whiteness(user, ending: today), yesterday: whiteness(user, ending: today - 1))
  end

  # 창 안에서 무엇이든 있었던 날의 비율. 하루에 여럿이어도 하루다.
  def self.whiteness(user, ending:)
    span = (ending - (WINDOW_DAYS - 1))..ending
    days = user.rests.where(rested_on: span).pluck(:rested_on) +
           user.sittings.where(sat_on: span).pluck(:sat_on) +
           user.clearings.where(cleared_on: span).pluck(:cleared_on) +
           user.copyings.where(copied_on: span).pluck(:copied_on)

    days.uniq.size / WINDOW_DAYS.to_f
  end
end
