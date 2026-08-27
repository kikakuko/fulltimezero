# This app is a raft. — 이 앱도 뗏목이다.
#
# Minitest 6 에서 minitest/mock 이 빠졌다. 게이트 규칙을 검사하는 데
# 필요한 것은 이것뿐이므로, 젬을 늘리는 대신 여섯 줄을 둔다.
module Stubbing
  def stubbing(object, name, value)
    singleton = object.singleton_class
    own = singleton.method_defined?(name, false) || singleton.private_method_defined?(name, false)
    original = singleton.instance_method(name) if own

    singleton.define_method(name) { |*, **, &_block| value }
    yield
  ensure
    own ? singleton.define_method(name, original) : singleton.remove_method(name)
  end
end

ActiveSupport.on_load(:active_support_test_case) do
  include Stubbing
end
