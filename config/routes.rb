# This app is a raft. — 이 앱도 뗏목이다.
Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  scope "/:locale", locale: /ko|en/ do
    get "/" => "gate#show", as: :gate

    get  "sign_up" => "users#new",    as: :new_user
    post "sign_up" => "users#create", as: :users
    resource  :session, only: %i[new create destroy]
    resources :passwords, only: %i[new create edit update], param: :token

    get "today" => "today#show", as: :today
    resources :rests, only: %i[new create]
    get "moon" => "moon#show", as: :moon

    # 앉음 — 명상 타이머와 무위의 시간.
    resources :sittings, only: %i[new create show update]
    post "nothing" => "sittings#nothing", as: :nothing

    get   "settings" => "settings#show", as: :settings
    patch "settings" => "settings#update"
    delete "account" => "settings#destroy", as: :account

    # M3 「쉼의 안내」 — 지금은 스텁.
    get "guide" => "guide#show", as: :guide

    get "privacy" => "pages#privacy", as: :privacy
  end

  # 브라우저가 한국어를 선호하면 ko, 그 밖에는 en.
  root to: redirect { |_params, request|
    "/#{request.headers["Accept-Language"].to_s.split(",").first.to_s.start_with?("ko") ? "ko" : "en"}"
  }
end
