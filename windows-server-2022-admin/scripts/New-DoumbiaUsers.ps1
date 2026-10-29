<#
.SYNOPSIS
    Cree en masse les utilisateurs de DoumbiaCorp depuis un fichier CSV.
.DESCRIPTION
    Pour chaque ligne du CSV : cree le compte dans l'OU de son service,
    l'active, puis l'ajoute au groupe GG_<service>.
    Les comptes deja existants sont ignores (le script peut etre relance).
    Le mot de passe initial est demande a l'execution : il n'est jamais
    ecrit dans un fichier.
.PARAMETER CsvPath
    Chemin du fichier CSV (colonnes : Prenom, Nom, Departement, Titre).
#>
[CmdletBinding()]
param(
    [string]$CsvPath = "C:\Scripts\utilisateurs.csv"
)

Import-Module ActiveDirectory

$domaine = Get-ADDomain
$racine  = "OU=DoumbiaCorp,$($domaine.DistinguishedName)"
$mdp     = Read-Host -Prompt "Mot de passe initial (a changer a la 1re connexion)" -AsSecureString

$crees = 0; $ignores = 0; $erreurs = 0

foreach ($u in Import-Csv -Path $CsvPath) {
    $sam = ("{0}.{1}" -f $u.Prenom, $u.Nom).ToLower()

    if (Get-ADUser -Filter "SamAccountName -eq '$sam'") {
        Write-Host "[IGNORE] $sam existe deja" -ForegroundColor Yellow
        $ignores++
        continue
    }

    try {
        $params = @{
            Name                  = "$($u.Prenom) $($u.Nom)"
            GivenName             = $u.Prenom
            Surname               = $u.Nom
            DisplayName           = "$($u.Prenom) $($u.Nom)"
            SamAccountName        = $sam
            UserPrincipalName     = "$sam@$($domaine.DNSRoot)"
            Path                  = "OU=$($u.Departement),OU=Utilisateurs,$racine"
            Department            = $u.Departement
            Title                 = $u.Titre
            AccountPassword       = $mdp
            ChangePasswordAtLogon = $true
            Enabled               = $true
        }
        New-ADUser @params -ErrorAction Stop
        Add-ADGroupMember -Identity "GG_$($u.Departement)" -Members $sam -ErrorAction Stop
        Write-Host "[CREE]   $sam -> OU $($u.Departement), groupe GG_$($u.Departement)" -ForegroundColor Green
        $crees++
    }
    catch {
        Write-Host "[ERREUR] $sam : $($_.Exception.Message)" -ForegroundColor Red
        $erreurs++
    }
}

Write-Host ""
Write-Host "Termine : $crees cree(s), $ignores ignore(s), $erreurs erreur(s)."
