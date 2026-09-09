# This app is a raft. — 이 앱도 뗏목이다.
#
# 기록을 통째로 돌려준다. 묻지 않고, 붙잡지 않고, 한 번에.
class ExportsController < ApplicationController
  def show
    export = Export.new(Current.user)

    case params[:format]
    when "json"
      send_data export.json, filename: export.filename("json"), type: "application/json"
    else
      send_data export.markdown, filename: export.filename("md"), type: "text/markdown"
    end
  end
end
