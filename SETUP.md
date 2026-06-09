# VOLT 앱 설치 및 실행 가이드

## 1. Flutter SDK 설치

터미널(PowerShell)에서:

```powershell
# flutter.zip 압축 해제 (이미 다운로드되어 있다면)
Expand-Archive -Path "$env:USERPROFILE\flutter.zip" -DestinationPath "$env:USERPROFILE" -Force

# PATH에 Flutter 추가 (현재 세션)
$env:PATH += ";$env:USERPROFILE\flutter\bin"

# Flutter doctor 실행
flutter doctor
```

PATH를 영구적으로 추가하려면 시스템 환경 변수에 `%USERPROFILE%\flutter\bin` 추가.

## 2. 프로젝트 의존성 설치

```powershell
cd C:\Users\Growfy\Desktop\volt\volt_app
flutter pub get
```

## 3. Drift 코드 생성

```powershell
flutter pub run build_runner build --delete-conflicting-outputs
```

이 명령으로 `lib/core/database/app_database.g.dart` 파일이 생성됩니다.

## 4. 폰트 파일 추가

`assets/fonts/` 폴더에 다음 폰트 파일을 다운로드하여 넣으세요:
- [Anton](https://fonts.google.com/specimen/Anton): `Anton-Regular.ttf`
- [Archivo](https://fonts.google.com/specimen/Archivo): `Archivo-Regular.ttf`, `Archivo-Medium.ttf`, `Archivo-SemiBold.ttf`, `Archivo-Bold.ttf`  
- [JetBrains Mono](https://www.jetbrains.com/lp/mono/): `JetBrainsMono-Regular.ttf`, `JetBrainsMono-Medium.ttf`

또는 Google Fonts 패키지를 사용하는 방식으로 전환 가능 (`google_fonts` 패키지 추가).

## 5. 앱 실행

```powershell
# 연결된 기기/에뮬레이터 확인
flutter devices

# 앱 실행
flutter run
```

## 주요 파일 구조

```
lib/
├── main.dart                         앱 진입점
├── app_router.dart                   go_router 라우팅
├── shell/main_shell.dart             하단 탭바
├── core/
│   ├── theme/app_theme.dart          디자인 토큰 + ThemeData
│   ├── database/app_database.dart    Drift SQLite 스키마
│   ├── providers/                    Riverpod providers
│   └── utils/                       무게 변환, 초성 검색
└── features/
    ├── home/                         홈 탭 (잔디, 주간 볼륨, 최근 세션)
    ├── session/                      세션 추가 플로우 (부위 선택 → 종목 선택)
    ├── workout/                      운동 탭 (세트 입력, 종목 목록)
    ├── timer/                        전체화면 휴식 타이머
    ├── stats/                        통계 탭 (잔디, 3대 500, 도넛)
    └── settings/                     설정 탭
```
