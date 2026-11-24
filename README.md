# scripts

Paylaşmak için küçük, tek komutla çalışan script'ler.

## Kullanım

PowerShell'i aç ve script'in komutunu yapıştır:

```powershell
irm https://raw.githubusercontent.com/rsemihkoca/scripts/main/<dosya>.ps1 | iex
```

## Script'ler

| Script | Ne yapar | Komut |
|---|---|---|
| `netzilo-kontrol.ps1` | Netzilo kurulumunu ve "Workspace Apps" klasörünü kontrol eder. Sadece okur, hiçbir şeyi değiştirmez; çıktıyı panoya kopyalar. | `irm https://raw.githubusercontent.com/rsemihkoca/scripts/main/netzilo-kontrol.ps1 \| iex` |
