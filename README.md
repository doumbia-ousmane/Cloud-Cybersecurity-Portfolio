# Cloud-Cybersecurity-Portfolio


New-Item -Path C:\Scripts, C:\Rapports -ItemType Directory -Force | Out-Null

@'
$horodatage = Get-Date -Format "yyyy-MM-dd_HH-mm"
$fichier = "C:\Rapports\bilan-$($env:COMPUTERNAME)-$horodatage.txt"
$lignes = New-Object System.Collections.Generic.List[string]
function Ajouter($texte) { $lignes.Add($texte) }

$os = Get-CimInstance Win32_OperatingSystem
$heures = [int]((Get-Date) - $os.LastBootUpTime).TotalHours
$ram = [math]::Round(100 * $os.FreePhysicalMemory / $os.TotalVisibleMemorySize, 1)
$cpu = [math]::Round((Get-CimInstance Win32_Processor | Measure-Object LoadPercentage -Average).Average, 1)

Ajouter "BILAN DE SANTE - $($env:COMPUTERNAME) - $(Get-Date -Format 'dd/MM/yyyy HH:mm')"
Ajouter "Demarre depuis : $heures h"
Ajouter "Charge processeur : $cpu %"
Ajouter "Memoire libre : $ram %"
Ajouter "Disques :"
foreach ($d in Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3") {
    $libre = [math]::Round(100 * $d.FreeSpace / $d.Size, 1)
    Ajouter ("  {0} {1} % libre ({2} Go sur {3} Go)" -f $d.DeviceID, $libre, [math]::Round($d.FreeSpace/1GB,1), [math]::Round($d.Size/1GB,1))
}
$arretes = @(Get-CimInstance Win32_Service -Filter "StartMode='Auto' AND State<>'Running'")
Ajouter "Services automatiques arretes : $($arretes.Count)"
foreach ($s in $arretes) { Ajouter "  - $($s.Name)" }
$echecs = @(Get-WinEvent -FilterHashtable @{LogName='Security'; Id=4625; StartTime=(Get-Date).AddHours(-24)} -ErrorAction SilentlyContinue)
Ajouter "Echecs d'ouverture de session (24 h) : $($echecs.Count)"
$partages = @(Get-SmbShare -ErrorAction SilentlyContinue | Where-Object { -not $_.Special })
Ajouter "Partages : $($partages.Count)"
foreach ($p in $partages) { Ajouter "  - $($p.Name) -> $($p.Path)" }

$lignes | Out-File $fichier -Encoding utf8
$lignes
Get-ChildItem C:\Rapports -Filter "bilan-*.txt" | Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-30) } | Remove-Item
'@ | Set-Content C:\Scripts\Get-Bilan.ps1 -Encoding UTF8

powershell.exe -NoProfile -ExecutionPolicy Bypass -File C:\Scripts\Get-Bilan.ps1
