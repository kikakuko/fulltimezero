# 배포

> This app is a raft. — 이 앱도 뗏목이다.

Kamal 로 한 대의 서버에 올린다(`config/deploy.yml`). 데이터베이스는 SQLite 이고 서버의
볼륨에 산다. 이 문서를 위에서 아래로 따라 하면 배포가 된다.

**비밀값은 이 문서에 적지 않는다.** 무엇이 필요한지만 적는다. 값은 `.kamal/secrets`(추적하지
않는다)와 서버의 환경변수로 들어간다.

## 1. 내가 정해서 넣어야 하는 값

| 이름 | 무엇 | 어디에 |
|---|---|---|
| `<도메인>` | 산 도메인. 예 `fulltimezero.app` | `APP_HOST` |
| `<서버IP>` | 서버의 공인 IP | `DEPLOY_SERVER_IP` |
| `<이미지저장소>` | 컨테이너 이미지를 둘 곳. 기본 `ghcr.io` | `REGISTRY_SERVER` |
| `<저장소계정>` | 그 저장소의 계정(깃허브면 `kikakuko`) | `REGISTRY_USER` |
| `<저장소토큰>` | 그 저장소에 올릴 권한의 토큰 | `.kamal/secrets` 의 `KAMAL_REGISTRY_PASSWORD` |
| `<보내는주소>` | 재설정 편지의 보내는 이. 예 `no-reply@<도메인>` | `MAIL_FROM` |
| `<메일서버>` | 메일 회사가 알려 준 SMTP 주소 | `SMTP_ADDRESS` (`SMTP_PORT` 기본 587) |
| `<메일계정>` `<메일비밀번호>` | 메일 회사가 준 것 | `.kamal/secrets` 의 `SMTP_USER_NAME` · `SMTP_PASSWORD` |
| `<백업보낼곳>` | 백업을 둘 바깥 저장소(rclone 의 이름) | 서버의 `BACKUP_REMOTE` |

환경변수는 배포하는 맥의 셸에 둔다. 예(비밀값은 여기 두지 않는다):

```
export APP_HOST=<도메인>
export DEPLOY_SERVER_IP=<서버IP>
export REGISTRY_SERVER=ghcr.io
export REGISTRY_USER=<저장소계정>
export MAIL_FROM=no-reply@<도메인>
export SMTP_ADDRESS=<메일서버>
```

## 2. 도메인을 산다

- 등록기관은 아무 곳이나(가비아 · Cloudflare Registrar · Namecheap 등). 1년에 만~3만 원.
- 개인정보 보호(WHOIS privacy)를 켠다. 등록자 이름과 주소가 공개되지 않는다.
- 자동 갱신을 켠다. 만료되면 주소가 사라진다.
- **네임서버는 등록기관 것을 그대로 쓴다.** Cloudflare 같은 CDN 뒤에 두면 그 회사가 접속
  주소를 본다 — §4 에 걸리는 선택이라 지금은 두지 않는다. 필요해지면 그때 따로 정한다.

## 3. 서버를 만든다

- 어디든 좋다(Hetzner · DigitalOcean · Vultr). **공유 vCPU 2코어 · 메모리 2GB · 디스크 40GB**
  면 충분하다 — Rails 8 에 SQLite 하나다. 모자라면 그때 올린다.
- 값은 서울이 유럽보다 비싸다. **서울은 월 12달러 안팎이니 등록 전에 확인한다.**
- 운영체제는 **Ubuntu 24.04 LTS**.
- 만들 때 SSH 공개키를 넣는다(맥의 `~/.ssh/id_ed25519.pub`). 비밀번호 접속은 끈다.
- 만든 뒤 한 번 들어가 도커를 깔고 방화벽을 연다.

```
ssh root@<서버IP>
apt update && apt install -y docker.io sqlite3
ufw allow OpenSSH && ufw allow 80 && ufw allow 443 && ufw --force enable
```

## 4. DNS 를 잇는다

등록기관의 DNS 화면에서 두 줄.

| 종류 | 이름 | 값 |
|---|---|---|
| A | `@` | `<서버IP>` |
| A | `www` | `<서버IP>` |

`dig +short <도메인>` 이 `<서버IP>` 를 답하면 된 것이다(몇 분~몇 시간).

## 5. 메일 보낼 곳을 정한다

이 앱이 먼저 보내는 편지는 없다. 사용자가 청한 비밀번호 재설정 하나뿐이다.

- 한 달에 몇 통 수준이므로 무료 구간으로 충분하다(Resend · Postmark · Mailgun · SES 등).
- 가입한 뒤 도메인을 등록하고 **SPF · DKIM 레코드 두세 줄**을 DNS 에 넣는다. 그래야 편지가
  스팸으로 가지 않는다.
- 받은 SMTP 주소 · 계정 · 비밀번호를 위 표의 자리에 넣는다.
- **§4 의 문제다.** 브라우저는 메일 회사를 부르지 않으므로 제3자 요청은 0 그대로다(§6).
  다만 이메일 주소가 그 회사까지 간다 — 그것이 §4 다. 개인정보 안내에 한 줄이 필요하면
  그때 적는다.

## 6. 이미지 저장소

- 깃허브를 쓰면 따로 만들 것이 없다. `ghcr.io` 에 `write:packages` 권한의 토큰 하나를 만든다.
- 그 토큰을 `.kamal/secrets` 의 `KAMAL_REGISTRY_PASSWORD` 로 넣는다.

## 7. 비밀값을 넣는다

`.kamal/secrets` 는 추적하지 않는다. 값이 아니라 어디서 읽을지를 적는 파일이다.

```
KAMAL_REGISTRY_PASSWORD=$(cat ~/.secrets/fulltimezero-registry)
RAILS_MASTER_KEY=$(cat config/master.key)
SMTP_USER_NAME=$(cat ~/.secrets/fulltimezero-smtp-user)
SMTP_PASSWORD=$(cat ~/.secrets/fulltimezero-smtp-password)
```

## 8. 백업의 열쇠를 만든다

**맥에서 한 번만** 만든다. 여는 열쇠(`backup-key.pem`)는 맥에만 두고, 서버에는 공개키
(`backup-cert.pem`)만 올린다. 서버가 털려도 백업은 열리지 않는다.

```
openssl req -x509 -newkey rsa:4096 -days 7300 -nodes \
  -keyout ~/.secrets/fulltimezero-backup-key.pem \
  -out    ~/.secrets/fulltimezero-backup-cert.pem \
  -subj "/CN=fulltimezero-backup"
ssh root@<서버IP> "mkdir -p /rails/backup"
scp ~/.secrets/fulltimezero-backup-cert.pem root@<서버IP>:/rails/backup/backup-cert.pem
```

- 여는 열쇠를 잃으면 백업도 잃는다. 맥 밖에 한 벌 더 둔다(종이에 적거나, 다른 기기에).
- 여는 열쇠를 서버에 두지 않는다. 그 순간 이 구조의 뜻이 사라진다.

## 9. 백업을 둘 곳

밤마다 뜬 것을 **서버 밖**으로 보낸다. 서버가 사라지는 날 백업도 함께 사라지면 안 된다.

- 값싸고 단순한 곳이면 된다(Backblaze B2 · Cloudflare R2 · Hetzner Storage Box 등).
  1GB 도 쓰지 않으므로 한 달 몇백 원이다.
- 계정을 만들고 **이 백업 전용 열쇠**를 발급한다(다른 것에 손댈 수 없는 권한으로).
- 서버에 rclone 을 한 번 깔고 한 번 설정한다.

```
ssh root@<서버IP>
apt install -y rclone
rclone config          # 새 remote 이름을 backup 으로, 저장소 회사를 고르고 열쇠를 넣는다
```

- 서버의 환경변수에 `BACKUP_REMOTE=backup:fulltimezero` 를 둔다.
- 밤마다 한 번 돌게 한다(서버에서).

```
(crontab -l 2>/dev/null; echo "17 3 * * * BACKUP_REMOTE=backup:fulltimezero /rails/bin/backup >> /var/log/fulltimezero-backup.log 2>&1") | crontab -
```

## 10. 첫 배포

```
bin/kamal setup                      # 서버를 준비하고 처음 올린다
bin/kamal app exec 'bin/rails db:seed'   # 경전과 아홉 자리를 심는다
```

- 시드는 몇 번을 돌려도 같은 결과가 된다. `data/heart_sutra.yml` 이 바뀌면 다시 돌린다.
- 그 뒤의 배포는 `bin/kamal deploy` 하나다.

## 11. 배포한 바로 뒤에 확인할 것

- [ ] `https://<도메인>` 이 열린다. 자물쇠 표시(SSL)가 붙어 있다.
- [ ] `https://<도메인>/robots.txt` 가 `Disallow: /` 를 답한다. **아직 보여 줄 때가 아니다.**
- [ ] 화면 머리에 `noindex` 가 있다.
- [ ] 계정을 하나 만들고, 비밀번호 재설정 편지가 오는지 본다.
- [ ] **`bin/kamal proxy logs` 를 열어 접속 주소(IP)와 브라우저 정보가 남는지 본다.**
      남으면 §4 에 걸린다 — kamal-proxy 의 요청 기록을 끄거나, 남기는 항목을 줄이는 방법을
      찾아 여기에 적는다. 앱 쪽은 이미 껐다(`LOG_REQUESTS: false`).
- [ ] `bin/kamal app logs` 에 요청 줄이 없다.
- [ ] `/up` 이 200 을 답한다.

## 12. 복구 — 한 달에 한 번 연습한다

백업은 복구해 본 적이 있을 때에만 백업이다.

```
# 1. 최신 백업을 맥으로 받는다
rclone copy backup:fulltimezero <최신파일>.cms .      # 또는 scp root@<서버IP>:/rails/backup/... .

# 2. 맥에서 연다 — 여는 열쇠는 맥에만 있다
openssl cms -decrypt -binary -inform DER -in <최신파일>.cms \
            -inkey ~/.secrets/fulltimezero-backup-key.pem -out restored.sqlite3

# 3. 성한지 보고, 수를 센다
sqlite3 restored.sqlite3 "pragma integrity_check;"
sqlite3 restored.sqlite3 "select count(*) from users;"
sqlite3 restored.sqlite3 "select count(*) from copyings;"

# 4. 개발 서버에 열어 눈으로 본다
cp restored.sqlite3 storage/development.sqlite3 && bin/rails server
```

- 센 수를 운영의 수와 맞춰 본다: `bin/kamal app exec 'bin/rails runner "puts User.count, Copying.count"'`
- 진짜로 되돌릴 때는 앱을 멈추고 파일을 갈아 끼운 뒤 다시 띄운다.

```
bin/kamal app stop
scp restored.sqlite3 root@<서버IP>:/rails/storage/production.sqlite3
bin/kamal app start
```

## 13. 사람을 부를 때

검색에 보이게 하는 것은 한 줄이다. 그 전까지는 막혀 있다.

```
SEARCHABLE=true bin/kamal deploy
```

## 휴대폰으로 보기 — 배포가 아니다

`bin/review` 는 개발 서버와 Cloudflare 터널(빠른 모드, 계정 없음)을 함께 띄우고 임시 https
주소를 찍는다. 그 주소를 휴대폰에서 연다.

- **만든 사람 혼자 확인하는 용도다.** 트래픽이 Cloudflare 를 거치므로 다른 사람에게 이
  주소를 돌리지 않는다.
- 주소는 매번 바뀌고, 스크립트를 끄면(Ctrl-C) 서버와 터널이 함께 꺼진다.
- `cloudflared` 가 없으면 `brew install cloudflared`.
