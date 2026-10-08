# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = "1.0"

# Add additional assets to the asset load path.
# 종성 음원 자리. 파일이 없으면 재생기가 합성음으로 운다.
Rails.application.config.assets.paths << Rails.root.join("app/assets/sounds")
# 글꼴 자리. 저장소 안에 두고 저장소에서 낸다 — 바깥(글꼴 서비스)을 부르지 않는다(제6조).
Rails.application.config.assets.paths << Rails.root.join("app/assets/fonts")
