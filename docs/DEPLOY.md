# 배포

> This app is a raft. — 이 앱도 뗏목이다.

Kamal 로 배포한다(`config/deploy.yml`).

## 배포할 때 잊지 말 것

- **경전은 시드로 들어간다.** 운영에 처음 올릴 때와 `data/heart_sutra.yml`
  이 바뀔 때마다 `bin/kamal app exec 'bin/rails db:seed'` 를 한 번 돌린다.
  시드는 몇 번을 돌려도 같은 결과가 되므로 겹쳐 돌려도 괜찮다.
