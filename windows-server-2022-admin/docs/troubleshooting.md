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
