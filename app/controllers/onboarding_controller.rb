# This app is a raft. — 이 앱도 뗏목이다.
#
# 처음의 문 셋.
#
# 튜토리얼은 알려주는 것이고 리츄얼은 거치게 하는 것이다. 절의 일주문이
# 절의 기능을 설명하지 않지만, 지나고 나면 마음이 이미 달라져 있다.
# 그래서 여기에는 기능 소개도, 「이렇게 쓰세요」도 없다.
#
#   첫째 문 — 나는 멈추었다.       명령이 아니라 선언. 읽는 사람이 제게로 옮겨 온다.
#   둘째 문 — 무엇이 움직이는가.   한 줄을 적는다. 비워도 된다. 분석하지 않는다.
#   셋째 문 — 한 번도 움직인 적 없다. 손을 얹고 숨 세 번. 그러면 그냥 열린다.
#
# 『앙굴리말라경』(MN 86)의 「나는 멈추었다」 — 걸으면서도 멈춘 것은 폭력을
# 영원히 내려놓았기 때문이다. 여기에 『육조단경』의 바람과 깃발 — 움직이는
# 것은 마음이다 — 을 겹친다. 쉼은 새로 얻는 것이 아니라 한 번도 움직인 적
# 없는 자리로 돌아오는 것이다. 그래서 그림은 움직이지 않고 장막만 걷힌다.
#
# 어느 문에서든 「나중에」로 지나갈 수 있다. 붙잡지 않는다(제7조).
#
# 문은 가입보다 먼저다. 처음 온 사람은 계정 없이 문 셋을 지나고, 셋째 문
# 뒤에 가입한다. 둘째 문의 답은 그동안 세션이 들고 있다가 가입 뒤 계정에
# 옮긴다. 가입 없이 나가면 버린다.
class OnboardingController < ApplicationController
  allow_unauthenticated_access

  def stop
  end

  def naming
    @what_moves = Current.user&.what_moves || session[:what_moves]
  end

  # 받아 두기만 한다. 분석하지도, 추천에 쓰지도 않는다.
  def name
    line = params.dig(:user, :what_moves).to_s

    if authenticated?
      Current.user.update(what_moves: line)
    else
      session[:what_moves] = line.strip.first(User::WHAT_MOVES_MOST).presence
    end

    redirect_to threshold_breath_path
  end

  def breath
  end

  # 셋째 문이 열렸거나 「나중에」를 눌렀다. 다시 지나도 처음 지난 날은 그대로다.
  # 계정이 없으면 이제 가입이다 — 문을 지났다는 것을 세션이 기억한다.
  def pass
    if authenticated?
      Current.user.update!(onboarded_at: Time.current) unless Current.user.onboarded?
      redirect_to today_path
    else
      session[:threshold_passed] = true
      redirect_to new_user_path
    end
  end
end
