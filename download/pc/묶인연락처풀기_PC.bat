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
# Ver0.90: 인터넷에서 받은 파일 표시(Zone.Identifier)를 지운다. 이 표시가 남아 있으면 바탕화면 아이콘을 누를 때마다
# "게시자를 확인하지 못했습니다… 실행하시겠습니까?" 보안 경고가 떴다. 이 프로그램이 만든 자기 파일만 지운다.
foreach ($uf in @($bat, $html, $ico, "$env:SELF")) { if ($uf -and (Test-Path -LiteralPath $uf)) { try { Unblock-File -LiteralPath $uf } catch { }; try { Remove-Item -LiteralPath $uf -Stream Zone.Identifier -Force -ErrorAction SilentlyContinue } catch { } } }
$ws = New-Object -ComObject WScript.Shell
foreach ($dir in @([Environment]::GetFolderPath('Desktop'), [Environment]::GetFolderPath('Programs'))) {
  $l = $ws.CreateShortcut((Join-Path $dir '묶인 연락처 풀기 PC.lnk'))
  $l.TargetPath = $bat; $l.WorkingDirectory = $D; $l.WindowStyle = 7
  if (Test-Path $ico) { $l.IconLocation = $ico }
  $l.Description = '묶인 연락처 풀기 PC판: 모바일 폰 연락처 백업을 PC에 보관하고 되돌리기'
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
# Ver0.73: 예전 판 도우미가 아직 돌고 있으면(새 기능이 없음) 끄고 새 도우미로 바꾼다. USB 복사 중이면 그대로 둔다.
try {
  $sfx = Join-Path $D 'usb_status.json'; $busy = $false
  if ((Test-Path $sfx) -and ((Get-Date) - (Get-Item $sfx).LastWriteTime).TotalMinutes -lt 2) { $busy = [bool]((Get-Content $sfx -Raw -Encoding UTF8 | ConvertFrom-Json).busy) }
  if (-not $busy) { Get-CimInstance Win32_Process -Filter "Name='powershell.exe'" | Where-Object { $_.CommandLine -like '*HELP==*' -and $_.ProcessId -ne $PID } | ForEach-Object { Stop-Process -Id $_.ProcessId -Force } }
} catch { }
$hc = "`$s=[IO.File]::ReadAllText('$bat',[Text.Encoding]::UTF8); `$m='#=='+'HELP=='; iex `$s.Substring(`$s.LastIndexOf(`$m)+`$m.Length)"
Start-Process -FilePath 'powershell.exe' -WindowStyle Hidden -ArgumentList @('-NoProfile','-ExecutionPolicy','Bypass','-WindowStyle','Hidden','-Command',$hc)
exit
#==HELP==
$ErrorActionPreference = 'SilentlyContinue'
$D = Join-Path $env:LOCALAPPDATA 'ContactUnlinkPC'
# ---------- Ver0.61: PC 도우미 (USB) ----------
# 프로그램 창(file://)이 http://localhost:8766 으로 묻는다: 모바일 폰이 USB로 꽂혔는지, 파일 전송이 켜졌는지, 지난번 보관 위치, 복사 진행.
# 복사는 모바일 폰 Download\묶인연락처풀기 → 보관 위치\묶인연락처풀기 로, PC에 없거나 크기가 다른 파일만. 모바일 폰 쪽은 읽기만 한다.
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
      if ("$($d.Path)" -notmatch 'usb#|wpdbusenum|\\\\\?\\') { continue }   # 모바일 폰 같은 '휴대용 장치'만
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
  if (-not $r.cu) { St @{ busy = $false; last = @{ ok = $false; msg = '모바일 폰의 Download\묶인연락처풀기 폴더를 찾지 못했습니다' } }; return }
  $dst = Join-Path $T '묶인연락처풀기'; New-Item -ItemType Directory -Force -Path $dst | Out-Null
  St @{ busy = $true; phase = 'list'; done = 0; total = 0; msg = '모바일 폰 파일 목록을 읽는 중…' }
  $list = New-Object System.Collections.ArrayList
  # Ver0.91: 단계마다(목록 읽기 → PC에 있는지 확인 → 복사 → 비교) 몇 개째인지 알려 막대와 %가 오르게 한다
  function Walk($f, $rel) { foreach ($it in $f.Items()) { if ($it.IsFolder) { Walk $it.GetFolder (JP $rel $it.Name) } else { [void]$list.Add(@{ it = $it; rel = $rel; name = $it.Name; size = [int64]("0" + $it.ExtendedProperty('System.Size')) }); if ($list.Count % 500 -eq 0) { St @{ busy = $true; phase = 'list'; done = $list.Count; total = 0; msg = "모바일 폰 파일 목록을 읽는 중: $($list.Count)개" } } } } }
  Walk $r.cu.GetFolder ''
  $todo = New-Object System.Collections.ArrayList; $ci = 0
  foreach ($x in $list) { $p = Join-Path (JP $dst $x.rel) $x.name; if (-not (Test-Path -LiteralPath $p) -or ($x.size -gt 0 -and (Get-Item -LiteralPath $p).Length -ne $x.size)) { [void]$todo.Add($x) }; $ci++; if ($ci % 500 -eq 0) { St @{ busy = $true; phase = 'check'; done = $ci; total = $list.Count; msg = "PC에 이미 있는지 확인하는 중: $ci / $($list.Count)개" } } }
  $n = 0; $bad = 0; $t0 = [DateTime]::Now; $bytes = 0
  foreach ($f in $todo) {
    if (Test-Path (Join-Path $T '.stop')) { Remove-Item (Join-Path $T '.stop') -Force; St @{ busy = $false; last = @{ ok = $false; msg = "멈췄습니다. $n / $($todo.Count)개 복사. 다시 시작하면 남은 것만 복사합니다" } }; return }
    $dd = JP $dst $f.rel; New-Item -ItemType Directory -Force -Path $dd | Out-Null
    $p = Join-Path $dd $f.name
    if (Test-Path -LiteralPath $p) { Remove-Item -LiteralPath $p -Force }   # 크기가 다른 PC 쪽 파일만 지우고 다시 받는다(모바일 폰은 그대로)
    $sh.NameSpace($dd).CopyHere($f.it, 4 + 16 + 512 + 1024)
    $w = 0; while ($w -lt 600) { Start-Sleep -Milliseconds 200; $w++; if ((Test-Path -LiteralPath $p) -and ($f.size -le 0 -or (Get-Item -LiteralPath $p).Length -eq $f.size)) { break } }
    $ok = Test-Path -LiteralPath $p
    if ($ok -and $f.name -match '^([0-9a-f]{64})') { $h = (Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash.ToLower(); if ($h -ne $Matches[1]) { $ok = $false } }   # 사진은 이름의 지문값과 바이트가 같은지
    if (-not $ok) { $bad++ } else { $bytes += $f.size }
    $n++; $sec = ([DateTime]::Now - $t0).TotalSeconds
    if ($n % 5 -eq 0 -or $n -eq $todo.Count) { St @{ busy = $true; phase = 'copy'; done = $n; total = $todo.Count; msg = "복사하는 중 $n / $($todo.Count)개 ($([math]::Round($bytes/1MB,1))MB, 초당 $([math]::Round($bytes/1MB/[math]::Max($sec,0.1),1))MB)" + $(if ($bad) { " · 문제 $bad개" } else { '' }) } }
  }
  # Ver0.71: 끝나면 모바일 폰 파일 목록과 PC 파일을 하나하나 비교한다(있는지, 크기가 같은지)
  St @{ busy = $true; phase = 'compare'; done = 0; total = $list.Count; msg = '모바일 폰과 PC를 비교하는 중…' }
  $match = 0; $ci = 0
  foreach ($x in $list) { $p = Join-Path (JP $dst $x.rel) $x.name; if ((Test-Path -LiteralPath $p) -and ($x.size -le 0 -or (Get-Item -LiteralPath $p).Length -eq $x.size)) { $match++ }; $ci++; if ($ci % 500 -eq 0) { St @{ busy = $true; phase = 'compare'; done = $ci; total = $list.Count; msg = "모바일 폰과 PC를 비교하는 중: $ci / $($list.Count)개" } } }
  $perfect = ($bad -eq 0) -and ($match -eq $list.Count)
  $msg = $(if ($perfect) { "완벽합니다. PC와 모바일 폰이 똑같습니다 (파일 $($list.Count)개 모두 같음, 새로 복사 $($todo.Count)개, 사진은 지문값까지 확인)" } else { "다른 것이 있습니다: 모바일 폰 $($list.Count)개 중 PC에 같은 것 $match개, 문제 $bad개. [예, 시작]을 다시 누르면 다른 것만 다시 복사합니다" })
  St @{ busy = $false; done = $n; total = $todo.Count; last = @{ ok = $perfect; msg = $msg; files = $list.Count; match = $match; copied = $todo.Count } }
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
      if (Test-Path $sf) { $st = Get-Content $sf -Raw -Encoding UTF8 | ConvertFrom-Json; $o.busy = [bool]$st.busy -and $job -and $job.State -eq 'Running'; $o.phase = $st.phase; $o.done = $st.done; $o.total = $st.total; $o.msg = $st.msg; if ($st.last) { $o.last = $st.last } }
      Reply $ctx $o
    } elseif ($path -eq '/pick') {
      Add-Type -AssemblyName System.Windows.Forms
      $fb = New-Object System.Windows.Forms.FolderBrowserDialog; $fb.Description = '모바일 폰 백업을 보관할 PC 폴더를 골라 주세요'; $fb.SelectedPath = (Target); $fb.ShowNewFolderButton = $true
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
    } elseif ($path -eq '/open' -or $path -eq '/where') {
      # Ver0.73/0.86: 보관 폴더를 찾아 윈도우 탐색기로 연다(/where 는 경로만 알려 줌). u=1 이면 USB 보관 위치, 아니면 프로그램 창이 고른 폴더(표시 파일 m, 폴더 이름 n 으로 찾음).
      # Ver0.86 고침: HttpListener 의 QueryString 은 한글 주소를 윈도우 기본 글자(CP949)로 풀어 깨졌다 → 주소를 UTF-8로 직접 푼다. 표시 파일 이름도 영문으로.
      $q = @{}; foreach ($kv in $ctx.Request.Url.Query.TrimStart('?').Split('&')) { $e = $kv.IndexOf('='); if ($e -gt 0) { $q[$kv.Substring(0, $e)] = [Uri]::UnescapeDataString($kv.Substring($e + 1).Replace('+', ' ')) } }
      $dir = ''
      if ($q['u']) { $dir = Target; New-Item -ItemType Directory -Force -Path $dir | Out-Null }
      else {
        $m = "$($q['m'])"; $n = "$($q['n'])"; $rf = Join-Path $D 'root_path.txt'
        if ($m -match '^_cu_mark_[a-z0-9]+\.txt$') {
          if (Test-Path $rf) { $c = (Get-Content $rf -Raw -Encoding UTF8).Trim(); if ($c -and (Test-Path -LiteralPath (Join-Path $c $m))) { $dir = $c } }
          $roots = @([Environment]::GetFolderPath('MyDocuments'), [Environment]::GetFolderPath('Desktop'), [Environment]::GetFolderPath('UserProfile')) + @(Get-PSDrive -PSProvider FileSystem | Where-Object { $_.Root -and $_.Free -ne $null } | ForEach-Object { $_.Root })
          $roots = @($roots | Where-Object { $_ } | Select-Object -Unique)
          if (-not $dir) { foreach ($r0 in $roots) { $hit = Get-ChildItem -LiteralPath $r0 -Filter $m -File -Recurse -Depth 6 -Force -ErrorAction SilentlyContinue | Select-Object -First 1; if ($hit) { $dir = $hit.DirectoryName; break } } }
          # 표시 파일을 못 찾으면, 같은 이름이면서 안에 묶인연락처풀기 폴더가 있는 폴더를 찾는다
          if (-not $dir -and $n) { foreach ($r0 in $roots) { $hit = Get-ChildItem -LiteralPath $r0 -Directory -Recurse -Depth 5 -Force -ErrorAction SilentlyContinue | Where-Object { $_.Name -eq $n -and (Test-Path -LiteralPath (Join-Path $_.FullName '묶인연락처풀기')) } | Select-Object -First 1; if ($hit) { $dir = $hit.FullName; break } } }
          if ($dir) { [IO.File]::WriteAllText($rf, $dir, [Text.Encoding]::UTF8) }
        }
      }
      if ($dir -and (Test-Path -LiteralPath $dir)) {
        $root = $dir; $in = Join-Path $dir '묶인연락처풀기'; if (Test-Path -LiteralPath $in) { $dir = $in }   # 백업이 실제로 든 안쪽 폴더를 연다
        if ($path -eq '/open') { Start-Process -FilePath 'explorer.exe' -ArgumentList ('"' + $dir + '"') }
        Reply $ctx @{ ok = $true; path = $dir; root = $root }
      } else { Reply $ctx @{ ok = $false; why = 'notfound' } }
    } elseif ($path -eq '/stop') { New-Item -ItemType File -Force -Path (Join-Path (Target) '.stop') | Out-Null; Reply $ctx @{ ok = $true }
    } else { Reply $ctx @{ ok = $false } }
  } catch { try { Reply $ctx @{ ok = $false; err = "$_" } } catch { } }
}
