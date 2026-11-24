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
# Ver0.61: 실행기 자신도 새 판이면 묻지 않고 바꾼다(지문값이 맞을 때만)
try { if ($j.batSha -and ((Get-FileHash $bat -Algorithm SHA256).Hash.ToLower() -ne "$($j.batSha)".ToLower())) { $tb = "$bat.new"; Invoke-WebRequest -Uri ($base + 'download/pc/' + [Uri]::EscapeDataString('묶인연락처풀기_PC.bat') + '?t=' + [DateTime]::Now.Ticks) -OutFile $tb -UseBasicParsing -TimeoutSec 60; if ((Get-FileHash $tb -Algorithm SHA256).Hash.ToLower() -eq "$($j.batSha)".ToLower()) { Move-Item -Force $tb $bat } else { Remove-Item $tb -Force } } } catch { }
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
# Ver0.61: USB를 살피는 PC 도우미를 숨은 창으로 따로 켠다(이 창은 바로 닫힘)
$hc = "`$s=[IO.File]::ReadAllText('$bat',[Text.Encoding]::UTF8); `$m='#=='+'HELP=='; iex `$s.Substring(`$s.LastIndexOf(`$m)+`$m.Length)"
Start-Process -FilePath 'powershell.exe' -WindowStyle Hidden -ArgumentList @('-NoProfile','-ExecutionPolicy','Bypass','-WindowStyle','Hidden','-Command',$hc)
exit
#==HELP==
$ErrorActionPreference = 'SilentlyContinue'
$D = Join-Path $env:LOCALAPPDATA 'ContactUnlinkPC'
# ---------- Ver0.61: PC 도우미 (USB) ----------
# 프로그램 창(file://)이 http://localhost:8766 으로 묻는다: 휴대폰이 USB로 꽂혔는지, 파일 전송이 켜졌는지, 지난번 보관 위치, 복사 진행.
# 복사는 휴대폰 Download\묶인연락처풀기 → 보관 위치\묶인연락처풀기 로, PC에 없거나 크기가 다른 파일만. 휴대폰 쪽은 읽기만 한다.
$L = New-Object Net.HttpListener
$L.Prefixes.Add('http://localhost:8766/')
try { $L.Start() } catch { exit }   # 이미 다른 창에서 도우미가 돌고 있으면 그것을 쓴다
$tf = Join-Path $D 'usb_target.txt'
$sf = Join-Path $D 'usb_status.json'
$defT = Join-Path ([Environment]::GetFolderPath('MyDocuments')) '연락처보관'
function JP($a, $b) { if ($b) { return (Join-Path $a $b) } else { return $a } }
function Target { if (Test-Path $tf) { $t = (Get-Content $tf -Raw -Encoding UTF8).Trim(); if ($t) { return $t } }; return $defT }
$finder = {
  function JP($a, $b) { if ($b) { return (Join-Path $a $b) } else { return $a } }
  function FindCU($sh) {
    $r = @{ phone = ''; mtp = $false; cu = $null }
    foreach ($d in $sh.NameSpace(17).Items()) {
      if (-not $d.IsFolder) { continue }
      if ("$($d.Path)" -notmatch 'usb#|wpdbusenum|\\\\\?\\') { continue }   # 휴대폰 같은 '휴대용 장치'만
      $r.phone = $d.Name
      foreach ($st in $d.GetFolder.Items()) {
        $r.mtp = $true
        foreach ($x in $st.GetFolder.Items()) { if ($x.Name -eq 'Download') { foreach ($y in $x.GetFolder.Items()) { if ($y.Name -eq '묶인연락처풀기') { $r.cu = $y; return $r } } } }
      }
    }
    return $r
  }
}
. $finder
$sh = New-Object -ComObject Shell.Application
$job = $null; $last = $null; $seen = [DateTime]::Now
$copy = {
  param($T, $SF, $finderText)
  . ([ScriptBlock]::Create($finderText))
  function St($o) { [IO.File]::WriteAllText($SF, ($o | ConvertTo-Json -Compress), [Text.Encoding]::UTF8) }
  $sh = New-Object -ComObject Shell.Application
  $r = FindCU $sh
  if (-not $r.cu) { St @{ busy = $false; last = @{ ok = $false; msg = '휴대폰의 Download\묶인연락처풀기 폴더를 찾지 못했습니다' } }; return }
  $dst = Join-Path $T '묶인연락처풀기'; New-Item -ItemType Directory -Force -Path $dst | Out-Null
  St @{ busy = $true; done = 0; total = 0; msg = '휴대폰 파일 목록을 읽는 중…' }
  $list = New-Object System.Collections.ArrayList
  function Walk($f, $rel) { foreach ($it in $f.Items()) { if ($it.IsFolder) { Walk $it.GetFolder (JP $rel $it.Name) } else { [void]$list.Add(@{ it = $it; rel = $rel; name = $it.Name; size = [int64]("0" + $it.ExtendedProperty('System.Size')) }) } } }
  Walk $r.cu.GetFolder ''
  $todo = @($list | Where-Object { $p = Join-Path (JP $dst $_.rel) $_.name; -not (Test-Path -LiteralPath $p) -or ($_.size -gt 0 -and (Get-Item -LiteralPath $p).Length -ne $_.size) })
  $n = 0; $bad = 0; $t0 = [DateTime]::Now; $bytes = 0
  foreach ($f in $todo) {
    if (Test-Path (Join-Path $T '.stop')) { Remove-Item (Join-Path $T '.stop') -Force; St @{ busy = $false; last = @{ ok = $false; msg = "멈췄습니다. $n / $($todo.Count)개 복사. 다시 시작하면 남은 것만 복사합니다" } }; return }
    $dd = JP $dst $f.rel; New-Item -ItemType Directory -Force -Path $dd | Out-Null
    $p = Join-Path $dd $f.name
    if (Test-Path -LiteralPath $p) { Remove-Item -LiteralPath $p -Force }   # 크기가 다른 PC 쪽 파일만 지우고 다시 받는다(휴대폰은 그대로)
    $sh.NameSpace($dd).CopyHere($f.it, 4 + 16 + 512 + 1024)
    $w = 0; while ($w -lt 600) { Start-Sleep -Milliseconds 200; $w++; if ((Test-Path -LiteralPath $p) -and ($f.size -le 0 -or (Get-Item -LiteralPath $p).Length -eq $f.size)) { break } }
    $ok = Test-Path -LiteralPath $p
    if ($ok -and $f.name -match '^([0-9a-f]{64})') { $h = (Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash.ToLower(); if ($h -ne $Matches[1]) { $ok = $false } }   # 사진은 이름의 지문값과 바이트가 같은지
    if (-not $ok) { $bad++ } else { $bytes += $f.size }
    $n++; $sec = ([DateTime]::Now - $t0).TotalSeconds
    if ($n % 5 -eq 0 -or $n -eq $todo.Count) { St @{ busy = $true; done = $n; total = $todo.Count; msg = "복사하는 중 $n / $($todo.Count)개 ($([math]::Round($bytes/1MB,1))MB, 초당 $([math]::Round($bytes/1MB/[math]::Max($sec,0.1),1))MB)" + $(if ($bad) { " · 문제 $bad개" } else { '' }) } }
  }
  $msg = "휴대폰 파일 $($list.Count)개 중 PC에 없던 $($todo.Count)개를 복사했습니다" + $(if ($bad) { ". 문제 $bad개: 다시 시작하면 그것만 다시 복사합니다" } else { '. 사진은 모두 지문값까지 같습니다' })
  St @{ busy = $false; done = $n; total = $todo.Count; last = @{ ok = ($bad -eq 0); msg = $msg } }
}
function Reply($ctx, $obj) {
  $b = [Text.Encoding]::UTF8.GetBytes(($obj | ConvertTo-Json -Compress -Depth 4))
  $ctx.Response.Headers.Add('Access-Control-Allow-Origin', '*'); $ctx.Response.Headers.Add('Access-Control-Allow-Private-Network', 'true')
  $ctx.Response.ContentType = 'application/json; charset=utf-8'; $ctx.Response.OutputStream.Write($b, 0, $b.Length); $ctx.Response.Close()
}
while ($L.IsListening) {
  $a = $L.BeginGetContext($null, $null)
  while (-not $a.AsyncWaitHandle.WaitOne(1000)) { if (([DateTime]::Now - $seen).TotalMinutes -gt 30) { $L.Stop(); exit } }   # 프로그램 창이 30분 동안 안 물으면 끝
  $ctx = $L.EndGetContext($a); $seen = [DateTime]::Now
  $path = $ctx.Request.Url.AbsolutePath
  try {
    if ($ctx.Request.HttpMethod -eq 'OPTIONS') { Reply $ctx @{}; continue }
    if ($path -eq '/usb') {
      $r = FindCU $sh; $o = @{ ok = $true; phone = $r.phone; mtp = $r.mtp; found = [bool]$r.cu; target = (Target); targetNew = -not (Test-Path (Target)) }
      if (Test-Path $sf) { $st = Get-Content $sf -Raw -Encoding UTF8 | ConvertFrom-Json; $o.busy = [bool]$st.busy -and $job -and $job.State -eq 'Running'; $o.done = $st.done; $o.total = $st.total; $o.msg = $st.msg; if ($st.last) { $o.last = $st.last } }
      Reply $ctx $o
    } elseif ($path -eq '/pick') {
      Add-Type -AssemblyName System.Windows.Forms
      $fb = New-Object System.Windows.Forms.FolderBrowserDialog; $fb.Description = '휴대폰 백업을 보관할 PC 폴더를 골라 주세요'; $fb.SelectedPath = (Target); $fb.ShowNewFolderButton = $true
      $own = New-Object System.Windows.Forms.Form; $own.TopMost = $true
      if ($fb.ShowDialog($own) -eq 'OK') { [IO.File]::WriteAllText($tf, $fb.SelectedPath, [Text.Encoding]::UTF8); Reply $ctx @{ target = $fb.SelectedPath } } else { Reply $ctx @{ target = '' } }
      $own.Dispose()
    } elseif ($path -eq '/copy') {
      if (-not ($job -and $job.State -eq 'Running')) {
        $T = Target; New-Item -ItemType Directory -Force -Path $T | Out-Null; [IO.File]::WriteAllText($tf, $T, [Text.Encoding]::UTF8)
        Remove-Item (Join-Path $T '.stop') -Force; Remove-Item $sf -Force
        $job = Start-Job -ScriptBlock $copy -ArgumentList $T, $sf, $finder.ToString()
      }
      Reply $ctx @{ ok = $true }
    } elseif ($path -eq '/stop') { New-Item -ItemType File -Force -Path (Join-Path (Target) '.stop') | Out-Null; Reply $ctx @{ ok = $true }
    } else { Reply $ctx @{ ok = $false } }
  } catch { try { Reply $ctx @{ ok = $false; err = "$_" } } catch { } }
}
