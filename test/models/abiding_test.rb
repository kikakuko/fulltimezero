# This app is a raft. — 이 앱도 뗏목이다.
#
# 아홉 자리가 도는가 — 파일에서 아홉이 들어오고, 다시 심어도 같은 아홉이다.
require "test_helper"
require_relative "../test_helpers/copy_locks"

class AbidingTest < ActiveSupport::TestCase
  setup { @abidings = nine_abidings }


  test "자리는 아홉이고, 처음부터 다 열려 있다" do
    assert_equal Abiding::COUNT, @abidings.size
    assert_equal (1..9).to_a, @abidings.map(&:pos)
    assert_no_match(/locked|open_at|unlock|required|reached/, Abiding.column_names.join(" "), "잠기는 자리가 있다")
  end

  # 값은 파일에서만 온다. 몇 번을 심어도 같은 아홉이다.
  test "몇 번을 심어도 같은 아홉이다" do
    Abiding.seed_from
    Abiding.seed_from

    assert_equal Abiding::COUNT, Abiding.count
  end

  test "모르는 칸이 파일에 생기면 시드가 터진다" do
    path = Rails.root.join("tmp/abidings_with_stranger.yml")
    data = YAML.load_file(Abiding::FILE)
    data["stages"].first["score"] = 1
    path.write(data.to_yaml)

    assert_raises(ActiveModel::UnknownAttributeError) { Abiding.seed_from(path) }
  ensure
    path.delete if path.exist?
  end
end
