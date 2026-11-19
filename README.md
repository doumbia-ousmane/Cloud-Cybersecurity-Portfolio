# Cloud-Cybersecurity-Portfolio


@'
$horodatage = Get-Date -Format "yyyy-MM-dd_HH-mm";
$fichier = "C:\Rapports\bilan-$($env:COMPUTERNAME)-$horodatage.txt";
$lignes = New-Object System.Collections.Generic.List[string];
function Ajouter($texte) { $lignes.Add($texte) };

$os = Get-CimInstance Win32_OperatingSystem;
$heures = [int]((Get-Date) - $os.LastBootUpTime).TotalHours;
$ram = [math]::Round(100 * $os.FreePhysicalMemory / $os.TotalVisibleMemorySize, 1);
$cpu = [math]::Round((Get-CimInstance Win32_Processor | Measure-Object LoadPercentage -Average).Average, 1);

Ajouter "BILAN DE SANTE - $($env:COMPUTERNAME) - $(Get-Date -Format 'dd/MM/yyyy HH:mm')";
Ajouter "Demarre depuis : $heures h";
Ajouter "Charge processeur : $cpu %";
Ajouter "Memoire libre : $ram %";
Ajouter "Disques :";
foreach ($d in Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3") {
    $libre = [math]::Round(100 * $d.FreeSpace / $d.Size, 1);
    Ajouter ("  {0} {1} % libre ({2} Go sur {3} Go)" -f $d.DeviceID, $libre, [math]::Round($d.FreeSpace/1GB,1), [math]::Round($d.Size/1GB,1));
};

try {
    $arretes = New-Object System.Collections.Generic.List[string];
    foreach ($s in Get-CimInstance Win32_Service -ErrorAction Stop) {
        if (($s.StartMode -eq 'Auto') -and ($s.State -ne 'Running')) { $arretes.Add($s.Name) };
    };
    Ajouter "Services automatiques arretes : $($arretes.Count)";
    foreach ($n in $arretes) { Ajouter "  - $n" };
} catch {
    Ajouter "Services automatiques arretes : ERREUR de lecture";
};

try {
    $echecs = @(Get-WinEvent -FilterHashtable @{LogName='Security'; Id=4625; StartTime=(Get-Date).AddHours(-24)} -ErrorAction Stop);
    Ajouter "Echecs d'ouverture de session (24 h) : $($echecs.Count)";
} catch {
    if ($Error[0].FullyQualifiedErrorId -like 'NoMatchingEventsFound*') {
        Ajouter "Echecs d'ouverture de session (24 h) : 0";
    } else {
        Ajouter "Echecs d'ouverture de session (24 h) : ERREUR de lecture du journal";
    };
};

try {
    $liste = New-Object System.Collections.Generic.List[string];
    foreach ($p in Get-SmbShare -ErrorAction Stop) {
        if (-not $p.Special) { $liste.Add("  - $($p.Name) : $($p.Path)") };
    };
    Ajouter "Partages : $($liste.Count)";
    foreach ($l in $liste) { Ajouter $l };
} catch {
    Ajouter "Partages : ERREUR de lecture";
};

$lignes | Out-File $fichier -Encoding utf8;
$lignes;
foreach ($f in Get-ChildItem C:\Rapports -Filter "bilan-*.txt") {
    if ($f.LastWriteTime -lt (Get-Date).AddDays(-30)) { Remove-Item $f.FullName };
};
'@ | Set-Content C:\Scripts\Get-Bilan.ps1 -Encoding UTF8

powershell.exe -NoProfile -ExecutionPolicy Bypass -File C:\Scripts\Get-Bilan.ps1
