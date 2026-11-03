# Journal de dépannage

Chaque entrée : symptôme, diagnostic, cause, solution.

## 001 : GNS3 VM sans adresse IP (eth0)

- **Date** : 2026-10-19
- **Symptôme** : l'écran de la GNS3 VM affiche `eth0 is not configured (no IP address found)`.
- **Diagnostic** : `ip a` montre eth0 et eth1 en état UP, mais seulement des adresses IPv6 `fe80::`, aucune IPv4. Le fichier `/etc/netplan/90_gns3vm_static_netcfg.yaml` ne configurait que eth1.
- **Cause** : les deux adaptateurs VMware étaient en mode *Bridged (Automatic)*, et le réseau physique ne distribuait pas d'adresse à la VM. De plus, eth0 n'était pas déclarée dans netplan.
- **Solution** :
  1. Déclarer eth0 et eth1 en `dhcp4: yes` dans le fichier netplan, puis `sudo netplan apply`.
  2. Passer *Network Adapter* en **NAT** et *Network Adapter 2* en **Host-only** dans VMware.
  3. Redémarrer la VM et vérifier avec `ip a`.
- **Leçon** : en lab, privilégier NAT et Host-only, qui ne dépendent pas du réseau physique.

## 002 : Erreur PowerShell « ParameterBindingException »

- **Date** : 2026-10-19
- **Symptôme** : `Remove-NetIPAddress : Impossible de trouver un paramètre positionnel acceptant l'argument « 192.168.10.2 »`.
- **Diagnostic** : la commande tapée était `Remove-NetIPAddress -InterfaceAlias "Ethernet" IPAddress 192.168.10.2 ...` : le tiret devant `IPAddress` manquait.
- **Cause** : sans tiret, PowerShell lit `IPAddress` comme une valeur positionnelle et ne sait plus à quel paramètre rattacher `192.168.10.2`.
- **Solution** : retaper la commande avec `-IPAddress`.
- **Deuxième occurrence (2026-10-22)** : même erreur avec `Sort-Object InstalledOn Descending` au lieu de `-Descending`.
- **Leçon** : `PositionalParameterNotFound` signale presque toujours un tiret oublié devant un paramètre ; privilégier le copier-coller et la touche `Tab`.

## 003 : IP de DC01 différente du plan d'adressage

- **Date** : 2026-10-19
- **Symptôme** : `ipconfig /all` affichait 192.168.10.2 au lieu de 192.168.10.10.
- **Cause** : adresse saisie à la main différente de celle prévue dans [plan-adressage.md](plan-adressage.md).
- **Solution** : suppression de l'ancienne adresse et de la route par défaut avec `Remove-NetIPAddress` et `Remove-NetRoute`, puis `New-NetIPAddress` avec la bonne adresse.
- **Leçon** : corriger l'adressage avant d'installer Active Directory, car un contrôleur de domaine ne doit plus changer d'IP.

## 004 : `Enable-NetFirewallRule` ne trouve pas le groupe de règles

- **Date** : 2026-10-21
- **Symptôme** : `Aucun objet MSFT_NetFirewallRule avec la propriété « DisplayGroup » égale à « @FirewallAPI.dll,-28752 » n'a été trouvé` (`ObjectNotFound`).
- **Cause** : confusion entre deux paramètres. `-DisplayGroup` attend le nom affiché, traduit selon la langue de Windows (ici « Bureau à distance »). `-Group` attend l'identifiant interne `@FirewallAPI.dll,-28752`, identique dans toutes les langues.
- **Solution** : `Enable-NetFirewallRule -Group "@FirewallAPI.dll,-28752"`, puis contrôle avec `Get-NetFirewallRule -Group ...` (3 règles `Enabled = True`).
- **Leçon** : lire d'abord (`Get-NetFirewallRule`) avant de modifier, et vérifier quel paramètre attend quel type de valeur avec `Get-Help`.

## 005 : Snapshot GNS3 impossible

- **Date** : 2026-10-21
- **Symptôme** : `Project must be stopped in order to export it`, puis `Timeout when downloading file 'project-files/qemu/.../hda_disk.qcow2' from remote compute 192.168.139.131:80`.
- **Cause** : un snapshot GNS3 exporte le projet, ce qui exige l'arrêt de tous les nœuds ; le disque de DC01, hébergé dans la GNS3 VM, est trop volumineux pour être téléchargé avant le délai maximal.
- **Solution** : snapshot **VMware** de la GNS3 VM (nœuds arrêtés, projet fermé, VM éteinte), car tous les disques des nœuds y sont stockés.
- **Leçon** : choisir l'outil de sauvegarde adapté à la taille des machines ; supprimer les anciens snapshots VMware pour éviter qu'ils ne grossissent.

## 006 : Mises à jour Windows partiellement installées

- **Date** : 2026-10-22
- **Symptôme** : via `sconfig`, 2 mises à jour sur 5 réussies (.NET), 3 en échec dont la cumulative de sécurité KB5122882 ; `Redémarrage nécessaire : True`.
- **Hypothèse** : redémarrage en attente après l'installation des mises à jour .NET, ou téléchargement perturbé par la latence du lab (environ 90 ms).
- **Diagnostic proposé** : redémarrer, relancer `sconfig` > 6, puis lire les erreurs avec `Get-WinEvent -LogName "Microsoft-Windows-WindowsUpdateClient/Operational"` (code `0x8024xxxx`).
- **Statut** : non résolu à ce stade ; reporté pour ne pas bloquer le projet. À traiter avant la phase 06 (durcissement), car la cumulative contient des correctifs de sécurité. Le lab n'est pas exposé à Internet (LAN privé derrière NAT).
- **Leçon** : documenter un échec non résolu avec honnêteté (état, risque, plan) vaut mieux que de le passer sous silence.

## 007 : test `dcdiag` DFSREvent en échec après la promotion

- **Date** : 2026-10-28
- **Symptôme** : `dcdiag` : « Le test DFSREvent de DC01 a échoué » (erreurs ou avertissements après le partage de SYSVOL) ; tous les autres tests réussissent.
- **Diagnostic** : journal `DFS Replication` : événements 1202 (erreur) à 11:59 et 12:40, 6016 (avertissement) à 13:18, tous avec l'erreur **1355** (domaine introuvable). Puis événements d'information 1206 (contrôleur contacté) à 13:18:56 et 4602 (SYSVOL initialisé, DC01 membre principal) à 13:18:58. Partages `SYSVOL` et `NETLOGON` présents ; `sysvolcheck`, `netlogons`, `advertising` réussis.
- **Cause** : le service DFSR a cherché le domaine avant que l'annuaire et le DNS soient prêts ; il a réessayé et réussi.
- **Pourquoi le test échoue encore** : `DFSREvent` examine les 24 dernières heures ; l'avertissement de 13:18 y figure encore.
- **Statut** : à reconfirmer le 29/10 après 13:19 avec `dcdiag /test:dfsrevent`. Risque pratique faible (un seul contrôleur, aucun partenaire de réplication).
- **Leçon** : lire le contenu des événements plutôt que de supposer ; un test basé sur une fenêtre de temps peut échouer après la résolution du problème.

## 008 : `PositionalParameterNotFound` avec l'argument `$null`

- **Date** : 2026-10-29
- **Symptôme** : `New-ADOrganizationalUnit : Impossible de trouver un paramètre positionnel acceptant l'argument « $null »`.
- **Cause** : plusieurs commandes collées sur une seule ligne, sans séparateur entre `New-ADOrganizationalUnit ... -Description "..."` et `$racine = ...`. PowerShell a lu `$racine` (encore vide) comme argument supplémentaire de la première commande. Un espace parasite dans `"OU=DoumbiaCorp, $base"` a aussi été ajouté par le copier-coller.
- **Diagnostic** : `Get-ADOrganizationalUnit -Filter *` montre que rien n'a été créé (seule `Domain Controllers`).
- **Solution** : refaire en blocs séparés (un par commande), dans l'ordre parent puis enfants, sans espace dans les chemins.
- **Leçon** : même message que l'entrée 002, mais autre cause. Lire ce que PowerShell met entre guillemets : `« $null »` signale une variable vide, pas un tiret oublié.

## 009 : arrêt brutal de DC01 (souris bloquée dans la console)

- **Date** : 2026-10-29
- **Symptôme** : le pointeur de la souris restait bloqué dans la console de la VM ; DC01 a été éteint puis rallumé. Au redémarrage, les variables PowerShell avaient disparu (`$racine` vide) et le compte `awa.traore`, en cours de création, n'existait pas.
- **Risque** : DC01 est l'unique contrôleur de domaine ; un arrêt brutal peut endommager l'annuaire sans copie de secours.
- **Constat** : OU et groupes présents ; recréation d'Awa Traore, puis création de 19 comptes par script : 0 erreur.
- **À compléter** : contrôles formels après incident (`Get-Service NTDS, DNS, Netlogon, KDC, ADWS, DFSR`, `dcdiag /q`, journaux `Directory Service` et événement DFSR 2213).
- **Prévention** : libérer le pointeur (Ctrl+Alt) avant toute décision, patienter avant de couper, éteindre avec `Stop-Computer`, snapshot après chaque étape importante, scripts qui recréent leurs propres variables.

## 010 : collage dans la console de la VM

- **Date** : 2026-10-29
- **Symptôme** : le collage (clic droit) ne fonctionnait pas dans la console du serveur.
- **Cause probable** : le presse-papiers de l'hôte n'est pas partagé avec la console de la VM.
- **Solution** : le raccourci **Shift+Insert** fonctionne dans la console PowerShell. Alternative prévue : télécharger les fichiers depuis un dépôt GitHub public avec `Invoke-WebRequest -UseBasicParsing`.
- **Leçon** : en cas de collage multiligne, vérifier que les retours à la ligne sont conservés (voir 008).

## 011 : la GNS3 VM ne démarre plus (`Geom Error`)

- **Date** : 2026-10-30
- **Symptôme** : écran noir avec `Geom Error`, puis deux échecs de démarrage réseau (`PXE-E53: No boot filename received`) et `Operating System not found` ; VMware affiche « Ubuntu 64-bit is not installed on this virtual machine ». Un message distinct (`Cannot connect the virtual device ide0:0 because no corresponding device is available on the host`) concernait le lecteur CD/DVD physique absent, sans lien avec la panne.
- **Diagnostic** : paramètres de la VM intacts (8 Go de RAM, 4 processeurs, disques SCSI de 100 Go et 1 To attachés, réseaux NAT et Host-only) ; quatre snapshots présents (`Avant-MAJ`, `Phase01-OK`, `Phase02a-DC-OK`, `Phase02-OK`).
- **Cause** : à déterminer. Hypothèses : arrêt incomplet de la VM, disque de l'hôte plein, chaîne de snapshots endommagée.
- **Solution** : `Power Off`, puis `Revert to Snapshot: Phase02-OK` (le plus récent, pris après la création des utilisateurs), puis `Power On` : la VM redémarre normalement. Case « Connect at power on » du lecteur CD/DVD décochée pour supprimer le message `ide0:0`.
- **Perte** : uniquement les modifications faites après le 29/10 à 15:58.
- **Leçon** : un snapshot par fin d'étape est un filet de sécurité efficace ; ajouter une copie de sauvegarde externe de la VM ; arrêt propre en trois temps (nœuds GNS3, fermeture du projet, `Shut Down Guest` de la GNS3 VM).

## 012 : mot de passe du MikroTik perdu

- **Date** : 2026-11-03
- **Symptôme** : impossible d'ouvrir une session sur le routeur `GW-DOUMBIACORP` ; le mot de passe défini au premier démarrage n'avait pas été noté.
- **Impact** : le routeur continue de fonctionner (passerelle et NAT) ; seule la modification de sa configuration est bloquée.
- **Solution retenue** : remplacer le nœud par un nouveau MikroTik CHR et rejouer les 5 commandes de la phase 00 (la configuration est documentée), avec la même adresse `192.168.10.1` pour ne rien changer côté clients. Mot de passe défini avec `/password` et conservé dans un gestionnaire de mots de passe ; export de la configuration avec `/export file=gw-phase03`.
- **Statut** : reconstruction à faire après la phase 03.
- **Leçon** : noter immédiatement tout mot de passe de lab dans un gestionnaire ; la documentation précise de chaque configuration rend un équipement remplaçable.

## 013 : échecs de jonction de CL01 au domaine

- **Date** : 2026-11-03
- **Symptôme 1** : `Add-Computer : ... failed to join domain ... Access is denied.` ; l'invite affichait `C:\Users\IEUser>` (fenêtre non élevée). Hypothèse la plus probable : manque de droits d'administrateur local ; non retestée.
- **Symptôme 2** (fenêtre élevée, `C:\Windows\system32>`) : `... with following error message: More data is available.`
- **Vérifications** : fenêtre élevée confirmée (`True`) ; `net use` vers `\\192.168.10.10\IPC$` réussi (identifiants valides) ; écart d'heure d'environ 1 minute ; ports 53, 88, 135, 389, 445 joignables ; `Get-ADComputer -Filter *` ne montre que `DC01` (aucun compte orphelin).
- **Diagnostic** : `Get-Content C:\Windows\debug\NetSetup.log -Tail 40`. Ligne `lpMachineAccountOU: OU=Postes,OU=Ordinateurs,OU=doumbiacorp,DC=local` au lieu de `OU=Postes,OU=Ordinateurs,OU=DoumbiaCorp,DC=doumbiacorp,DC=local`, puis `ldap_compare_s failed: 0xa 0xea`, `LDAP creation failed`, `Cannot retry downlevel, specifying OU is not supported`.
- **Cause** : chemin d'OU mal saisi (`DC=doumbiacorp` manquant, casse de `DoumbiaCorp` modifiée), donc une OU inexistante ; le code `0xea` (« More data is available ») est trompeur.
- **Solution** : jonction sans `-OUPath`, puis `Move-ADObject` vers l'OU `Postes` avec un chemin construit par `(Get-ADDomain).DistinguishedName`.
- **Statut** : résolu, CL01 joint au domaine.
- **Leçon** : les messages génériques de PowerShell masquent la vraie cause ; le journal `NetSetup.log` la désigne.

## 014 : échec de connexion d'un utilisateur du domaine

- **Date** : 2026-11-03
- **Symptôme** : connexion de `DOUMBIACORP\awa.traore` refusée sur CL01.
- **Cause** : mot de passe oublié (saisi de façon masquée lors de la création manuelle du compte).
- **Solution** : sur DC01, `Set-ADAccountPassword -Identity awa.traore -Reset -NewPassword $mdp`, `Set-ADUser awa.traore -ChangePasswordAtLogon $true`, `Unlock-ADAccount awa.traore`. À la connexion suivante, Windows affiche « The user's password must be changed before signing in », comportement attendu ; après le changement, `whoami` renvoie `doumbiacorp\awa.traore`.
- **Leçon** : un administrateur réinitialise un mot de passe sans connaître l'ancien (`-Reset`) ; conserver les mots de passe de lab dans un gestionnaire.
