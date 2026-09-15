# This app is a raft. — 이 앱도 뗏목이다.
require "test_helper"

class CopyingTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
    @sutra = heart_sutra
  end

  # 글씨를 채점할 칸이 뒷문으로 들어오지 못하게 목록을 못박는다(제3조).
  test "사경에는 쓴 자와 획과 날짜뿐이다" do
    assert_equal %w[copied_on created_at glyph_paths id sutra_char_id updated_at user_id],
      Copying.column_names.sort
  end

  test "하루에 한 자" do
    write
    second = @user.copyings.new(sutra_char: @user.pagoda.next_char, glyph_paths: [])

    refute second.valid?
    assert_includes second.errors.details[:copied_on], { error: :taken, value: @user.today }
  end

  test "다음 날에는 다음 자가 기다린다" do
    write

    travel 1.day do
      assert_equal 2, @user.pagoda.next_char.pos
      assert write.persisted?
    end
  end

  test "경은 차례로 쓴다 — 건너뛰지도 앞질러 가지도 않는다" do
    ahead = @user.copyings.new(sutra_char: @sutra.chars.find_by!(pos: 3))

    refute ahead.valid?
    assert ahead.errors.of_kind?(:sutra_char, :out_of_turn)
  end

  test "종이에 쓴 자도 똑같이 탑을 쌓는다" do
    copying = write(glyph_paths: nil)

    assert copying.on_paper?
    assert_equal 1, @user.pagoda.last_pos
  end

  test "화면에 그은 획은 그어진 그대로 남는다" do
    strokes = [ [ [ 0.1, 0.2 ], [ 0.4, 0.5 ] ], [ [ 0.6, 0.1 ], [ 0.6, 0.9 ] ] ]

    assert_equal strokes, write(glyph_paths: strokes).reload.glyph_paths
  end

  test "한 획도 없는 목록은 화면에 쓴 것이 아니다" do
    copying = @user.copyings.new(sutra_char: @user.pagoda.next_char, glyph_paths: [])

    refute copying.valid?
  end

  test "획이 획의 목록이 아니면 받지 않는다 — 잘 썼는지는 보지 않는다" do
    copying = @user.copyings.new(sutra_char: @user.pagoda.next_char, glyph_paths: { "score" => 1 })

    refute copying.valid?
    assert copying.errors.of_kind?(:glyph_paths, :invalid)
  end

  # 간격이 벌어져도 아무 일도 일어나지 않는다. 탑은 무너지지 않는다(§3).
  test "한 해를 쉬었다 와도 탑은 그 높이 그대로다" do
    write
    travel(1.day) { write }
    travel(2.days) { write }

    travel 400.days do
      assert_equal 3, @user.pagoda.last_pos, "쉬는 동안 탑이 낮아졌다"
      assert_equal 4, @user.pagoda.next_char.pos, "쉬는 동안 다음 자가 바뀌었다"
      assert write.persisted?, "오래 쉬고 온 사람이 이어 쓰지 못한다"
    end
  end

  test "탑을 낮추거나 되돌리는 코드가 앱에 없다" do
    lowering = /\bcopyings?\b[^\n]*\.(?:destroy|delete|update_all|update_column)|\bCopying\.(?:destroy|delete|update_all)/

    offenders = Rails.root.join("app").glob("**/*.rb").select do |path|
      path.read.gsub(/^\s*#.*$/, "").match?(lowering)
    end

    assert_empty offenders.map { |path| path.relative_path_from(Rails.root).to_s },
      "사경을 지우거나 되돌리는 코드가 들어왔다"
    assert_empty Pagoda.public_instance_methods(false) - %i[user sutra last_pos next_char complete?],
      "탑에 높이를 바꾸는 길이 생겼다"
  end

  test "계정을 지우면 사경도 곧장 함께 사라진다" do
    write

    assert_difference -> { Copying.count }, -1 do
      @user.destroy!
    end
  end

  private
    def write(glyph_paths: [ [ [ 0.5, 0.5 ] ] ])
      @user.copyings.create!(sutra_char: @user.pagoda.next_char, glyph_paths: glyph_paths)
    end
end
