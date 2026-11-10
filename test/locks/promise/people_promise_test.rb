# This app is a raft. — 이 앱도 뗏목이다.
#
# 사람과 사람(SPIRIT 제5조 · 제5조의2 · 제4조 주석 · §3 · §4, 2026-11-10 개정). 약속 자물쇠다 — 사람을 들이는 자리는 대적광전(서로 말을
# 나누지 않음)과 다실(초대한 사람과 법담) 둘뿐이고, 그 둘에서도 하지 않을 것을 여기서 먼저 잠근다. 기능은 아직 없다 — 대적광전 · 다실을
# 만들 때(NEXT 18 · 19) 이 자물쇠는 그대로 지나야 한다. 다실의 표를 들이는 날에는 아래 「남는 표」 검사를 그 표의 지우는 길과 함께
# 고친다 — 약속을 푸는 것이므로 먼저 묻는다.
#
# 낱말 「초대」 자체는 comparing_test 가 아직 막는다(초대 기능이 없으므로). 다실을 만드는 날 그 자물쇠를 함께 묻고 고친다.
require "test_helper"

class PeoplePromiseTest < ActionDispatch::IntegrationTest
  # 사람을 모아 보이는 길 — 목록 · 찾기 · 추천 · 친구 · 팔로우 · 연락처.
  GATHERING = /\b(?:friends?|follow(?:ers?|ing)?|contacts?|directory|discover|people|members?|lobby|rooms?|suggestions?|recommend\w*)\b/i

  # 제5조의2 · §3 — 공개된 방도, 둘러볼 목록도, 친구 목록 · 팔로우 · 연락처 불러오기 · 사람 찾기 · 추천도 없다.
  test "사람을 모아 보이는 길이 없다 — 목록 · 찾기 · 친구 · 팔로우 · 연락처" do
    paths = Rails.application.routes.routes.map { |route| route.path.spec.to_s }
    assert_empty paths.grep(GATHERING), "사람을 모아 보이는 길이 있다"
    models = Rails.root.glob("app/models/**/*.rb").map { |path| path.basename(".rb").to_s }
    assert_empty models.grep(/\A(?:friend|friendship|follow|contact|member|lobby)s?\z/), "친구 · 팔로우 · 연락처를 담는 모델이 있다"
  end

  # 제5조의2 — 사람 수를 보여 주지 않는다. 몇 사람이 앉았는지, 들어와 있는지를 숫자로도 낱말로도 세지 않는다.
  test "사람 수를 보여 주지 않는다" do
    copy = Rails.root.glob("config/locales/*.yml").map(&:read).join("\n") +
           Rails.root.glob("app/views/**/*.erb").map(&:read).join("\n")
    assert_no_match(/명이\s*(?:함께|앉|들어|보|읽)|사람이\s*(?:함께\s*)?(?:앉아|있다)|접속\s*중|\b(?:people|others|users)\s+(?:are\s+)?(?:here|sitting|online|reading)\b|\bonline now\b/i,
                    copy, "사람 수나 사람이 있다는 것을 세어 보인다")
  end

  # §4 — 최소 수집은 이용자 자신의 이메일뿐. 남의 이메일을 쥐는 칸이 없다(초대의 주소는 보내고 나면 지운다). 다실의 말을 남기는 표가 없다.
  test "남의 이메일과 지난 말을 쥐는 표가 없다" do
    schema = Rails.root.join("db/schema.rb").read
    tables = schema.scan(/create_table "(\w+)"/).flatten
    email_columns = schema.scan(/create_table "(\w+)".*?\n  end/m).flat_map do |(table)|
      block = schema[/create_table "#{table}".*?\n  end/m]
      block.scan(/t\.\w+ "(\w*email\w*)"/).flatten.map { |column| "#{table}.#{column}" }
    end
    assert_equal [ "users.email_address" ], email_columns, "이용자 자신의 이메일 밖에 이메일 칸이 있다"
    assert_empty tables.grep(/messages?|chats?|conversations?|threads?|invitations?|invitees?/),
      "다실의 말 · 초대를 담는 표가 생겼다 — 닫히면 지우는 길과 이 자물쇠를 함께 고친다(먼저 묻는다)"
  end

  # 제4조 주석 — 초대 편지도 게이트를 지난다(밤에 보낸 초대는 아침에). 초대를 보내는 메일러가 생기면 SilenceGate 를 거쳐야 한다.
  test "초대 편지는 침묵 게이트를 지난다" do
    Rails.root.glob("app/{mailers,models,controllers,jobs}/**/*.rb").select { |path| path.read.match?(/invit/i) }.each do |path|
      assert_match(/SilenceGate\.deliver/, path.read, "#{path.relative_path_from(Rails.root)} 이 초대를 침묵 게이트 밖으로 보낸다")
    end
  end

  # §4 — 염불은 했다는 한 줄만, 횟수는 없다. 다실을 열었다는 것은 남지 않는다. 지금은 염불 · 다실의 표가 없다 — 생기면 이것이 먼저 선다.
  test "염불의 횟수와 다실을 연 기록을 남기는 칸이 없다" do
    schema = Rails.root.join("db/schema.rb").read
    assert_no_match(/t\.\w+ "(?:recitations?|chants?|nianfo|yeombul)_?(?:count|times|total)/i, schema, "염불의 횟수를 센다")
    assert_no_match(/create_table "(?:dasils?|tea_rooms?|dasil_\w+)"/, schema, "다실을 연 기록을 남기는 표가 있다")
  end

  # 제5조의2 — 열네 살 이상만 사람을 만난다. 약관이 그것을 적고 있다.
  test "열네 살이 되지 않은 사람은 가입하지 않는다고 약관이 적는다" do
    assert_match(/열네 살이 되지 않은 사람은 가입할 수 없다/, Rails.root.join("docs/legal/terms.md").read)
  end
end
