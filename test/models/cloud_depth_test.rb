# This app is a raft. — 이 앱도 뗏목이다.
#
# 공기원근법 — 먼 것은 옅고 느리다. 값은 결이지만(cloud_form_test), 셋 사이의
# 차례는 성질이므로 기능이다. 값을 손보다가 차례가 뒤집히면 깊이가 사라진다.
require "test_helper"

class CloudDepthTest < ActiveSupport::TestCase
  CSS = Rails.root.join("app/assets/tailwind/application.css")

  test "먼 것일수록 옅다" do
    far, mid, near = depths

    assert_operator far, :<, mid, "먼 구름이 중간 구름보다 짙다"
    assert_operator mid, :<, near, "중간 구름이 가까운 구름보다 짙다"
  end

  test "먼 것일수록 느리다" do
    far, mid, near = spans

    assert_operator far, :>, mid, "먼 구름이 중간 구름보다 빠르다"
    assert_operator mid, :>, near, "중간 구름이 가까운 구름보다 빠르다"
  end

  # 배경이 도상처럼 또렷해지면 눈이 거기로 간다. 가장 가까운 구름도 반투명이다.
  test "가장 가까운 구름도 제 몸을 다 드러내지 않는다" do
    assert_operator depths.max, :<, 1.0, "구름이 불투명해졌다"
  end

  private
    def root = @root ||= CSS.read[/:root \{.*?\n\}/m].to_s
    def depths = %w[far mid near].map { |depth| root[/--cloud-#{depth}: ([\d.]+);/, 1].to_f }
    def spans = %w[far mid near].map { |depth| root[/--cloud-span-#{depth}: (\d+)s;/, 1].to_i }
end
