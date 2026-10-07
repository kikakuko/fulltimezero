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
| — | 가입을 받는가. **기본은 받지 않음** | `SIGNUPS`(여는 말은 `true` 하나) |
| — | 검색에 보이는가. **기본은 막음** | `SEARCHABLE` |
| `<백업저장소>` | 백업을 올릴 사설 깃허브 저장소 | 서버의 `BACKUP_REPO` |

환경변수는 배포하는 맥의 셸에 둔다. 예(비밀값은 여기 두지 않는다):

```
export APP_HOST=<도메인>
export DEPLOY_SERVER_IP=<서버IP>
export REGISTRY_SERVER=ghcr.io
export DEPLOY_ARCH=arm64            # Ampere A1 이면 arm64, AMD 마이크로면 amd64
export REGISTRY_USER=<저장소계정>
export MAIL_FROM=no-reply@<도메인>
export SMTP_ADDRESS=<메일서버>
```

## 2. 도메인을 산다 — 끝났다(2026-10-07)

`fulltimezero.com` 을 Porkbun 에서 샀다. 만료 2027-10-07, 자동 갱신 켬, 도메인 잠금
(`clientTransferProhibited`) 걸림, 공개 조회에 등록자 이름 · 주소 · 전화가 보이지 않는다.
네임서버는 Porkbun 기본 넷. 아래는 다음에 다시 할 때를 위한 적바림이다.

- 등록기관은 아무 곳이나(가비아 · Cloudflare Registrar · Namecheap 등). 1년에 만~3만 원.
- 개인정보 보호(WHOIS privacy)를 켠다. 등록자 이름과 주소가 공개되지 않는다.
- 자동 갱신을 켠다. 만료되면 주소가 사라진다.
- **네임서버는 등록기관 것을 그대로 쓴다.** Cloudflare 같은 CDN 뒤에 두면 그 회사가 접속
  주소를 본다 — §4 에 걸리는 선택이라 지금은 두지 않는다. 필요해지면 그때 따로 정한다.

## 3. 서버를 만든다

**고른 곳: Oracle Cloud Always Free · 홈 리전 서울.** 값이 0원이고 진짜 리눅스 한 대라
Kamal 설정이 그대로 간다(Fly.io · Render 를 버린 까닭이 이것이다). 유료(Vultr 서울)로
갔던 것은 「오늘 보려면」이라는 까닭이었고, 그것은 정한 적 없는 조건이었다 — 되돌렸다.

- **기계는 둘 중 하나.** `VM.Standard.A1.Flex`(Ampere, arm64)가 첫째다. 2026년부터 무료
  몫이 2 OCPU · 12GB 로 줄었고, 그 안에서 1 OCPU · 6GB 면 넉넉하다. 서울은 「Out of host
  capacity」 가 잦아 못 잡을 수 있다.
- **못 잡으면 `VM.Standard.E2.1.Micro`**(AMD, amd64, 1/8 OCPU · 1GB). 영구 무료이고 대개
  바로 잡힌다. **스왑 2GB 를 먼저 붙이고 올린다**(아래). 앱은 1GB 에서 돌지만 짓는 일이
  빡빡하다.
- 기계의 결이 바뀌면 `DEPLOY_ARCH` 를 함께 바꾼다 — A1 은 `arm64`(기본), 마이크로는 `amd64`.
- 부트 볼륨은 47GB 이상이어야 하고 무료 몫은 전부 합쳐 200GB 다.
- 운영체제는 **Ubuntu 24.04 LTS**(Platform Images → Ubuntu).
- 만들 때 SSH 공개키를 붙여넣는다(맥의 `~/.ssh/id_ed25519.pub`).
- **Oracle 은 80 · 443 이 기본으로 막혀 있다.** VCN 의 Security List 에 ingress 둘을 손으로
  연다 — TCP, 0.0.0.0/0, 포트 80 과 443.

### 1GB 기계에 스왑 먼저

```
ssh ubuntu@<서버IP>
sudo fallocate -l 2G /swapfile && sudo chmod 600 /swapfile
sudo mkswap /swapfile && sudo swapon /swapfile
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
```

- 다른 곳이어도 조건은 같다. **공유 vCPU 2코어 · 메모리 2GB · 디스크 40GB** 면 충분하다 —
  Rails 8 에 SQLite 하나다. 모자라면 그때 올린다.
- 운영체제는 **Ubuntu 24.04 LTS**.
- 만들 때 SSH 공개키를 넣는다(맥의 `~/.ssh/id_ed25519.pub`). 비밀번호 접속은 끈다.
- 만든 뒤 한 번 들어가 도커를 깔고 방화벽을 연다.

```
ssh root@<서버IP>
apt update && apt install -y docker.io sqlite3
ufw allow OpenSSH && ufw allow 80 && ufw allow 443 && ufw --force enable

# 접속 주소가 쌓이지 않게 — 방화벽 기록은 끄고, 들어온 기록은 짧게 둔다(§4).
ufw logging off
mkdir -p /etc/systemd/journald.conf.d
printf '[Journal]\nSystemMaxUse=50M\nMaxRetentionSec=3day\n' > /etc/systemd/journald.conf.d/short.conf
systemctl restart systemd-journald

# 도커가 담는 기록도 짧게 — 프록시의 접속 기록이 여기 쌓인다.
printf '{ "log-driver": "json-file", "log-opts": { "max-size": "10m", "max-file": "2" } }\n' > /etc/docker/daemon.json
systemctl restart docker
```

## 4. DNS 를 잇는다

등록기관의 DNS 화면에서 두 줄.

| 종류 | 이름 | 값 | TTL |
|---|---|---|---|
| A | `@`(빈칸) | `<서버IP>` | 600 |
| A | `www` | `<서버IP>` | 600 |
| A | `app` | `<서버IP>` | 600 |

셋 다 같은 서버다. `www` 는 앱이 맨 이름으로 영구 넘김(301)하고, `app` 은 넘기지 않고
그대로 선다 — 훗날 맨 이름에 소개나 강의가 들어와도 앱이 이사하지 않게 살려 두는 자리다.
**Porkbun 이 기본으로 넣어 둔 `@` · `www` 레코드(주차 페이지)가 있으면 지우고 넣는다.**

`dig +short <도메인>` 이 `<서버IP>` 를 답하면 된 것이다(몇 분~몇 시간).

## 5. 메일 보낼 곳을 정한다 — 가입을 열 때

**가입이 닫혀 있는 동안은 건너뛴다.** 편지를 보낼 일이 없고, 없는 비밀값을 적어 두면
배포가 멈춘다. `config/deploy.yml` 의 `env.secret` 과 `.kamal/secrets` 에서 SMTP 둘은
주석으로 내려 두었다 — 메일 회사가 정해지면 함께 되살린다.

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
KAMAL_REGISTRY_PASSWORD=$KAMAL_REGISTRY_PASSWORD
RAILS_MASTER_KEY=$(cat config/master.key)
# 가입을 열 때 되살린다 — config/deploy.yml 의 env.secret 에서도 함께.
# SMTP_USER_NAME=$SMTP_USER_NAME
# SMTP_PASSWORD=$SMTP_PASSWORD
```

껍데기에 한 번 내보내 둔다(값은 이 문서에도, 저장소에도 적지 않는다):

```
export KAMAL_REGISTRY_PASSWORD=<저장소토큰>
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

## 9. 백업을 둘 곳 — 사설 깃허브 저장소

계정을 더 만들지 않는다. 사설 저장소 하나에 암호화된 덩어리를 올린다. 판이 쌓이는 것은
깃이 알아서 하고, 저장소에는 늘 같은 이름의 파일 하나만 있다 — 지난 판은 역사에 남는다.

1. 깃허브에서 **사설(Private) 저장소**를 하나 만든다. 이름은 `fulltimezero-backup`.
   설명 · README · 라이선스 없이 빈 채로 만든다.
2. 서버에서 그 저장소에만 쓰는 열쇠를 만든다. **배포 키(deploy key)라 이 저장소 하나에만
   닿는다** — 다른 저장소에는 손대지 못한다.

```
ssh root@<서버IP>
ssh-keygen -t ed25519 -f /root/.ssh/backup -N "" -C "fulltimezero backup"
cat /root/.ssh/backup.pub
printf 'Host github-backup\n  HostName github.com\n  User git\n  IdentityFile /root/.ssh/backup\n' >> /root/.ssh/config
```

3. 그 공개키를 저장소의 **Settings → Deploy keys → Add deploy key** 에 붙이고
   **「Allow write access」를 켠다.**
4. 백업이 그리로 가게 한다 — `BACKUP_REPO=git@github-backup:<계정>/fulltimezero-backup.git`.

**암호화된 덩어리만 올라간다.** 저장소가 새어도 여는 열쇠가 없으면 열리지 않는다 —
개인키는 맥에만 있다(§8).

**언젠가 무거워진다.** 암호화한 덩어리는 압축도 델타도 먹지 않아서, 날마다 **파일 전체
크기가 깃 역사에 그대로 쌓인다.** 기록이 몇십 KB 인 지금은 한 해에 백여 메가지만, 사람이
늘면 달라진다. 저장소가 몇백 메가에 가까워지면 둘 중 하나를 한다 — ㉮ **해마다 저장소를
새로 만든다**(`fulltimezero-backup-2027`. 가장 단순하고, 지난해 것이 그대로 남는다),
㉯ **역사를 자른다**(서버의 사본을 지우고 `git checkout --orphan` 으로 한 판만 남겨 다시
올린다. 지난 판을 잃는다). **㉮ 를 권한다** — 백업의 값은 지난 판에 있다.
나중에 발견하면 이미 무겁다. 해가 바뀔 때 한 번 본다.

## 10. 첫 배포

이미지는 **서버에서 짓는다**(`builder.remote`). 맥에는 도커 데몬이 필요 없고 CLI 만 있으면
된다 — `brew install docker docker-buildx`. Docker Desktop 도, 도커 계정도 쓰지 않는다.

```
bin/kamal setup                      # 서버를 준비하고 처음 올린다
bin/kamal app exec 'bin/rails db:seed'   # 경전과 아홉 자리를 심는다
```

가입과 검색은 아무것도 적지 않아도 닫혀 있다(`SignupGate` · `SearchGate`). 첫 배포에서
따로 끌 것이 없다 — 켜는 쪽에만 한 줄이 필요하다(§13).

- 시드는 몇 번을 돌려도 같은 결과가 된다. `data/heart_sutra.yml` 이 바뀌면 다시 돌린다.
- 그 뒤의 배포는 `bin/kamal deploy` 하나다.

## 11. 배포한 바로 뒤에 확인할 것

- [ ] `https://<도메인>` 이 열린다. 자물쇠 표시(SSL)가 붙어 있다.
- [ ] `https://www.<도메인>` 이 맨 이름으로 넘어간다. `https://app.<도메인>` 도 열린다.
- [ ] `https://<도메인>/robots.txt` 가 `Disallow: /` 를 답한다. **아직 보여 줄 때가 아니다.**
- [ ] 화면 머리에 `noindex` 가 있고, 머리말에 `X-Robots-Tag` 가 있다.
- [ ] **가입이 정말 잠겼는지 일부러 열어 본다** — `/ko/sign_up` · `/ko/session/new` ·
      `/ko/passwords/new` 가 모두 404 다. 문 셋의 끝은 「아직 가입을 받지 않는다」로 간다.
- [ ] `bin/kamal app logs` 에 요청 줄이 없다(요청을 적는 미들웨어를 걷었다).
- [ ] `bin/kamal proxy logs` 에는 접속 주소가 남는다 — **끌 수 없는 층이다.** 브라우저
      정보(User-Agent)는 비웠다. 도커 기록 회전으로 보관만 짧게 한다(§3). 아래 표를 본다.
- [ ] `/up` 이 200 을 답한다.
- [ ] 백업을 한 번 손으로 돌려 본다(아래 「백업을 하루 한 번」).

## 11.5 접속 주소가 쌓이는 층 — 가린 것 없이

§4 는 「이메일 하나뿐」이라고 말한다. 실제로 접속 주소(IP)가 닿는 층을 전부 적는다.
못 끄는 층이 있으면 숨기지 않는다.

| 층 | 주소가 남는가 | 지금 어떻게 하고 있나 |
|---|---|---|
| 레일즈 요청 기록 | **남지 않는다** | 요청을 적는 미들웨어를 운영에서 걷었다(`production.rb`) |
| 레일즈 오류 기록 | 남지 않는다 | 예외와 자리만 적힌다. 시도를 세는 자리도 이메일로 센다 |
| kamal-proxy 접근 기록 | **남는다 — 끌 수 없다** | 브라우저 정보는 비웠다(`logging.request_headers: []`). 도커 기록을 10MB·2벌로 회전시켜 보관을 짧게 |
| 도커 데몬 | 위와 같은 층 | 같은 회전 설정 |
| sshd(들어온 기록) | **남는다** | 끄지 않는다 — 침입을 보려면 필요하다. journald 를 사흘·50MB 로 짧게 |
| 방화벽(ufw) | 끌 수 있다 | `ufw logging off` |
| 서버 회사(Vultr) | **남는다 — 우리 손 밖이다** | 네트워크 흐름과 콘솔 접속은 그 회사가 가진다. 가입을 열 때 처리방침의 수탁자로 적는다 |
| Let's Encrypt | 사용자 주소는 가지 않는다 | 서버가 CA 를 부른다. 브라우저는 부르지 않는다(§6) |
| Porkbun DNS | 사용자 주소는 가지 않는다 | 질의는 사용자의 리졸버에서 온다 |

요약: **못 끄는 층이 둘이다** — 프록시의 접근 기록과 서버 회사. 둘 다 보관을 짧게 하는
것까지가 지금 할 수 있는 전부다. 가입을 열 때 처리방침에 이 둘을 적는다.

## 11.6 백업을 하루 한 번 — 호스트에서 돈다

앱 컨테이너가 아니라 서버(호스트)에서 돈다. 컨테이너 이름이 배포마다 바뀌어도 상관없고,
데이터베이스 파일은 도커 볼륨에 그대로 있다. **여는 열쇠는 맥에만 있다(§8).**

```
# 맥에서 — 스크립트와 공개키만 올린다. 개인키는 올리지 않는다.
scp bin/backup root@<서버IP>:/usr/local/bin/fulltimezero-backup
ssh root@<서버IP> 'chmod +x /usr/local/bin/fulltimezero-backup && mkdir -p /root/backup'
scp ~/.secrets/fulltimezero-backup-cert.pem root@<서버IP>:/root/backup/backup-cert.pem

# 서버에서 — 한 번 손으로 돌려 보고, 되면 하루 한 번으로 걸어 둔다(04:15 한국 시각).
ssh root@<서버IP>
export DATABASE_PATH=/var/lib/docker/volumes/fulltimezero_storage/_data/production.sqlite3
export BACKUP_DIR=/root/backup
/usr/local/bin/fulltimezero-backup

cat > /etc/cron.d/fulltimezero-backup <<'EOF'
15 19 * * * root DATABASE_PATH=/var/lib/docker/volumes/fulltimezero_storage/_data/production.sqlite3 BACKUP_DIR=/root/backup BACKUP_REPO=git@github-backup:<계정>/fulltimezero-backup.git /usr/local/bin/fulltimezero-backup >> /var/log/fulltimezero-backup.log 2>&1
EOF
```

보낼 곳(`BACKUP_REMOTE`)이 정해지기 전에는 서버에만 남는다 — 서버가 사라지면 백업도
사라진다는 뜻이다. 가입을 열기 전에 반드시 바깥으로 보내게 한다(§9).

**Oracle 에서는 이것이 더 급하다.** 이레 동안 CPU · 네트워크(A1 은 메모리까지)가 모두
스물 푼 아래면 그 기계는 회수 대상이 된다. 하루 몇 사람 쓰는 앱이 바로 그 조건이다.
다만 그 대비는 「더 자주 뜨기」가 아니라 **「서버 밖에 두기」**다 — 기록이 하루 몇 줄이라
하루 한 번으로 잃을 것이 적고, 서버가 통째로 사라지는 쪽이 진짜 위험이다. 그래서
`BACKUP_REMOTE` 를 먼저 정하고, 배포 직전에도 한 번 뜬다.

## 11.7 서버가 사라졌을 때 — 한 시간 안에 다시 세운다

Oracle 의 무료 기계는 이레 동안 쓰임이 낮으면 회수 대상이다. 회수가 중지인지 삭제인지는
오라클 문서에 적혀 있지 않다. **사라질 것을 전제로 삼는다** — 적어 두면 사고가 아니라
절차다. 아홉 단계이고, 사람이 기다리는 시간(인스턴스 생성과 인증서 발급)을 빼면 손은
몇 분이다.

1. **새 인스턴스.** Compute → Create instance. 이름 `fulltimezero`, Ubuntu 24.04,
   같은 shape(A1 이면 arm64, 마이크로면 amd64), 공인 IPv4 자동 할당, SSH 공개키 붙여넣기.
2. **포트.** 쓰던 VCN 이 남아 있으면 Security List 의 80 · 443 규칙도 남아 있다. 새로
   만들었으면 다시 연다(TCP · 0.0.0.0/0 · 80 과 443).
3. **서버 손질.** 도커 · sqlite3 · 방화벽 · 기록 짧게 · 스왑(1GB 기계면) — §3 의 명령 그대로.
4. **DNS.** Porkbun 의 A 레코드 셋(`@` · `www` · `app`)을 새 IP 로 고친다. TTL 이 열 분이라
   십여 분이면 돈다. **DNS 가 먼저 돌아야 인증서가 난다.**
5. **환경변수.** 맥에서 `export DEPLOY_SERVER_IP=<새IP>`(결이 바뀌었으면 `DEPLOY_ARCH` 도).
6. **올리기.** `bin/kamal setup`. 이미지는 서버에서 짓는다.
7. **되살리기.** 백업을 맥에서 열어(§12) 서버에 넣는다:

```
bin/kamal app stop
scp restored.sqlite3 root@<새IP>:/var/lib/docker/volumes/fulltimezero_storage/_data/production.sqlite3
bin/kamal app start
```

8. **씨앗.** `bin/kamal app exec 'bin/rails db:seed'` — 경전과 아홉 자리, 그리고 구경하는
   자리의 씨앗이 다시 선다.
9. **확인.** §11 의 목록을 그대로 한 번. 그리고 백업을 다시 세운다(§11.6 · §9) — 새 서버에는
   배포 키도 cron 도 없다. **이것을 잊으면 다음 사라짐은 되돌릴 수 없다.**

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

문이 둘이고 둘 다 기본이 닫힘이다. 열 때는 한 줄씩이고, 순서가 있다.

```
SIGNUPS=true bin/kamal deploy       # 가입을 받는다 — 그 전에 아래 넷을 먼저
SEARCHABLE=true bin/kamal deploy    # 검색에 보인다
```

가입을 열기 전에 먼저 할 넷:

1. 처리방침의 `{{CPO_NAME}}`(맡은 사람의 실명)과 받는 메일을 채운다.
2. `{{HOST_NAME}}`(서버 회사)과 메일 회사를 채우고, 맡기기 전에 처리위탁 계약서를 받는다.
3. 메일 회사를 정하고 SMTP 둘을 되살린다(§5).
4. 백업을 서버 밖으로 보내게 한다(§9) — 서버 하나에만 있는 백업은 백업이 아니다.

## 휴대폰으로 보기 — 배포가 아니다

`bin/review` 는 개발 서버와 Cloudflare 터널(빠른 모드, 계정 없음)을 함께 띄우고 임시 https
주소를 찍는다. 그 주소를 휴대폰에서 연다.

- **만든 사람 혼자 확인하는 용도다.** 트래픽이 Cloudflare 를 거치므로 다른 사람에게 이
  주소를 돌리지 않는다.
- 주소는 매번 바뀌고, 스크립트를 끄면(Ctrl-C) 서버와 터널이 함께 꺼진다.
- `cloudflared` 가 없으면 `brew install cloudflared`.
