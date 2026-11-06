// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
// 선방의 걸음 사이 뒤로 가기를 Turbo 보다 먼저 받는다 — 반드시 Turbo 앞에(controllers/seonbang_history.js).
import "controllers/seonbang_history"
import "@hotwired/turbo-rails"
import "controllers"
