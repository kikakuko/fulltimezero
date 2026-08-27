# This app is a raft. — 이 앱도 뗏목이다.
#
# 종성은 파일이 먼저다. app/assets/sounds/ 에 bell-start · bell-end 가
# 있으면 그것으로 울고, 없으면 재생기가 합성음으로 운다.
# 훗날 CC0 실음원이나 직접 녹음한 종을 같은 이름으로 넣기만 하면
# 코드를 고치지 않고 갈아 끼워진다. 라이선스는 docs/SOURCES.md 에 적는다.
module BellHelper
  SOUNDS = Rails.root.join("app/assets/sounds")
  EXTENSIONS = %w[ogg mp3 wav m4a].freeze

  def bell_source(which)
    file = bell_file(which)

    asset_path(file) if file
  end

  # 파일이 없으면 nil 이고, 재생기는 그때 합성음으로 운다.
  def bell_file(which, dir: SOUNDS)
    EXTENSIONS.each do |extension|
      file = "bell-#{which}.#{extension}"
      return file if dir.join(file).exist?
    end

    nil
  end
end
