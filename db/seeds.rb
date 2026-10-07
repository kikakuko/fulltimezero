# This app is a raft. — 이 앱도 뗏목이다.
#
# 경전은 앱의 것이라 어느 환경에나 심는다. 값은 파일에서만 온다.
Sutra.seed_from(Sutra::HEART_FILE)
# 아홉 자리도 앱의 것이다.
Abiding.seed_from

# 구경하는 자리의 씨앗 — 가입이 닫혀 있는 동안 손님 모두가 이것을 함께 본다.
# 빈 화면이 아니라 살아 있던 자리여야 한다: 달이 차 있고, 탑에 글자가 쌓여 있고,
# 코끼리가 길을 오르고, 미륵이 조금 드러나 있다. 몇 번을 돌려도 같은 결과가 된다.
#
# 아무도 이 계정으로 들어오지 못한다 — 가입과 로그인의 길이 닫혀 있고, 비밀번호는
# 아무도 모르는 값이다. 손님에게는 이메일을 묻지 않는다(Guest).
guest = User.find_or_create_by!(email_address: Guest::SEED) do |user|
  user.password = SecureRandom.hex(32)
  user.locale = "ko"
  user.time_zone = "Asia/Seoul"
end
guest.update!(onboarded_at: 60.days.ago, what_moves: nil, daily_door: false)
guest.rests.destroy_all
guest.sittings.destroy_all
guest.clearings.destroy_all
guest.copyings.destroy_all
guest.plans.destroy_all

guest_today = guest.today
guest_abidings = Abiding.in_order.to_a

# 쉰 날 — 최근 스물여드레에 흩어서. 코끼리가 길의 중간쯤에 선다.
[ 2, 5, 9, 14, 18, 23, 27, 34, 41, 52 ].each do |days_ago|
  guest.rests.create!(rested_on: guest_today - days_ago,
                      duration: Rest::DURATIONS[days_ago % Rest::DURATIONS.size],
                      texture: Rest::TEXTURES[days_ago % Rest::TEXTURES.size])
end

# 앉음 — 둘은 자리를 골랐다.
[ [ 3, guest_abidings[2] ], [ 11, nil ], [ 20, guest_abidings[5] ], [ 38, nil ] ].each do |days_ago, abiding|
  at = (guest_today - days_ago).in_time_zone(guest.time_zone).change(hour: 7)
  guest.sittings.create!(mode: "sitting", sat_on: guest_today - days_ago, abiding: abiding,
                         created_at: at, ended_at: at + 20.minutes)
end

# 비운 날 셋 — 미륵이 조금 드러난다.
[ 7, 21, 44 ].each { |days_ago| guest.clearings.create!(cleared_on: guest_today - days_ago) }

# 사경 스물넉 자 — 첫 층이 아직 차지 않았다.
guest_strokes = [ [ [ 0.24, 0.32 ], [ 0.52, 0.36 ], [ 0.76, 0.34 ] ], [ [ 0.5, 0.16 ], [ 0.49, 0.52 ], [ 0.5, 0.84 ] ] ]
Sutra.heart.chars.order(:pos).first(24).each_with_index do |char, index|
  guest.copyings.create!(sutra_char: char, copied_on: guest_today - (60 - index * 2), glyph_paths: guest_strokes)
end

# 개발용 씨앗 — 눈으로 보기 위한 계정 둘. 개발 DB 에만 심는다.
#
#   gate@fulltimezero.test / fulltimezero   문을 아직 지나지 않은 계정. 온보딩부터.
#   look@fulltimezero.test / fulltimezero   지난 두 달을 산 계정 — 쉰 날 열둘,
#                                           비운 날 다섯, 앉음 여덟(자리 고른 것
#                                           셋), 사경 예순네 자. 코끼리는 길 중간,
#                                           미륵은 눈까지, 탑은 첫 층에 여섯 자 남음.
#
# 몇 번을 돌려도 같은 결과가 된다 — 지우고 다시 심는다.
if Rails.env.development?
  password = "fulltimezero"

  gate = User.find_or_create_by!(email_address: "gate@fulltimezero.test") do |u|
    u.password = password
    u.locale = "ko"
    u.time_zone = "Asia/Seoul"
  end
  gate.update!(onboarded_at: nil, what_moves: nil)
  gate.rests.destroy_all
  gate.sittings.destroy_all
  gate.clearings.destroy_all
  gate.copyings.destroy_all
  gate.plans.destroy_all

  look = User.find_or_create_by!(email_address: "look@fulltimezero.test") do |u|
    u.password = password
    u.locale = "ko"
    u.time_zone = "Asia/Seoul"
  end
  look.update!(onboarded_at: 70.days.ago, what_moves: "끝나지 않는 생각")
  look.rests.destroy_all
  look.sittings.destroy_all
  look.clearings.destroy_all
  look.copyings.destroy_all
  look.plans.destroy_all

  today = look.today
  abidings = Abiding.in_order.to_a

  # 쉰 날 열둘 — 지난 두 달에 흩어서. 최근 스물여드레에 무엇이든 있었던 날이
  # 열둘쯤이면 코끼리가 길 중간이다.
  [ 1, 6, 13, 22, 31, 35, 38, 43, 46, 50, 55, 59 ].each do |days_ago|
    look.rests.create!(rested_on: today - days_ago, duration: Rest::DURATIONS.sample, texture: (Rest::TEXTURES + [ nil ]).sample)
  end

  # 앉음 여덟 — 셋은 자리를 골랐다.
  [ [ 2, abidings[3] ], [ 12, nil ], [ 19, abidings[0] ], [ 29, abidings[3] ], [ 36, nil ], [ 44, nil ], [ 52, nil ], [ 57, nil ] ].each do |days_ago, abiding|
    at = (today - days_ago).in_time_zone(look.time_zone).change(hour: 7)
    look.sittings.create!(mode: days_ago == 12 ? "nothing" : "sitting", sat_on: today - days_ago, abiding: abiding,
                          created_at: at, ended_at: at + 20.minutes)
  end

  # 비운 날 다섯 — 미륵이 눈까지 올라온다.
  [ 4, 11, 33, 47, 58 ].each { |days_ago| look.clearings.create!(cleared_on: today - days_ago) }

  # 사경 예순네 자 — 첫 층(일흔 칸)에 여섯 자가 남은 상태. 하루 한 자씩, 지난 석 달에
  # 흩어서. 획은 눈으로 보기 위한 것이다.
  strokes = [ [ [ 0.22, 0.34 ], [ 0.5, 0.38 ], [ 0.78, 0.36 ] ], [ [ 0.5, 0.14 ], [ 0.48, 0.5 ], [ 0.5, 0.86 ] ], [ [ 0.3, 0.64 ], [ 0.7, 0.66 ] ] ]
  # 최근 스물여드레에는 셋만 — 나머지는 그 전에. 그래야 코끼리가 길 중간에 선다.
  days = ((29..89).to_a + [ 7, 17, 25 ]).sort.reverse
  Sutra.heart.chars.order(:pos).first(64).zip(days).each do |char, days_ago|
    look.copyings.create!(sutra_char: char, copied_on: today - days_ago, glyph_paths: strokes)
  end

  # 오늘 일정 하나 — 저녁의 한마디가 보이게.
  look.plans.create!(planned_on: today, what: "회의")

  puts "gate@fulltimezero.test / #{password}  — 문 앞"
  puts "look@fulltimezero.test / #{password}  — 두 달을 산 계정"
end
