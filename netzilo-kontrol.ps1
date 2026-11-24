# Netzilo "Workspace Apps" karsilastirma - SADECE OKUR, hicbir seyi degistirmez.
# Anahtar/token yazdirmaz. Cikti otomatik panoya kopyalanir.
# Calistirma:  irm https://raw.githubusercontent.com/rsemihkoca/scripts/main/netzilo-kontrol.ps1 | iex

$__nzOut = & {
$ErrorActionPreference = 'SilentlyContinue'
$nz = 'C:\ProgramData\Netzilo'

"===== Netzilo surumu ====="
(Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*','HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*' |
    Where-Object DisplayName -match 'Netzilo' | Select-Object -First 1).DisplayVersion

"===== Baglanti durumu ====="
& 'C:\ProgramData\Netzilo Client\netzilo.exe' status 2>&1 |
    Select-String 'version|Management|Signal|Peers count|Netzilo IP'

"===== Workspace Apps klasoru ====="
$desktops = @([Environment]::GetFolderPath('Desktop'), [Environment]::GetFolderPath('CommonDesktopDirectory')) +
    (Get-ChildItem $env:USERPROFILE -Directory -Filter 'OneDrive*' | ForEach-Object { Join-Path $_.FullName 'Desktop' })
$found = $false
foreach ($d in $desktops | Where-Object { $_ -and (Test-Path $_) }) {
    Get-ChildItem $d -Directory -Force | Where-Object Name -match 'Workspace' | ForEach-Object {
        $found = $true
        "Bulundu: $($_.FullName)  (olusma: $($_.CreationTime))"
        $sh = New-Object -ComObject WScript.Shell
        Get-ChildItem $_.FullName -Force | ForEach-Object {
            if ($_.Extension -eq '.lnk') { $l = $sh.CreateShortcut($_.FullName); "  $($_.Name) -> $($l.TargetPath) $($l.Arguments)" }
            else { "  $($_.Name)" }
        }
    }
}
if (-not $found) { "YOK" }

"===== Ek suruculer / diskler ====="
Get-PSDrive -PSProvider FileSystem | ForEach-Object { "$($_.Name): $($_.Description)" }

"===== Kurulum logu (hangi installer, config indi mi) ====="
Get-Content "$nz\netzilo_offline_nsis_install.log"

"===== client.log icinde workspace izleri ====="
$hits = Select-String -Path "$nz\client.log" -Pattern 'workspace|container|sandbox|nzfs|desktop folder|shortcut'
"Eslesen satir: $(@($hits).Count)"
$hits | Select-Object -Last 15 | ForEach-Object { $_.Line.Substring(0, [Math]::Min(200, $_.Line.Length)) }

"===== Kayit (FQDN) gecmisi ====="
Select-String -Path "$nz\client.log" -Pattern 'engine started, FQDN' |
    ForEach-Object { $_.Line.Substring(0, [Math]::Min(160, $_.Line.Length)) }
} 2>&1 | Out-String

$__nzOut
try { $__nzOut | Set-Clipboard; '>> Cikti panoya kopyalandi. Direkt yapistirip gonderebilirsin.' } catch { '>> Panoya kopyalanamadi, ustteki ciktiyi elle kopyala.' }
