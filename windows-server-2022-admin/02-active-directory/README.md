# Phase 02 : Active Directory Domain Services

## Objectif

Transformer DC01 en contrôleur de domaine, créer la forêt `doumbiacorp.local`, puis construire l'annuaire de DoumbiaCorp : unités d'organisation (OU), groupes, utilisateurs (un à la main, puis en masse depuis un CSV).

## Concepts

| Terme | Définition |
|---|---|
| **AD DS** | Rôle Windows Server qui fournit l'annuaire centralisé (comptes, machines, groupes) |
| **Domaine / forêt** | Le domaine est la frontière de gestion et de sécurité ; la forêt regroupe un ou plusieurs domaines. Ici : une forêt, un domaine |
| **Contrôleur de domaine (DC)** | Serveur qui héberge l'annuaire et authentifie les utilisateurs |
| **OU** | Dossier de l'annuaire, sert à **gérer** (GPO, délégation). Un objet est dans une seule OU |
| **Groupe** | Sert à **autoriser** (permissions). Un objet peut être dans plusieurs groupes |
| **AGDLP** | Accounts, Global, Domain Local, Permissions : méthode standard d'attribution des droits (la partie DL est mise en place en phase 05) |
| **DNS et SRV** | AD stocke dans le DNS des enregistrements SRV qui indiquent où se trouve le contrôleur ; le DNS de DC01 doit donc pointer vers lui-même |
| **Kerberos** | Protocole d'authentification ; refuse les échanges si l'écart d'horloge dépasse 5 minutes |
| **NTDS.dit / SYSVOL** | Base de l'annuaire (très sensible) et dossier partagé qui distribue GPO et scripts |
| **DSRM** | Mot de passe de secours de l'annuaire, demandé à la promotion |

## Prérequis

- Phase 01 validée, snapshot VMware `Phase01-OK`
- DC01 : nom `DC01`, IP `192.168.10.10/24`, heure correcte, aucun redémarrage en attente

## Procédure

### 1. Contrôles avant promotion

```powershell
hostname
Get-NetIPAddress -InterfaceAlias "Ethernet" -AddressFamily IPv4 | Select-Object IPAddress, PrefixLength
Get-Date
Test-Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending'
```

Résultat : `DC01`, `192.168.10.10 / 24`, heure cohérente, `False`.

### 2. Installation du rôle

```powershell
Get-WindowsFeature AD-Domain-Services
Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools
Get-WindowsFeature AD-Domain-Services
```

Avant : `[ ] Available`. Résultat : `Success True`, `Restart Needed No`. Après : `[X] Installed`. Le rôle est installé mais DC01 reste en `WORKGROUP`.

### 3. Promotion en contrôleur de domaine

Le mot de passe DSRM est saisi à l'invite, jamais écrit dans une commande ni dans un fichier :

```powershell
$dsrm = Read-Host -Prompt "Mot de passe DSRM" -AsSecureString

$params = @{
    DomainName                    = "doumbiacorp.local"
    DomainNetbiosName             = "DOUMBIACORP"
    ForestMode                    = "WinThreshold"
    DomainMode                    = "WinThreshold"
    InstallDns                    = $true
    DatabasePath                  = "C:\Windows\NTDS"
    LogPath                       = "C:\Windows\NTDS"
    SysvolPath                    = "C:\Windows\SYSVOL"
    SafeModeAdministratorPassword = $dsrm
}

Test-ADDSForestInstallation @params
Install-ADDSForest @params
```

`WinThreshold` correspond au niveau fonctionnel 2016, le plus élevé disponible. Le test préalable ne modifie rien : `Status : Success`, avec deux avertissements attendus (algorithmes de chiffrement NT 4.0 désactivés par défaut, et délégation DNS impossible car `.local` n'a pas de zone parente). Snapshot `Phase01-OK` pris avant la promotion. Redémarrage automatique, puis connexion avec `DOUMBIACORP\Administrateur`.

![Test de promotion](../assets/02-test-promotion.png)
![Écran de connexion](../assets/02-connexion-domaine.png)

### 4. Vérification du domaine

```powershell
Get-Service NTDS, DNS, Netlogon, KDC, ADWS | Select-Object Name, Status
Get-ADDomain | Select-Object Name, DNSRoot, NetBIOSName, DomainMode, PDCEmulator
Get-ADForest | Select-Object Name, ForestMode, SchemaMaster, DomainNamingMaster
Get-ADDomainController | Select-Object Name, IPv4Address, IsGlobalCatalog, OperatingSystem
```

| Contrôle | Résultat |
|---|---|
| Services | Les 5 `Running` |
| Domaine | `doumbiacorp.local`, `DOUMBIACORP`, `Windows2016Domain`, PDC `DC01` |
| Forêt | `Windows2016Forest`, schéma et nommage sur DC01 |
| Contrôleur | DC01, `192.168.10.10`, catalogue global `True` |

Avec un seul contrôleur, DC01 porte tous les rôles FSMO.

### 5. DNS : DC01 pointe vers lui-même

```powershell
Get-DnsClientServerAddress -InterfaceAlias "Ethernet" -AddressFamily IPv4
Set-DnsClientServerAddress -InterfaceAlias "Ethernet" -ServerAddresses 192.168.10.10
Get-DnsServerForwarder
```

Après la promotion, le DNS client était `127.0.0.1` ; réglé sur `192.168.10.10`. Le redirecteur `8.8.8.8` était déjà configuré (hérité de l'ancien DNS) : pas ajouté en double.

```powershell
Resolve-DnsName doumbiacorp.local
Resolve-DnsName _ldap._tcp.dc._msdcs.doumbiacorp.local -Type SRV
Resolve-DnsName google.com
ping google.com
```

Résultat : `doumbiacorp.local` vers `192.168.10.10` ; enregistrement SRV vers `dc01.doumbiacorp.local`, port 389 (LDAP) ; noms d'Internet résolus via le redirecteur, ping 0 % de perte.

### 6. Diagnostic `dcdiag`

```powershell
dcdiag /q
dcdiag
```

Tous les tests réussis sauf `DFSREvent` (voir dépannage 007). `SysVolCheck`, `NetLogons`, `Advertising`, `Replications` : réussis. Partages `SYSVOL` et `NETLOGON` présents.

Snapshot VMware `Phase02a-DC-OK`.

### 7. Structure d'OU

```
doumbiacorp.local
└── DoumbiaCorp
    ├── Utilisateurs  (RH, Finance, IT)
    ├── Ordinateurs   (Postes, Serveurs)
    ├── Groupes
    └── Administration
```

```powershell
$base = (Get-ADDomain).DistinguishedName
New-ADOrganizationalUnit -Name "DoumbiaCorp" -Path $base -Description "OU racine de l'entreprise"
$racine = "OU=DoumbiaCorp,$base"

foreach ($ou in "Utilisateurs","Ordinateurs","Groupes","Administration") {
    New-ADOrganizationalUnit -Name $ou -Path $racine
}
foreach ($ou in "RH","Finance","IT") {
    New-ADOrganizationalUnit -Name $ou -Path "OU=Utilisateurs,$racine"
}
foreach ($ou in "Postes","Serveurs") {
    New-ADOrganizationalUnit -Name $ou -Path "OU=Ordinateurs,$racine"
}
```

Le parent est créé avant les enfants. Résultat : 10 OU, toutes protégées contre la suppression accidentelle (`ProtectedFromAccidentalDeletion = True`). Avant : seule l'OU par défaut `Domain Controllers`.

![Arbre des OU](../assets/02-dsa-ou.png)

### 8. Groupes globaux (le « G » d'AGDLP)

```powershell
foreach ($g in "RH","Finance","IT") {
    New-ADGroup -Name "GG_$g" -SamAccountName "GG_$g" -GroupScope Global -GroupCategory Security -Path "OU=Groupes,$racine" -Description "Utilisateurs du service $g"
}
```

Résultat : `GG_RH`, `GG_Finance`, `GG_IT`, étendue `Global`, catégorie `Security`.

### 9. Premier utilisateur, à la main

```powershell
$mdp = Read-Host -Prompt "Mot de passe initial de l'utilisateur" -AsSecureString

$user = @{
    Name                  = "Awa Traore"
    GivenName             = "Awa"
    Surname               = "Traore"
    DisplayName           = "Awa Traore"
    SamAccountName        = "awa.traore"
    UserPrincipalName     = "awa.traore@doumbiacorp.local"
    Path                  = "OU=RH,OU=Utilisateurs,$racine"
    Department            = "RH"
    Title                 = "Assistant RH"
    AccountPassword       = $mdp
    ChangePasswordAtLogon = $true
    Enabled               = $true
}
New-ADUser @user
Add-ADGroupMember -Identity "GG_RH" -Members "awa.traore"
```

Points clés : un compte créé en PowerShell est **désactivé par défaut** (`Enabled = $true` est nécessaire) ; `-Path` place le compte dans l'OU voulue (sinon il atterrit dans le conteneur `Users`) ; `ChangePasswordAtLogon` impose le choix d'un mot de passe personnel.

Vérification : `Enabled = True`, chemin `CN=Awa Traore,OU=RH,OU=Utilisateurs,...`, membre de `GG_RH` et `Utilisateurs du domaine`.

![Propriétés d'Awa Traore](../assets/02-awa-traore.png)

### 10. Création en masse depuis un CSV

Fichiers : [`../data/utilisateurs.csv`](../data/utilisateurs.csv) (20 employés fictifs, sans mot de passe) et [`../scripts/New-DoumbiaUsers.ps1`](../scripts/New-DoumbiaUsers.ps1).

```powershell
C:\Scripts\New-DoumbiaUsers.ps1
```

Fonctionnement : lecture du CSV, création du compte dans l'OU de son service, ajout au groupe `GG_<service>`, compteurs et résumé. Les comptes existants sont ignorés ; chaque erreur est capturée par `try/catch` sans arrêter le reste ; le mot de passe est demandé à l'exécution.

| Exécution | Résultat |
|---|---|
| 1re (Awa existait déjà) | `19 cree(s), 1 ignore(s), 0 erreur(s)` |
| 2e (idempotence) | `0 cree(s), 20 ignore(s), 0 erreur(s)` |

Vérification : RH 5, Finance 7, IT 8 utilisateurs ; `GG_RH` 5, `GG_Finance` 7, `GG_IT` 8 membres.

![Exécution du script](../assets/02-script-execution.png)
![Utilisateurs de l'OU IT](../assets/02-dsa-it.png)

## Problèmes rencontrés et solutions

Voir [../docs/troubleshooting.md](../docs/troubleshooting.md) : 007 (`DFSREvent`), 008 (`PositionalParameterNotFound` avec `$null`), 009 (arrêt brutal de DC01) et 010 (collage dans la console de la VM).

## Choix de lab et limites

- Nom de domaine en `.local` : simple en lab ; en production, on préfère un sous-domaine d'un nom que l'on possède (ex. `ad.exemple.com`).
- Même mot de passe initial pour tous les comptes créés par le script : simplification de lab ; en production, un mot de passe temporaire distinct par compte.
- Un seul contrôleur de domaine : pas de redondance (un deuxième DC est prévu en phase 09).
- Mots de passe de lab (DSRM, comptes) : jamais dans le dépôt.

## Bonnes pratiques

- Lire (`Get-`) avant de modifier ; tester (`Test-ADDSForestInstallation`) avant d'installer.
- Un snapshot VMware avant les opérations difficiles à annuler (promotion).
- Éteindre les serveurs avec `Stop-Computer`, jamais brutalement.
- Ranger les objets dans des OU dédiées, pas dans les conteneurs par défaut.
