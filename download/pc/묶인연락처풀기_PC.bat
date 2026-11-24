@echo off
rem 묶인 연락처 풀기 PC판 실행기: 새 판을 묻지 않고 받아 두고, 바탕화면·시작 메뉴 아이콘을 만들고, 프로그램 창을 엽니다.
setlocal
set "SELF=%~f0"
powershell -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -Command "$s=[IO.File]::ReadAllText($env:SELF,[Text.Encoding]::UTF8); $m='#=='+'PS=='; iex $s.Substring($s.LastIndexOf($m)+$m.Length)"
exit /b
#==PS==
$ErrorActionPreference = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$D = Join-Path $env:LOCALAPPDATA 'ContactUnlinkPC'
New-Item -ItemType Directory -Force -Path $D | Out-Null
$base = 'https://raw.githubusercontent.com/ds4eqm-lgtm/contact-unlink/main/'
$html = Join-Path $D 'contact-unlink-pc.html'
$ico  = Join-Path $D 'contact-unlink-pc.ico'
$vf   = Join-Path $D 'ver.txt'
function VNum($v) { $p = "$v".Split('.'); return [int]$p[0] * 1000 + [int]$p[1] }
$cur = '0.0'; if (Test-Path $vf) { $cur = (Get-Content $vf -Raw).Trim() }
# 새 판 확인: 있으면 묻지 않고 받고, 지문값(SHA-256)이 맞을 때만 바꾼다
try {
  $j = Invoke-RestMethod -Uri ($base + 'app/version.json?t=' + [DateTime]::Now.Ticks) -TimeoutSec 20
  if ($j.pc -and ((VNum $j.pc) -gt (VNum $cur) -or -not (Test-Path $html))) {
    $tmp = "$html.new"
    Invoke-WebRequest -Uri ($base + 'download/pc/contact-unlink-pc.html?t=' + [DateTime]::Now.Ticks) -OutFile $tmp -UseBasicParsing -TimeoutSec 120
    if ((Get-FileHash $tmp -Algorithm SHA256).Hash.ToLower() -eq "$($j.pcSha)".ToLower()) { Move-Item -Force $tmp $html; Set-Content -Path $vf -Value $j.pc -Encoding ASCII } else { Remove-Item $tmp -Force }
  }
  if (-not (Test-Path $ico)) { Invoke-WebRequest -Uri ($base + 'download/pc/contact-unlink-pc.ico') -OutFile $ico -UseBasicParsing -TimeoutSec 60 }
} catch { }
# 실행기 자신을 늘 같은 곳에 두고, 바탕화면과 시작 메뉴에 아이콘을 만든다(이미 있으면 그대로 고쳐 씀)
$bat = Join-Path $D '묶인연락처풀기_PC.bat'
if ($env:SELF -ne $bat) { Copy-Item -Force $env:SELF $bat }
$ws = New-Object -ComObject WScript.Shell
foreach ($dir in @([Environment]::GetFolderPath('Desktop'), [Environment]::GetFolderPath('Programs'))) {
  $l = $ws.CreateShortcut((Join-Path $dir '묶인 연락처 풀기 PC.lnk'))
  $l.TargetPath = $bat; $l.WorkingDirectory = $D; $l.WindowStyle = 7
  if (Test-Path $ico) { $l.IconLocation = $ico }
  $l.Description = '묶인 연락처 풀기 PC판: 휴대폰 연락처 백업을 PC에 보관하고 되돌리기'
  $l.Save()
}
if (-not (Test-Path $html)) {
  Add-Type -AssemblyName System.Windows.Forms
  [System.Windows.Forms.MessageBox]::Show('인터넷에 연결되지 않아 프로그램을 받지 못했습니다. 인터넷을 확인하고 다시 켜 주세요.', '묶인 연락처 풀기 PC판') | Out-Null
  exit
}
# 엣지(없으면 크롬)로 앱 창처럼 연다. 폴더 쓰기 기능이 있는 브라우저여야 한다
$url = 'file:///' + ($html -replace '\\', '/')
$cands = @("${env:ProgramFiles(x86)}\Microsoft\Edge\Application\msedge.exe", "$env:ProgramFiles\Microsoft\Edge\Application\msedge.exe",
           "$env:ProgramFiles\Google\Chrome\Application\chrome.exe", "${env:ProgramFiles(x86)}\Google\Chrome\Application\chrome.exe", "$env:LOCALAPPDATA\Google\Chrome\Application\chrome.exe")
$b = $cands | Where-Object { $_ -and (Test-Path $_) } | Select-Object -First 1
if ($b) { Start-Process -FilePath $b -ArgumentList "--app=$url" } else { Start-Process $html }
