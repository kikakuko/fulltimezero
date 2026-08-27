# This app is a raft. — 이 앱도 뗏목이다.
require "test_helper"

class RestTest < ActiveSupport::TestCase
  # SPIRIT 제3조: 판정 금지. 스키마에 평가성 컬럼을 두지 않는다.
  # 그리고 쉼을 분으로 재지 않는다.
  FORBIDDEN_COLUMNS = %w[
    minutes seconds hours length_in_minutes
    score rating mood quality level grade rank points streak depth
  ].freeze

  ALLOWED_COLUMNS = %w[id user_id rested_on duration texture note created_at updated_at].freeze

  test "쉼에는 평가성 컬럼도, 분 컬럼도 없다" do
    assert_empty Rest.column_names & FORBIDDEN_COLUMNS
    assert_equal ALLOWED_COLUMNS.sort, Rest.column_names.sort
  end

  test "길이는 다섯 가지이고 분으로 환산되지 않는다" do
    assert_equal %w[one_breath a_moment a_while a_long_while time_fell_away], Rest::DURATIONS

    rest = users(:one).rests.create!(duration: "time_fell_away")
    assert_equal "time_fell_away", rest.read_attribute(:duration)
    assert_not rest.respond_to?(:minutes)
  end

  test "쉼의 결은 선택 사항이라 건너뛸 수 있다" do
    rest = users(:one).rests.new(duration: "a_moment", texture: nil)
    assert rest.valid?
  end

  test "빈 문자열로 온 결은 고르지 않은 것으로 둔다" do
    rest = users(:one).rests.create!(duration: "a_moment", texture: "")
    assert_nil rest.texture
  end

  test "길이는 반드시 있어야 하고 목록 밖의 값은 받지 않는다" do
    assert_not users(:one).rests.new(duration: nil).valid?
    assert_not users(:one).rests.new(duration: "forever").valid?
  end

  test "기록한 날은 사용자의 오늘로 찍힌다" do
    travel_to Time.utc(2026, 8, 27, 22, 0) do
      assert_equal Date.new(2026, 8, 28), users(:one).rests.create!(duration: "a_while").rested_on
      assert_equal Date.new(2026, 8, 27), users(:two).rests.create!(duration: "a_while").rested_on
    end
  end
end
