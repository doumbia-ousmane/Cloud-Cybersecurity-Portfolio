# Plan d'adressage et de nommage

## Réseaux

| Réseau | Plage | Rôle |
|---|---|---|
| NAT GNS3 VM | 192.168.42.0/24 | Sortie Internet (fournie par la GNS3 VM) |
| LAN DoumbiaCorp | 192.168.10.0/24 | Serveurs et postes du domaine |

## Découpage du LAN 192.168.10.0/24

| Plage | Usage |
|---|---|
| 192.168.10.1 | Passerelle (MikroTik, ether2) |
| 192.168.10.10 - .19 | Serveurs (IP statiques) |
| 192.168.10.20 - .49 | Réservé (futurs serveurs, équipements) |
| 192.168.10.100 - .200 | Pool DHCP des postes clients (phase 3) |

## Machines

| Nom | Rôle | Adresse | DNS (phases 0-1) | DNS (après phase 2) |
|---|---|---|---|---|
| GW-DOUMBIACORP | Routeur / NAT | 192.168.10.1 | 8.8.8.8 | n/a |
| DC01 | AD DS, DNS, DHCP | 192.168.10.10 | 8.8.8.8 | 192.168.10.10 |
| SRV02 | Fichiers, impression, sauvegarde | 192.168.10.11 | 8.8.8.8 | 192.168.10.10 |
| CL01 | Poste client Windows 10 | DHCP | 8.8.8.8 | 192.168.10.10 (via DHCP) |

## Conventions de nommage

- Serveurs : `SRV` + numéro, contrôleurs de domaine : `DC` + numéro
- Postes : `CL` + numéro
- Domaine : `doumbiacorp.local` (NetBIOS : `DOUMBIACORP`)
- Utilisateurs : `prenom.nom` (ex. `awa.traore`)
- Groupes : `GG_<service>` (globaux), `DL_<ressource>_<droit>` (domaine local)
