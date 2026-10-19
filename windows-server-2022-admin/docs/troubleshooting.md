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
