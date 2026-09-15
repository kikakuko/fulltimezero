# This app is a raft. — 이 앱도 뗏목이다.
#
# 처음의 문 셋.
#
# 튜토리얼은 알려주는 것이고 리츄얼은 거치게 하는 것이다. 절의 일주문이
# 절의 기능을 설명하지 않지만, 지나고 나면 마음이 이미 달라져 있다.
# 그래서 여기에는 기능 소개도, 「이렇게 쓰세요」도 없다.
#
#   첫째 문 — 멈춤.        기다려야 길이 나타난다. 말로 하지 않는다.
#   둘째 문 — 이름 붙이기.  무엇에서 쉬려 하는지 한 줄. 비워도 된다.
#   셋째 문 — 몸으로 하는 일. 손을 얹고 숨 세 번. 그러면 그냥 열린다.
#
# 어느 문에서든 「나중에」로 지나갈 수 있다. 붙잡지 않는다(제7조).
class OnboardingController < ApplicationController
  def stop
  end

  def naming
  end

  # 받아 두기만 한다. 분석하지도, 추천에 쓰지도 않는다.
  def name
    Current.user.update(resting_from: params.dig(:user, :resting_from).to_s)

    redirect_to threshold_breath_path
  end

  def breath
  end

  # 셋째 문이 열렸거나 「나중에」를 눌렀다. 다시 지나도 처음 지난 날은 그대로다.
  def pass
    Current.user.update!(onboarded_at: Time.current) unless Current.user.onboarded?

    redirect_to today_path
  end
end
