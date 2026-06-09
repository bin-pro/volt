# VOLT 앱 자동 설정 스크립트
# 실행: ! .\setup.ps1 (Claude Code 터미널에서)

$flutterZip = "$env:USERPROFILE\flutter.zip"
$flutterDir = "$env:USERPROFILE\flutter"

# 1. Flutter SDK 압축 해제
if (-not (Test-Path "$flutterDir\bin\flutter.bat")) {
    if (Test-Path $flutterZip) {
        Write-Host "Flutter SDK 압축 해제 중... (1-2분 소요)"
        Expand-Archive -Path $flutterZip -DestinationPath $env:USERPROFILE -Force
        Write-Host "완료!"
    } else {
        Write-Host "ERROR: flutter.zip 파일이 없습니다. 먼저 다운로드하세요."
        exit 1
    }
}

# 2. PATH 설정
$env:PATH = "$flutterDir\bin;$env:PATH"
Write-Host "Flutter PATH 설정 완료"

# 3. Flutter 버전 확인
flutter --version

# 4. 의존성 설치
Set-Location "$PSScriptRoot"
Write-Host "패키지 설치 중..."
flutter pub get

# 5. Drift 코드 생성
Write-Host "코드 생성 중 (build_runner)..."
dart run build_runner build --delete-conflicting-outputs

Write-Host ""
Write-Host "========================================="
Write-Host "설정 완료! 이제 실행하세요:"
Write-Host "  flutter devices      # 기기 확인"
Write-Host "  flutter run          # 앱 실행"
Write-Host "========================================="
Write-Host ""
Write-Host "[중요] 폰트 파일을 assets/fonts/ 폴더에 추가해주세요:"
Write-Host "  Anton-Regular.ttf"
Write-Host "  Archivo-Regular/Medium/SemiBold/Bold.ttf"
Write-Host "  JetBrainsMono-Regular/Medium.ttf"
Write-Host "  (Google Fonts에서 무료 다운로드 가능)"
