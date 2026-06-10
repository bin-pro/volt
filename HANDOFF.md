# VOLT — 인수인계 메모

맥북 Claude Code에서 이 레포를 열 때 읽을 파일.
현재까지 구현된 것, 남은 것, 배포 방법이 정리되어 있음.

---

## 현재 상태 (2026-06-09 기준)

Flutter 앱 코드 완성, Codemagic으로 iOS 빌드 성공, `.ipa` 생성까지 완료.
아직 iPhone에 설치는 못 한 상태 (Windows Sideloadly 페어링 실패).

---

## 맥북에서 iPhone 설치하는 법 (바로 하면 됨)

```bash
# 1. 레포 클론
git clone https://github.com/bin-pro/volt
cd volt/volt_app

# 2. 의존성
flutter pub get

# 3. iPhone USB 연결 후 설치
flutter run --release
```

- iPhone에서 "이 컴퓨터를 신뢰하시겠습니까?" → **신뢰**
- 처음 실행 시: 설정 → 일반 → VPN 및 기기 관리 → Apple ID → 신뢰
- 무료 Apple ID면 **7일마다** 재실행(`flutter run --release`) 필요

---

## 구현 완료된 기능

- **홈**: 이번 주 볼륨 + 요일 바, 볼륨 잔디(이번 달 기준, 부위 색상), 최근 세션
- **세션 추가**: 부위 선택(사진 배경) → 종목 선택(초성 검색 ㅋㅇㅂ 등) → 누른 순서 보존
- **운동 탭**: 세트 입력(kg/lb 토글, 워밍업 W, RPE), 직전 기록 placeholder
- **전체화면 타이머**: 원형 링, ±10/±5 조정, 5단계 프리셋(1:00~3:00), 사운드+진동
- **통계**: 잔디 + 도넛 차트 + 3대 500 진행바
- **설정**: 단위/워밍업/RPE/타이머 토글

---

## 미완성 (나중에 할 것)

- [ ] 유산소 기록 화면 UI (DB 구조는 있음)
- [ ] 1RM 실제 DB 연동 (stats_screen에 placeholder)
- [ ] Supabase 동기화 + 소셜 로그인 (Google/카카오/Apple)
- [ ] 앱 아이콘 (현재 Flutter 기본 아이콘)
- [ ] Bundle ID 변경 `com.example.volt` → 앱스토어 배포 시 필요

---

## 앱스토어 배포 조건 (나중에)

- Apple Developer 계정 연 $99 필요
- Bundle ID를 고유하게 변경 (예: `com.binpro.volt`)
  - `ios/Runner.xcodeproj/project.pbxproj` 에서 `PRODUCT_BUNDLE_IDENTIFIER` 변경
- 앱 아이콘 1024×1024, 스크린샷(6.7인치), 설명 준비
- 심사 1~3일

---

## 알려진 이슈 / 해결된 것들

| 이슈 | 해결 |
|------|------|
| `Generated.xcconfig` Windows 경로 | git에서 제거, CI에서 재생성 |
| `drift_flutter 0.2.7` isolateDebugLog API 불일치 | `drift_flutter: 0.2.4`로 핀 |
| UUID RangeError | dart:math 기반 UUID v4로 교체 |
| 타이머 사운드 | audioplayers + timer_end.wav |
| 부위 선택 사진 배경 | DecorationImage + 40% 다크 오버레이 |
| 잔디 UI 고정 픽셀 | 14px 셀 Row/Column (GridView 아님) |

---

## 주요 파일 위치

```
lib/
  core/
    database/app_database.dart     # Drift DB 스키마 + 쿼리
    utils/uuid_utils.dart          # UUID v4 생성
  features/
    home/                          # 홈 탭
    session/screens/               # 부위선택, 종목선택
    workout/                       # 운동 탭, 세트입력
    timer/timer_screen.dart        # 전체화면 타이머
    stats/                         # 통계 탭
    settings/                      # 설정 탭
assets/
  data/exercises_seed.json         # 운동 종목 108개
  images/muscle_groups/            # 부위 사진 7장
  sounds/timer_end.wav             # 타이머 완료음
codemagic.yaml                     # CI/CD (iOS 빌드)
```

---

## Codemagic 재빌드 방법

코드 수정 후 push하면 자동 빌드 안 됨 (수동 트리거 설정).
[codemagic.io](https://codemagic.io) → VOLT 프로젝트 → **Start new build**.
