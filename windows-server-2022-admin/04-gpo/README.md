# Phase 04 : Stratégies de groupe (GPO) et politiques de sécurité des comptes

## Objectif

Appliquer automatiquement des réglages aux utilisateurs et aux ordinateurs du domaine selon leur OU, et imposer des règles de mots de passe et de verrouillage de compte. Les lecteurs réseau sont reportés à la phase 05 (ils exigent des dossiers partagés).

## Concepts

| Notion | Explication |
|---|---|
| **GPO** | *Group Policy Object* : jeu de réglages nommé, poussé par l'annuaire |
| **Lien** | Une GPO ne s'applique que là où elle est liée (domaine, site ou OU) ; d'où l'intérêt des OU |
| **Configuration ordinateur / utilisateur** | La première s'applique à la machine (au démarrage), la seconde à la personne (à la connexion) |
| **Ordre LSDOU** | Local, Site, Domaine, OU : la dernière GPO appliquée l'emporte en cas de conflit |
| **Héritage** | Une GPO liée à une OU parente s'applique aux OU enfants |
| **Filtrage de sécurité** | Limite une GPO à certains groupes |
| **Actualisation** | Les postes relisent leurs GPO environ toutes les 90 minutes ; `gpupdate /force` l'impose |
| **GPC / GPT** | Une GPO = définition dans l'annuaire + fichiers dans SYSVOL |
| **Politique de mots de passe du domaine** | Unique pour tout le domaine, stockée dans la `Default Domain Policy` (seule exception à la règle de ne pas la modifier) |
| **PSO** (*Fine-Grained Password Policy*) | Politique de mots de passe appliquée à des utilisateurs ou à des groupes globaux de sécurité, prioritaire sur celle du domaine |

Convention de nommage : `USR-` (utilisateurs) ou `CMP-` (ordinateurs), puis la cible et l'objet.

## Prérequis

- Phase 03 validée : CL01 joint au domaine, rangé dans l'OU `Postes`
- OU `RH` et groupes `GG_RH`, `GG_Finance`, `GG_IT` créés en phase 02

## Procédure

### 1. Première GPO utilisateur : bloquer le Panneau de configuration pour le service RH

```powershell
$dn   = (Get-ADDomain).DistinguishedName
$ouRH = "OU=RH,OU=Utilisateurs,OU=DoumbiaCorp,$dn"
$ouRH

New-GPO -Name "USR-RH-Restrictions" -Comment "Bloque le Panneau de configuration pour le service RH"
Set-GPRegistryValue -Name "USR-RH-Restrictions" -Key "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" -ValueName "NoControlPanel" -Type DWord -Value 1
New-GPLink -Name "USR-RH-Restrictions" -Target $ouRH
```

`New-GPO` crée sans lier ; `Set-GPRegistryValue` écrit dans la partie *Utilisateur* (`HKCU`) ; `New-GPLink` lie à l'OU `RH`. Vérification : `Get-GPInheritance -Target $ouRH | Select-Object -ExpandProperty GpoLinks`, console `gpmc.msc`.

Test sur CL01 : `gpupdate /force` puis `gpresult /r /scope user`.

| Test | Résultat |
|---|---|
| `gpresult` pour Awa (RH) | GPO appliquée |
| Panneau de configuration pour Awa | Bloqué, message de restriction |
| Même test avec un compte Finance | Non bloqué : la GPO ne touche que l'OU `RH` |

![GPO dans gpmc.msc](../assets/04-gpmc-usr-rh.png)
![gpresult sur CL01](../assets/04-gpresult-awa.png)
![Blocage du Panneau de configuration](../assets/04-blocage-panneau.png)

### 2. Politique de mots de passe et de verrouillage de compte du domaine

État avant : `Get-ADDefaultDomainPasswordPolicy` (valeurs par défaut : longueur 7, pas de verrouillage).

```powershell
Set-ADDefaultDomainPasswordPolicy -Identity doumbiacorp.local -MinPasswordLength 12 -ComplexityEnabled $true -PasswordHistoryCount 24 -MaxPasswordAge (New-TimeSpan -Days 90) -MinPasswordAge (New-TimeSpan -Days 1) -LockoutThreshold 5 -LockoutDuration (New-TimeSpan -Minutes 30) -LockoutObservationWindow (New-TimeSpan -Minutes 30)
Get-ADDefaultDomainPasswordPolicy
```

| Réglage | Valeur appliquée |
|---|---|
| Longueur minimale | 12 caractères |
| Complexité | Activée |
| Historique | 24 mots de passe |
| Âge maximum / minimum | 90 jours / 1 jour |
| Seuil de verrouillage | 5 échecs |
| Durée de verrouillage / fenêtre d'observation | 30 minutes / 30 minutes |

Les mots de passe existants restent valides ; la nouvelle longueur s'applique au prochain changement. Les recommandations actuelles privilégient la longueur et la surveillance des mots de passe compromis plutôt que des changements fréquents obligatoires ; les 90 jours servent ici à illustrer le mécanisme.

Test du verrouillage (compte de test, jamais l'Administrateur du domaine) : 5 mauvais mots de passe sur CL01 pour `aminata.toure`, puis sur DC01 :

```powershell
Get-ADUser aminata.toure -Properties LockedOut, BadLogonCount | Select-Object Name, LockedOut, BadLogonCount
Unlock-ADAccount aminata.toure
```

Résultat : `LockedOut = True`, déblocage par `Unlock-ADAccount`. `net accounts /domain` sur CL01 affiche la politique reçue.

### 3. Politique plus stricte pour l'IT (PSO)

```powershell
New-ADFineGrainedPasswordPolicy -Name "PSO-IT" -Precedence 10 -MinPasswordLength 14 -ComplexityEnabled $true -PasswordHistoryCount 24 -MaxPasswordAge (New-TimeSpan -Days 60) -MinPasswordAge (New-TimeSpan -Days 1) -LockoutThreshold 3 -LockoutDuration (New-TimeSpan -Minutes 30) -LockoutObservationWindow (New-TimeSpan -Minutes 30) -ReversibleEncryptionEnabled $false
Add-ADFineGrainedPasswordPolicySubject -Identity "PSO-IT" -Subjects "GG_IT"
Get-ADUserResultantPasswordPolicy -Identity lassana.fofana | Select-Object Name, MinPasswordLength, LockoutThreshold
```

Une PSO s'applique à un utilisateur ou à un **groupe global de sécurité** (d'où les groupes `GG_`). `Precedence` départage deux PSO en conflit (la plus petite valeur l'emporte). Résultat pour un compte IT : `PSO-IT`, longueur 14, seuil 3 ; aucune PSO pour un compte RH.

### 4. GPO d'ordinateur : verrouillage de session après inactivité

```powershell
$dn      = (Get-ADDomain).DistinguishedName
$ouPoste = "OU=Postes,OU=Ordinateurs,OU=DoumbiaCorp,$dn"
$ouPoste

New-GPO -Name "CMP-Postes-Verrouillage" -Comment "Verrouille la session apres 5 minutes d'inactivite"
Set-GPRegistryValue -Name "CMP-Postes-Verrouillage" -Key "HKLM\Software\Microsoft\Windows\CurrentVersion\Policies\System" -ValueName "InactivityTimeoutSecs" -Type DWord -Value 300
New-GPLink -Name "CMP-Postes-Verrouillage" -Target $ouPoste
```

`InactivityTimeoutSecs = 300` correspond au réglage « Ouverture de session interactive : limite d'inactivité de l'ordinateur ». La clé `HKLM` appartient à la configuration **ordinateur**.

Sur CL01 : `gpupdate /force`, `gpresult /r /scope computer`, puis `reg query "HKLM\Software\Microsoft\Windows\CurrentVersion\Policies\System" /v InactivityTimeoutSecs` (valeur attendue `0x12c`, soit 300). Une GPO d'ordinateur s'applique surtout au démarrage : redémarrer CL01 si besoin. Résultat : écran de verrouillage après 5 minutes d'inactivité.

![Écran verrouillé](../assets/04-ecran-verrouille.png)

### 5. Sauvegarde et rapport des GPO

```powershell
New-Item -ItemType Directory -Path C:\GPOBackup -Force | Out-Null
Backup-GPO -All -Path C:\GPOBackup
Get-GPOReport -All -ReportType Html -Path C:\GPOBackup\rapport-gpo.html
Get-GPO -All | Select-Object DisplayName, GpoStatus, CreationTime
```

`Backup-GPO` copie toutes les GPO (restaurables avec `Restore-GPO`). Les sauvegardes restent dans la VM : elles ne remplacent pas une copie externe.

Résultats confirmés par l'utilisateur le 04/11/2026 ; captures à ajouter dans `assets/`.

## Problèmes rencontrés et solutions

Aucun nouveau à cette phase. Voir [../docs/troubleshooting.md](../docs/troubleshooting.md).

## Choix de lab et limites

- Politique de mots de passe adaptée à l'apprentissage ; le seuil de 5 échecs peut verrouiller des comptes pendant les tests.
- Lecteurs réseau reportés à la phase 05.
- GPO de sauvegarde conservées dans la VM : copie externe à prévoir.

## Bonnes pratiques

- Une GPO = un objet précis, avec un nom explicite (`USR-`, `CMP-`).
- Vérifier avec `gpresult` côté poste, et tester sur deux populations (cible et hors cible).
- Ne modifier la `Default Domain Policy` que pour la politique de mots de passe ; créer des GPO dédiées pour le reste.
- Ne jamais tester le verrouillage sur l'Administrateur du domaine.
