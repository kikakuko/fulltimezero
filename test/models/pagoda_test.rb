# This app is a raft. — 이 앱도 뗏목이다.
require "test_helper"

class PagodaTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
    @sutra = heart_sutra
  end

  test "아직 한 자도 쓰지 않았으면 첫 자가 기다린다" do
    pagoda = @user.pagoda

    assert_equal 0, pagoda.last_pos
    assert_equal @sutra.chars.first, pagoda.next_char
    refute pagoda.complete?
  end

  test "경을 다 쓰면 탑이 완성되고 다음 자는 없다" do
    today = @user.today
    rows = @sutra.chars.map.with_index do |char, i|
      { user_id: @user.id, sutra_char_id: char.id, copied_on: today - (@sutra.total - i),
        glyph_paths: nil, created_at: Time.current, updated_at: Time.current }
    end
    Copying.insert_all!(rows)

    pagoda = @user.pagoda
    assert_equal @sutra.total, pagoda.last_pos
    assert pagoda.complete?
    assert_nil pagoda.next_char
  end

  test "남의 사경은 내 탑에 쌓이지 않는다" do
    other = users(:two)
    other.copyings.create!(sutra_char: other.pagoda.next_char, glyph_paths: nil)

    assert_equal 0, @user.pagoda.last_pos
  end
end
