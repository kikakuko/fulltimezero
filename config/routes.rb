# This app is a raft. — 이 앱도 뗏목이다.
Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  # 언어의 목록은 config/application.rb 한 곳에서 온다.
  scope "/:locale", locale: Regexp.union(I18n.available_locales.map(&:to_s)) do
    get "/" => "gate#show", as: :gate

    get  "sign_up" => "users#new",    as: :new_user
    post "sign_up" => "users#create", as: :users
    resource  :session, only: %i[new create destroy]
    resources :passwords, only: %i[new create edit update], param: :token

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
  end

  # 브라우저가 한국어를 선호하면 ko, 그 밖에는 en.
  root to: redirect { |_params, request|
    "/#{request.headers["Accept-Language"].to_s.split(",").first.to_s.start_with?("ko") ? "ko" : "en"}"
  }
end
