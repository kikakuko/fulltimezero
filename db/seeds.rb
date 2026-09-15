# This app is a raft. — 이 앱도 뗏목이다.
#
# 경전은 앱의 것이라 어느 환경에나 심는다. 값은 파일에서만 온다.
Sutra.seed_from(Sutra::HEART_FILE)

# 개발용 씨앗. 달이 차오른 모습을 눈으로 보기 위한 것뿐이다.
if Rails.env.development?
  user = User.find_or_create_by!(email_address: "rest@example.com") do |u|
    u.password = "a good long password"
    u.locale = "ko"
    u.time_zone = "Asia/Seoul"
  end

  user.rests.destroy_all
  [ 0, 1, 3, 4, 6, 9, 10, 13, 14, 15, 19, 21, 22, 26 ].each do |days_ago|
    user.rests.create!(
      rested_on: user.today - days_ago,
      duration: Rest::DURATIONS.sample,
      texture: (Rest::TEXTURES + [ nil ]).sample
    )
  end

  puts "rest@example.com / a good long password"
end
