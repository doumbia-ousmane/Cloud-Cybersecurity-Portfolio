# Phase 03 : DHCP et jonction d'un poste au domaine

## Objectif

Distribuer automatiquement les paramètres réseau aux postes du LAN (DHCP), puis vérifier toute la chaîne en joignant un poste Windows 10 (`CL01`) au domaine `doumbiacorp.local`.

## Concepts

| Notion | Explication |
|---|---|
| **DORA** | Les 4 échanges d'une demande DHCP : *Discover*, *Offer*, *Request*, *Acknowledge* |
| **Étendue** (*scope*) | Plage d'adresses distribuées : `192.168.10.100` à `192.168.10.200` |
| **Bail** (*lease*) | Durée pendant laquelle un client garde son adresse (8 jours) |
| **Options** | Paramètres donnés avec l'IP : 3 (passerelle), 6 (serveurs DNS), 15 (nom de domaine) |
| **Autorisation dans AD** | Un serveur DHCP doit être autorisé dans l'annuaire pour répondre (protection contre les serveurs pirates) |
| **APIPA** | Adresse `169.254.x.x` attribuée par Windows en l'absence de réponse DHCP |
| **Jonction au domaine** | Création d'un compte ordinateur dans l'annuaire et établissement d'un canal sécurisé avec le contrôleur |

L'option 6 donne aux clients le DNS `192.168.10.10`, indispensable pour qu'ils localisent le domaine (enregistrements SRV).

## Prérequis

- Phase 02 validée (domaine, OU, groupes, utilisateurs)
- Aucun autre serveur DHCP sur le LAN : le MikroTik n'en exécute pas sur `ether2`, le nœud NAT de GNS3 ne distribue que sur le réseau `192.168.42.0/24`, côté Internet

## Procédure

### 1. Installation du rôle DHCP et autorisation

```powershell
Install-WindowsFeature -Name DHCP -IncludeManagementTools
Add-DhcpServerInDC -DnsName "dc01.doumbiacorp.local" -IPAddress 192.168.10.10
netsh dhcp add securitygroups
Restart-Service dhcpserver
```

### 2. Étendue et options

```powershell
Add-DhcpServerv4Scope -Name "LAN DoumbiaCorp" -StartRange 192.168.10.100 -EndRange 192.168.10.200 -SubnetMask 255.255.255.0 -LeaseDuration (New-TimeSpan -Days 8) -State Active
Set-DhcpServerv4OptionValue -ScopeId 192.168.10.0 -Router 192.168.10.1 -DnsServer 192.168.10.10 -DnsDomain "doumbiacorp.local"
```

### 3. Vérification côté serveur

```powershell
Get-DhcpServerInDC
Get-DhcpServerv4Scope
Get-DhcpServerv4OptionValue -ScopeId 192.168.10.0
```

| Contrôle | Résultat |
|---|---|
| Serveur autorisé | `dc01.doumbiacorp.local`, `192.168.10.10` |
| Étendue | `192.168.10.0`, `255.255.255.0`, `Active`, `.100` à `.200`, bail `8.00:00:00` |
| Option 3 (Routeur) | `192.168.10.1` |
| Option 6 (Serveurs DNS) | `192.168.10.10` |
| Option 15 (Nom de domaine) | `doumbiacorp.local` |
| Option 51 (Bail) | `691200` secondes (8 jours) |

Le Gestionnaire de serveur affiche une bannière « Configuration requise pour : Serveur DHCP » : simple rappel de l'assistant post-installation, dont les actions (autorisation et groupes) ont été faites en PowerShell. Les journaux montrent des erreurs au premier démarrage du service (13:49) puis uniquement des avertissements après le redémarrage (13:58) ; _contenu exact des événements 1046 et 10020 à compléter_.

![Gestionnaire de serveur, DHCP](../assets/03-gestionnaire-dhcp.png)
![Vérification DHCP](../assets/03-verif-dhcp.png)

### 4. Ajout du poste CL01 et obtention de l'adresse

Nœud **Windows 10 w/ Edge** ajouté dans GNS3, relié au switch. Sur CL01 :

```
ipconfig /all
ping 192.168.10.10
nslookup doumbiacorp.local
```

| Contrôle | Résultat |
|---|---|
| Adresse IPv4 | `192.168.10.100` (première de l'étendue), DHCP activé |
| Serveur DHCP / passerelle / DNS | `192.168.10.10` / `192.168.10.1` / `192.168.10.10` |
| Suffixe DNS | `doumbiacorp.local` |
| Bail | Obtenu le 30/10, expire le 07/11 (8 jours) |
| `ping 192.168.10.10` | 4/4, 1 ms, `TTL=128` (aucun routeur traversé) |
| `nslookup doumbiacorp.local` | `192.168.10.10` ; `Server: UnKnown` car aucune zone de recherche inversée n'existe encore |

![ipconfig sur CL01](../assets/03-cl01-ipconfig.png)

**Accès Internet instable** : `ping google.com` échoue à la première tentative puis réussit ; latences de 99 à 733 ms et pertes de paquets vers `8.8.8.8`. La configuration est correcte (la 2e requête DNS aboutit), le chemin vers Internet est instable. La jonction n'utilise que le réseau local. Tests de localisation (ping depuis le PC hôte, `ping 192.168.10.1 -n 20` depuis DC01) et durcissement (deuxième redirecteur, délai porté à 5 secondes) : _à compléter_.

### 5. Jonction de CL01 au domaine

Préparations (fenêtre PowerShell **en administrateur**) :

```powershell
Get-Date
Set-TimeZone -Id "Greenwich Standard Time"
net use \\192.168.10.10\IPC$ /user:DOUMBIACORP\Administrateur
net use \\192.168.10.10\IPC$ /delete
foreach ($p in 53,88,135,389,445) { Test-NetConnection 192.168.10.10 -Port $p -WarningAction SilentlyContinue | Select-Object RemotePort, TcpTestSucceeded }
```

Résultats : heure de CL01 et DC01 écartées d'environ 1 minute (limite Kerberos : 5 minutes) ; identifiants valides ; ports 53, 88, 135, 389 et 445 joignables.

Jonction (commande courte, sans chemin d'OU saisi à la main) :

```powershell
Add-Computer -DomainName doumbiacorp.local -NewName CL01 -Credential DOUMBIACORP\Administrateur -Restart
```

Puis, sur DC01, rangement dans l'OU `Postes` (chemin construit à partir de l'annuaire) :

```powershell
$cible = "OU=Postes,OU=Ordinateurs,OU=DoumbiaCorp," + (Get-ADDomain).DistinguishedName
Get-ADComputer CL01 | Move-ADObject -TargetPath $cible
Get-ADComputer CL01 | Select-Object Name, Enabled, DistinguishedName
```

Connexion avec `DOUMBIACORP\awa.traore` : Windows impose le changement du mot de passe (`ChangePasswordAtLogon`), puis ouvre la session ; `whoami` renvoie `doumbiacorp\awa.traore` et le profil `C:\Users\awa.traore` est créé.

Reste à relever : `nltest /dsgetdc:doumbiacorp.local` sur CL01 (la commande sans paramètre n'affiche que l'aide), le `DistinguishedName` de CL01 après déplacement, et `Get-DhcpServerv4Lease -ScopeId 192.168.10.0` sur DC01.

![Connexion awa.traore](../assets/03-connexion-awa.png)

## Problèmes rencontrés et solutions

Voir [../docs/troubleshooting.md](../docs/troubleshooting.md) : 011 (GNS3 VM qui ne démarre plus), 012 (mot de passe du MikroTik perdu), 013 (échecs de jonction) et 014 (échec de connexion d'un utilisateur).

## Choix de lab et limites

- DHCP hébergé sur le contrôleur de domaine : acceptable en lab ; en production, un serveur dédié et redondant (DHCP failover).
- Jonction effectuée avec l'Administrateur du domaine ; en production, un compte délégué dédié.
- Zone de recherche inversée DNS non créée (facultatif : `Add-DnsServerPrimaryZone -NetworkId "192.168.10.0/24" -ReplicationScope Domain`).
- Les mots de passe de lab sont conservés dans un gestionnaire de mots de passe, jamais dans le dépôt.

## Bonnes pratiques

- Construire les chemins d'annuaire (`DistinguishedName`) par commande plutôt que de les taper à la main.
- Lire `C:\Windows\debug\NetSetup.log` en cas d'échec de jonction.
- Snapshot VMware avant et après chaque étape structurante.
