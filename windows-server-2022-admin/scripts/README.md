# Scripts PowerShell

| Script | Rôle | Données |
|---|---|---|
| `New-DoumbiaUsers.ps1` | Création en masse des utilisateurs, rangement dans l'OU du service et ajout au groupe `GG_<service>` | `../data/utilisateurs.csv` |

Propriétés du script : idempotent (relançable sans doublons), erreurs gérées par compte, mot de passe jamais écrit dans un fichier ni dans le dépôt.
Toutes les données sont fictives.
