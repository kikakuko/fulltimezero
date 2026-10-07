# This app is a raft. — 이 앱도 뗏목이다.
Rails.application.routes.draw do
  # 호스트는 셋이고 앱은 하나다. www 로 온 발길은 맨 이름으로 넘긴다 —
  # 영구 넘김(301)이라 검색과 브라우저가 한 번만 배운다. app 은 넘기지 않는다.
  match "(*path)", to: redirect(subdomain: "", status: 301), via: :all, constraints: lambda { |request|
    ENV["APP_HOST"].present? && request.host == "www.#{ENV['APP_HOST']}"
  }

  get "up" => "rails/health#show", as: :rails_health_check
  # 홈 화면에 더했을 때의 이름 · 바탕 · 전체 화면. 서비스 워커는 두지 않는다.
  get "manifest.json" => "rails/pwa#manifest", as: :pwa_manifest
  # 검색에 보일 것인가 — 기본은 막음. SEARCHABLE=true 한 줄로 푼다(SearchGate).
  get "robots.txt" => "pages#robots", as: :robots

  # 언어의 목록은 config/application.rb 한 곳에서 온다.
  scope "/:locale", locale: Regexp.union(I18n.available_locales.map(&:to_s)) do
    get "/" => "gate#show", as: :gate

    # 가입 · 로그인 · 비밀번호는 문 뒤에 있다(SignupGate). 닫혀 있으면 길이
    # 없다 — 화면을 숨기는 것으로는 봇을 막지 못한다. 나가기(session#destroy)는
    # 문 밖에 둔다. 잠근 뒤에도 이미 들어온 사람은 나갈 수 있어야 한다.
    constraints(SignupGate) do
      get  "sign_up" => "users#new",    as: :new_user
      post "sign_up" => "users#create", as: :users
      resource  :session, only: %i[new create]
      resources :passwords, only: %i[new create edit update], param: :token
    end
    resource :session, only: :destroy

    # 가입이 닫혀 있는 동안 문 셋의 끝과 로그인이 필요한 자리가 닿는 곳.
    get "not_yet" => "pages#not_yet", as: :not_yet

    get "today" => "today#show", as: :today

    # 처음의 문 셋 — 설명이 아니라 지나는 문이다.
    get   "threshold" => "onboarding#stop", as: :threshold
    get   "threshold/naming" => "onboarding#naming", as: :threshold_naming
    patch "threshold/naming" => "onboarding#name"
    get   "threshold/breath" => "onboarding#breath", as: :threshold_breath
    post  "threshold/passed" => "onboarding#pass", as: :threshold_passed
    resources :rests, only: %i[new create destroy]

    # 달력은 하나다. 「달의 자취」는 「날들」에 들어갔다 — 달력 둘을 둘
    # 이유가 없다. 예전 주소로 오는 발길은 그리로 보낸다.
    get "moon", to: redirect { |path, _request| "/#{path[:locale]}/days" }

    # 앉음 — 명상 타이머와 무위의 시간.
    resources :sittings, only: %i[new create show update destroy]
    post "nothing" => "sittings#nothing", as: :nothing

    # 아홉 자리 — 읽고 고르는 안내. 처음부터 아홉이 다 열려 있다.
    resources :abidings, only: :show, param: :pos

    # 사경 — 하루 한 자. 쌓인 탑은 언제든 볼 수 있다.
    resources :copyings, only: %i[new create]
    get "pagoda" => "pagodas#show", as: :pagoda

    # 절 — 두 벌 가운데 하나를 고르고, 한 배마다 알 하나를 꿴다.
    # 속도는 사람이 정한다. 앱이 세는 길은 없다.
    # 범종각 — 치고 듣는다. 쌓는 것이 없으므로 쓰는 길도 없다.
    get "bells" => "bells#show", as: :bells

    get  "bows" => "bows#show", as: :bows
    get  "bows/:kind" => "bows#bow", as: :bow
    post "beads" => "beads#create", as: :beads

    # 날들 — 빈 일정. 달력의 날짜 숫자만이 이 앱에서 허용되는 숫자다.
    get   "days" => "days#index", as: :days
    get   "days/:date" => "days#show", as: :day
    patch "days/:date" => "days#update"
    resources :plans, only: %i[create destroy]

    # 기록은 사용자의 것이다. 언제든 통째로 들고 나갈 수 있다(제7조).
    get "export" => "exports#show", as: :export

    get   "settings" => "settings#show", as: :settings
    patch "settings" => "settings#update"
    delete "account" => "settings#destroy", as: :account

    # 「쉼의 안내」 — 한 번에 한 장씩. 다음 장으로 미는 고리는 두지 않는다.
    get "guide" => "guide#show", as: :guide
    get "guide/:chapter" => "guide#chapter", as: :guide_chapter

    get "privacy" => "pages#privacy", as: :privacy
    # 쓰인 것들 — 빌려온 것의 출처와 이용조건. 소리 · 글꼴 · 그림이 들어올 때마다 는다.
    get "credits" => "pages#credits", as: :credits
  end

  # 브라우저가 한국어를 선호하면 ko, 그 밖에는 en.
  root to: redirect { |_params, request|
    "/#{request.headers["Accept-Language"].to_s.split(",").first.to_s.start_with?("ko") ? "ko" : "en"}"
  }
end
