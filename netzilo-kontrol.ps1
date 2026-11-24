# Netzilo kontrol - SADECE OKUR, hicbir seyi degistirmez. Anahtar/token yazdirmaz.
# Calistirma:  irm https://raw.githubusercontent.com/rsemihkoca/scripts/main/netzilo-kontrol.ps1 | iex

& {
$ErrorActionPreference = 'SilentlyContinue'
$nz  = 'C:\ProgramData\Netzilo'
$cli = 'C:\ProgramData\Netzilo Client\netzilo.exe'

function Show($label, $value, $ok) {
    $color = if ($ok -eq $true) { 'Green' } elseif ($ok -eq $false) { 'Red' } else { 'Gray' }
    Write-Host ('{0,-15}: ' -f $label) -NoNewline
    Write-Host $value -ForegroundColor $color
}

Write-Host ''
Write-Host ("=== Netzilo Kontrol | {0} | {1} ===" -f $env:COMPUTERNAME, (Get-Date -Format 'yyyy-MM-dd HH:mm')) -ForegroundColor Cyan

# Surum
$ver = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*','HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*' |
        Where-Object DisplayName -match 'Netzilo' | Select-Object -First 1).DisplayVersion
if (-not $ver) { Show 'Netzilo' 'KURULU DEGIL' $false; Write-Host ''; return }

$st = (& $cli status 2>&1 | Out-String)
function Get-Field($name) { if ($st -match "(?m)^$name\s*:\s*(.+)$") { $Matches[1].Trim() } else { '?' } }
$daemon = Get-Field 'Daemon version'
Show 'Surum' "$ver (daemon $daemon)"

# Servisler
$svc = Get-Service Netzilo, NtzlSvc
$svcOk = (@($svc | Where-Object Status -ne 'Running').Count -eq 0) -and (@($svc).Count -eq 2)
Show 'Servisler' (($svc | ForEach-Object { "$($_.Name)=$($_.Status)" }) -join ', ') $svcOk

# Baglanti
$mgmt = Get-Field 'Management'; $sig = Get-Field 'Signal'; $peers = Get-Field 'Peers count'
$peerOk = $peers -match '^(\d+)/(\d+)' -and [int]$Matches[2] -gt 0 -and $Matches[1] -eq $Matches[2]
Show 'Baglanti' "Management=$mgmt, Signal=$sig, Peers=$peers" ($mgmt -eq 'Connected' -and $sig -eq 'Connected' -and $peerOk)

# Cihaz kaydi
$fqdn = (Get-Field 'FQDN') -replace '\.netzilo\.network$', ''
Show 'Cihaz adi' $fqdn
$regs = @(Select-String -Path "$nz\client.log" -Pattern 'engine started, FQDN: ([^ ]+?)\.netzilo\.network' |
          ForEach-Object { $_.Matches[0].Groups[1].Value } | Select-Object -Unique)
Show 'Kayit sayisi' ("{0}  ({1})" -f $regs.Count, ($regs -join ', ')) ($regs.Count -le 1)

# Workspace Apps klasoru
$desktops = @([Environment]::GetFolderPath('Desktop'), [Environment]::GetFolderPath('CommonDesktopDirectory')) +
            @(Get-ChildItem $env:USERPROFILE -Directory -Filter 'OneDrive*' | ForEach-Object { Join-Path $_.FullName 'Desktop' })
$ws = $desktops | Where-Object { $_ -and (Test-Path $_) } |
      ForEach-Object { Get-ChildItem $_ -Directory -Force | Where-Object Name -match 'Workspace' } | Select-Object -First 1
if ($ws) {
    $items = @(Get-ChildItem $ws.FullName -Force)
    Show 'Workspace Apps' ("VAR, {0} kisayol: {1}" -f $items.Count, (($items | ForEach-Object BaseName) -join ', ')) $true
    $lnk = $items | Where-Object Extension -eq '.lnk' | Select-Object -First 1
    if ($lnk) { $l = (New-Object -ComObject WScript.Shell).CreateShortcut($lnk.FullName); Show 'Ornek kisayol' "$($l.TargetPath) $($l.Arguments)" }
} else {
    Show 'Workspace Apps' 'YOK' $false
}
$wsLog = @(Select-String -Path "$nz\client.log" -Pattern 'workspace|container|sandbox|nzfs').Count
Show 'Workspace log' "$wsLog satir" ($wsLog -gt 0)

# Installer + config indirme
$inst = Get-Content "$nz\netzilo_offline_nsis_install.log" -Raw
if ($inst) {
    $runs = $inst -split '--- Installation Log ---' | Where-Object { $_ -match 'Installer:' }
    foreach ($r in $runs) {
        $name = if ($r -match 'Installer:\s*"([^"]+)"') { Split-Path $Matches[1] -Leaf } else { '?' }
        $res  = if ($r -match '(?m)^download config\.json (?!from)(\S+)') { $Matches[1] } else { '?' }
        Show 'Installer' "$name -> config $res" ($res -ne 'FAIL')
    }
} else { Show 'Installer' 'log yok' }

Write-Host ''
}
