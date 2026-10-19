# Architecture du lab

## Flux réseau

1. Le nœud **NAT** de GNS3 donne accès à Internet via la GNS3 VM (réseau `192.168.42.0/24`).
2. Le **MikroTik CHR** reçoit son adresse WAN en DHCP sur `ether1` et fait du masquerade vers le LAN.
3. Le LAN `192.168.10.0/24` est commuté par un **Ethernet switch** GNS3.
4. Les serveurs utilisent le MikroTik comme passerelle par défaut.

## Choix techniques

| Choix | Justification |
|---|---|
| MikroTik CHR comme passerelle | Léger, gratuit, routage et NAT simples, proche d'un équipement réel |
| Un seul LAN au départ | Simplicité ; la segmentation (VLAN, DMZ) pourra être ajoutée en phase 6 |
| IP statiques pour les serveurs | Un serveur d'infrastructure ne doit jamais changer d'adresse |
| Kali Linux (disponible dans le lab) | Réservé aux tests de sécurité de la phase 6 |

## Ressources recommandées (GNS3 VM : 8 Go de RAM, 4 vCPU)

| Nœud | RAM conseillée |
|---|---|
| DC01 | 3 Go |
| SRV02 | 2 à 3 Go |
| CL01 | 2 à 3 Go |
| MikroTik CHR | 256 Mo |

Si la mémoire manque, ne démarrer que les nœuds nécessaires à la phase en cours.
