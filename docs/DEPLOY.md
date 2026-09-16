# 배포

> This app is a raft. — 이 앱도 뗏목이다.

Kamal 로 배포한다(`config/deploy.yml`).

## 배포할 때 잊지 말 것

- **경전은 시드로 들어간다.** 운영에 처음 올릴 때와 `data/heart_sutra.yml`
  이 바뀔 때마다 `bin/kamal app exec 'bin/rails db:seed'` 를 한 번 돌린다.
  시드는 몇 번을 돌려도 같은 결과가 되므로 겹쳐 돌려도 괜찮다.

## 휴대폰으로 보기 — 배포가 아니다

`bin/review` 는 개발 서버와 Cloudflare 터널(빠른 모드, 계정 없음)을 함께
띄우고 임시 https 주소를 찍는다. 그 주소를 휴대폰에서 연다.

```
bin/review
  휴대폰에서:  https://xxxx-xxxx.trycloudflare.com/ko
```

- **만든 사람 혼자 확인하는 용도다.** 트래픽이 Cloudflare 를 거치므로
  다른 사람에게 이 주소를 돌리지 않는다. 진짜 배포는 아래 절차로.
- 주소는 매번 바뀌고, 스크립트를 끄면(Ctrl-C) 서버와 터널이 함께 꺼진다.
- 개발 환경만 `*.trycloudflare.com` 을 hosts 에 받는다
  (`config/environments/development.rb`). 운영 설정은 건드리지 않았다.
- `cloudflared` 가 없으면 `brew install cloudflared`.

## 운영 배포

아직 절차를 적지 않았다 — 어디에 올릴지 정한 뒤 여기에 채운다.
