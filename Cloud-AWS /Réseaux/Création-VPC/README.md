# 🌐 Configuration d'un VPC (Amazon Virtual Private Cloud)

> **Type d'atelier :** TP Pratique AWS / Architecture Réseau & Infrastructures Cloud  
> **Durée estimée :** ⏱️ 45 minutes  
> **Services AWS utilisés :** Amazon VPC, Amazon EC2, Internet Gateway (IGW), NAT Gateway, Route Tables, EC2 Instance Connect  

---

## 📌 Présentation de l'atelier

**Amazon Virtual Private Cloud (Amazon VPC)** vous permet de mettre en service une section du cloud Amazon Web Services (AWS) qui a été isolée de manière logique, dans laquelle vous pouvez lancer des ressources AWS dans un réseau virtuel que vous définissez. Vous conservez la totale maîtrise de votre environnement de mise en réseau virtuel, y compris pour la sélection de vos plages d'adresses IP, la création de sous-réseaux et la configuration de tables de routage et de passerelles réseau.

Au cours de cet atelier, vous créez un cloud privé virtuel (VPC) et d'autres composants réseau nécessaires au déploiement de ressources, telles qu'une instance **Amazon Elastic Compute Cloud (Amazon EC2)**.

---

### 🎯 Objectifs

À la fin de cet atelier, vous saurez :
- [x] Créer un VPC avec un sous-réseau privé, un sous-réseau public, une passerelle Internet et une passerelle NAT.
- [x] Configurer les tables de routage associées aux sous-réseaux pour le trafic local et Internet en utilisant une passerelle Internet et une passerelle NAT.
- [x] Lancer un serveur Bastion dans un sous-réseau public.
- [x] Utiliser un serveur Bastion pour vous connecter à une instance dans un sous-réseau privé.
- [x] *(Défi facultatif)* Créer une instance Amazon EC2 dans un sous-réseau privé et vous y connecter par l'intermédiaire du serveur Bastion.

---

### ⌛ Durée

Cet atelier dure environ **45 minutes**.

---

### 🔑 Accès à la console de gestion AWS

1. En haut de ces instructions, choisissez **Start Lab (Démarrer l'atelier)** pour lancer l'atelier.
2. Un volet **Start Lab (Démarrer l'atelier)** s'ouvre et affiche le statut de l'atelier.
3. Attendez que le message *« Lab status: ready » (Statut de l'atelier : prêt)* s'affiche, puis cliquez sur **X** pour fermer le volet Start Lab.
4. En haut de ces instructions, choisissez **AWS** pour ouvrir la console de gestion AWS dans un nouvel onglet de navigateur. Le système vous y connecte automatiquement.
   > 💡 **Conseil :** Si le nouvel onglet ne s'affiche pas, une bannière ou une icône située en haut du navigateur peut indiquer que votre navigateur bloque l'ouverture des fenêtres contextuelles. Cliquez sur la bannière ou l'icône, puis choisissez **Allow pop-ups (Autoriser les fenêtres contextuelles)**.
5. Disposez la console de gestion AWS de façon à l'afficher à côté de ces instructions. Dans l'idéal, vous devez pouvoir voir les deux onglets en même temps pour suivre les étapes de l'atelier.

---

## 🏗️ Tâche 1 : Création d'un VPC

Au cours de cette tâche, vous allez créer un VPC.

1. Dans la barre de recherche de la Console de gestion AWS, saisissez et sélectionnez `VPC` pour accéder à la Console de gestion VPC.
2. Dans le volet de navigation de gauche, pour **Cloud privé virtuel**, choisissez **Vos VPC**.
   > ℹ️ Dans chaque région, un VPC par défaut avec le bloc d'adresse CIDR (*Classless Inter-Domain Routing*) `172.31.0.0/16` a déjà été créé pour vous. Même si vous n'avez encore rien créé dans votre compte, vous allez voir certaines ressources de VPC préexistantes.
3. Choisissez **Créer un VPC** et configurez les options suivantes :
   * **Ressources à créer :** choisissez `VPC uniquement`.
   * **Identification de nom :** entrez `Lab VPC`.
   * **IPv4 CIDR block (Bloc d'adresse CIDR IPv4) :** choisissez `IPv4 CIDR manual input (Saisie manuelle du CIDR IPv4)`.
   * **IPv4 CIDR (CIDR IPv4) :** entrez `10.0.0.0/16`.
   * **IPv6 CIDR block (Bloc d'adresse CIDR IPv6) :** choisissez `No IPv6 CIDR block (Aucun bloc d'adresse CIDR IPv6)`.
   * **Location :** choisissez `Par défaut`.
   * **Balises :** conservez les balises suggérées.
4. Choisissez **Créer un VPC**.
   * *En haut de la page, un message similaire à ce qui suit s'affiche : « Vous avez créé avec succès vpc-NNNNNNNNNNN / Lab VPC. »*
5. Choisissez **Actions**, puis **Modifier les paramètres VPC**.
6. Dans la section **Paramètres DNS**, sélectionnez **Activer les noms d'hôte DNS**.
7. Sélectionnez **Enregistrer**.
   * *Les instances EC2 lancées dans le VPC reçoivent désormais automatiquement un nom d'hôte DNS IPv4 public.*

---

## 🔀 Tâche 2 : Création de sous-réseaux

Au cours de cette tâche, vous allez créer un sous-réseau public et un sous-réseau privé.

### 🌐 Tâche 2.1 : Création d'un sous-réseau public

1. Dans le volet de navigation de gauche, pour **Cloud privé virtuel**, choisissez **Sous-réseaux**.
2. Choisissez **Créer un sous-réseau** et configurez les options suivantes :
   * **ID de VPC :** choisissez `Lab VPC`.
   * **Nom du sous-réseau :** entrez `Public Subnet`.
   * **Zone de disponibilité :** choisissez la première zone de disponibilité de la liste. *(Ne choisissez pas Aucune préférence)*.
   * **IPv4 CIDR block (Bloc d'adresse CIDR IPv4) :** entrez `10.0.0.0/24`.
3. Choisissez **Créer un sous-réseau**.
4. Vous allez à présent configurer le sous-réseau public de sorte à attribuer automatiquement une adresse IP publique à toutes les instances EC2 lancées dans celui-ci :
   * Sélectionnez **Public Subnet**.
   * Choisissez **Actions**, puis **Modifier les paramètres de sous-réseau**.
   * Dans la section **Paramètres d'attribution automatique d'une adresse IP**, sélectionnez `Enable auto-assign public IPv4 address` *(Activer l'attribution automatique d'une adresse IPv4 publique)*.
   * Sélectionnez **Enregistrer**.

> ℹ️ Bien que ce sous-réseau ait été nommé **Public Subnet**, il n'est pas encore public. Un sous-réseau public doit avoir une passerelle Internet, que vous attacherez au cours d'une tâche ultérieure de l'atelier.

### 🔒 Tâche 2.2 : Création d'un sous-réseau privé

Au cours de cette tâche, vous créez le sous-réseau privé qui est utilisé pour les ressources qui doivent rester isolées d'Internet.

1. Pour créer le sous-réseau privé, répétez les étapes de la tâche précédente, puis choisissez les options suivantes :
   * **ID de VPC :** choisissez `Lab VPC`.
   * **Nom du sous-réseau :** entrez `Private Subnet`.
   * **Zone de disponibilité :** choisissez la première zone de disponibilité de la liste. *(Ne choisissez pas Aucune préférence)*.
   * **IPv4 CIDR block (Bloc d'adresse CIDR IPv4) :** entrez `10.0.2.0/23`.
2. Choisissez **Créer un sous-réseau**.

> ℹ️ Le bloc d'adresse CIDR `10.0.2.0/23` inclut toutes les adresses IP qui commencent par `10.0.2.x` et `10.0.3.x`. Cette plage est deux fois plus grande que le sous-réseau public, car la plupart des ressources doivent être conservées dans des sous-réseaux privés, sauf si elles doivent être spécifiquement accessibles depuis Internet.

*Votre VPC possède désormais deux sous-réseaux. Toutefois, le VPC est totalement isolé et ne peut pas communiquer avec des ressources en dehors du VPC. Vous allez ensuite configurer le sous-réseau public pour vous connecter à Internet par le biais d'une passerelle Internet.*

---

## 🚪 Tâche 3 : Création d'une passerelle Internet

Au cours de cette tâche, vous allez créer une passerelle Internet pour votre VPC. Une passerelle Internet est nécessaire pour établir une connectivité externe aux instances EC2 dans les VPC.

1. Dans le volet de navigation de gauche, pour **Cloud privé virtuel**, choisissez **Passerelles Internet**.
2. Choisissez **Créer une passerelle Internet** et pour **Identification de nom**, entrez `Lab IGW`.
3. Choisissez **Créer une passerelle Internet**.
4. Choisissez **Actions**, puis **Attacher à un VPC**.
5. Dans la liste déroulante, sélectionnez `Lab VPC`, puis choisissez **Attacher une passerelle Internet**.

*Votre sous-réseau public dispose désormais d'une connexion à Internet. Cependant, pour acheminer le trafic vers Internet, vous devez également configurer la table de routage du sous-réseau public afin qu'elle utilise la passerelle Internet.*

---

## 🗺️ Tâche 4 : Configuration des tables de routage

Au cours de cette tâche, vous allez effectuer les actions suivantes :
- Créer une table de routage publique pour le trafic Internet.
- Ajouter un acheminement à la table de routage pour diriger le trafic Internet vers la passerelle Internet.
- Associer le sous-réseau public à la nouvelle table de routage.

1. Dans le volet de navigation de gauche, pour **Cloud privé virtuel**, choisissez **Tables de routage**.
   * *Plusieurs tables de routage sont répertoriées.*
2. Sélectionnez la table de routage qui indique `Lab VPC` dans la colonne VPC.
   > 💡 **Astuce :** Si vous ne voyez pas la colonne VPC, faites défiler l'écran vers la droite.
3. Dans la colonne Nom, cliquez sur l'icône de modification, entrez `Private Route Table` pour Edit Name *(Modifier le nom)*, puis choisissez **Enregistrer**.
4. Cliquez sur l'onglet **Routes**.
   * *Il n'y a actuellement qu'un seul acheminement. Cela indique que l'ensemble du trafic destiné à `10.0.0.0/16` (qui est la plage de Lab VPC) sera acheminé localement. Cette option permet à tous les sous-réseaux au sein d'un VPC de communiquer entre eux.*
5. Vous allez maintenant créer une table de routage publique pour envoyer le trafic public vers la passerelle Internet :
   * Choisissez **Créer une table de routage** et configurez les options suivantes :
     * **Nom - facultatif :** entrez `Public Route Table`.
     * **VPC :** choisissez `Lab VPC`.
   * Choisissez **Créer une table de routage**.
6. Une fois la table de routage créée, dans l'onglet **Routes**, choisissez **Modifier des routes**.
   > ℹ️ Vous allez à présent ajouter un acheminement pour diriger le trafic Internet (`0.0.0.0/0`) vers la passerelle Internet.
   * Choisissez **Ajouter une route** et configurez les options suivantes :
     * **Destination :** entrez `0.0.0.0/0`.
     * **Cible :** choisissez **Passerelle Internet**, puis `Lab IGW` dans la liste.
   * Sélectionnez **Enregistrer les modifications**.
7. La dernière étape consiste à associer cette nouvelle table de routage au sous-réseau public :
   * Cliquez sur l'onglet **Associations de sous-réseau**.
   * Choisissez **Modifier des associations de sous-réseau**.
   * Sélectionnez **Public Subnet**.
   * Choisissez **Enregistrer les associations**.

*Le sous-réseau public est désormais public, car il possède une entrée de table de routage qui envoie le trafic vers Internet par le biais de la passerelle Internet.*

> 📝 Au cours des tâches précédentes, vous avez créé un VPC et attaché une passerelle Internet. Vous avez ensuite créé des sous-réseaux et une table de routage, puis vous avez associé une table de routage publique au sous-réseau public. Vous allez maintenant lancer des ressources dans les sous-réseaux, comme requis.

---

## 🖥️ Tâche 5 : Lancement d'un serveur Bastion dans le sous-réseau public

Un **serveur Bastion** (également connu sous le nom de *« serveur intermédiaire »*) est une instance EC2 dans un sous-réseau public, configuré de manière sécurisée pour fournir un accès aux ressources d'un sous-réseau privé. Les opérateurs système peuvent se connecter au serveur Bastion, puis accéder aux ressources du sous-réseau privé.

Au cours de cette tâche, vous allez lancer un serveur Bastion d'instance EC2 dans le sous-réseau public que vous avez créé précédemment.

1. Dans la barre de recherche de la Console de gestion AWS, saisissez et sélectionnez `EC2` pour accéder à la Console de gestion EC2.
2. Dans le volet de navigation de gauche, choisissez **Instances**.
3. Choisissez **Lancer des instances** et configurez les options suivantes :
   * Dans la section **Nom et balises**, entrez `Bastion Server`.
   * Dans la section **Application and OS Images (Amazon Machine Image)**, configurez :
     * **Démarrage rapide :** choisissez `Amazon Linux`.
     * **Amazon Machine Image (AMI) :** choisissez `Amazon Linux 2023 AMI`.
   * Dans la section **Type d'instance**, choisissez `t3.micro`.
   * Dans la section **Paire de clés (connexion)**, choisissez `Continuer sans paire de clés (déconseillé)`.
     > ℹ️ Vous allez utiliser EC2 Instance Connect pour accéder au shell s'exécutant sur l'instance EC2. Une paire de clés n'est donc pas nécessaire pour cet atelier.
   * Dans la section **Paramètres réseau**, choisissez **Modifier** et configurez les options suivantes :
     * **VPC – obligatoire :** choisissez `Lab VPC`.
     * **Sous-réseau :** choisissez `Public Subnet`.
     * **Attribuer automatiquement l'adresse IP publique :** choisissez `Activer`.
     * **Pare-feu (groupes de sécurité) :** choisissez `Créer un groupe de sécurité`.
     * **Nom du groupe de sécurité - obligatoire :** entrez `Bastion Security Group`.
     * **Description - obligatoire :** entrez `Allow SSH`.
     * **Règles des groupes de sécurité pour le trafic entrant :**
       * **Type :** choisissez `ssh`.
       * **Type de source :** choisissez `N'importe où`.
4. Choisissez **Lancer l'instance**.
5. Pour afficher l'instance lancée, choisissez **Afficher toutes les instances**.

*Au départ, l'instance EC2 nommée Bastion Server est à l'état **En attente**. Le champ État de l'instance prend ensuite la valeur **En cours d'exécution**, ce qui indique que le démarrage de l'instance est terminé.*

> 💡 Passez à la tâche suivante. Vous n'avez pas besoin d'attendre que l'instance soit exécutée.

---

## 🔄 Tâche 6 : Création d'une passerelle NAT

Au cours de cette tâche, vous allez lancer une passerelle NAT dans le sous-réseau public et configurer la table de routage privée de sorte à faciliter la communication entre les ressources du sous-réseau privé et Internet.

1. Dans la barre de recherche de la console de gestion AWS, entrez `NAT gateways`, cliquez sur la liste **Fonctionnalités**, puis choisissez **NAT gateways (Passerelles NAT)**.
2. Choisissez **Créer une passerelle NAT** et configurez les options suivantes :
   * **Nom :** entrez `Lab NAT gateway`.
   * **Sous-réseau :** choisissez `Public Subnet` dans la liste déroulante.
   * Choisissez **Allouer une adresse IP Elastic**.
3. Choisissez **Créer une passerelle NAT**.
4. Vous allez à présent configurer le sous-réseau privé pour envoyer le trafic Internet vers la passerelle NAT :
   * Dans le volet de navigation de gauche, choisissez **Tables de routage**, puis sélectionnez **Private Route Table**.
   * Cliquez sur l'onglet **Routes**.
     > ℹ️ La table de routage affiche actuellement une seule entrée qui achemine le trafic localement au sein du VPC. Vous allez ajouter un acheminement supplémentaire pour envoyer le trafic Internet via la passerelle NAT.
   * Choisissez **Modifier des routes**.
   * Choisissez **Ajouter une route** et configurez les options suivantes :
     * **Destination :** entrez `0.0.0.0/0`.
     * **Cible :** choisissez **Passerelle NAT**, puis `nat-` dans la liste.
   * Sélectionnez **Enregistrer les modifications**.

*Le trafic réseau des ressources du sous-réseau privé qui souhaitent communiquer avec Internet est désormais dirigé vers la passerelle NAT, qui transmet la demande à Internet. Les réponses transitent par la passerelle NAT vers le sous-réseau privé.*

---

## ⚡ Défi facultatif : Test du sous-réseau privé

Ce défi est facultatif ; il est fourni au cas où il vous resterait du temps avant la fin de l'atelier.

Au cours de ce défi facultatif, vous allez lancer une instance EC2 dans le sous-réseau privé et confirmer qu'elle peut communiquer avec Internet.

### 🚀 Lancement d'une instance dans le sous-réseau privé

Au cours de cette tâche, vous allez lancer une instance EC2 dans le sous-réseau privé.

1. Suivez les instructions que vous avez utilisées pour lancer le serveur Bastion, puis configurez les options suivantes :
   * Dans la section **Nom et balises**, entrez `Private Instance`.
   * Dans la section **Application and OS Images (Amazon Machine Image)** :
     * **Démarrage rapide :** choisissez `Amazon Linux`.
     * **Amazon Machine Image (AMI) :** choisissez `Amazon Linux 2023 AMI`.
   * Dans la section **Type d'instance**, choisissez `t3.micro`.
   * Dans la section **Paire de clés (connexion)**, choisissez `Continuer sans paire de clés (déconseillé)`.
   * Dans la section **Paramètres réseau**, choisissez **Modifier** et configurez :
     * **VPC – obligatoire :** choisissez `Lab VPC`.
     * **Sous-réseau :** choisissez `Private Subnet` *(pas le sous-réseau public)*.
     * **Pare-feu (groupes de sécurité) :** choisissez `Créer un groupe de sécurité`.
     * **Nom du groupe de sécurité - obligatoire :** entrez `Private Instance SG`.
     * **Description - obligatoire :** entrez `Allow SSH from Bastion`.
     * **Règles des groupes de sécurité pour le trafic entrant :**
       * **Type :** choisissez `ssh`.
       * **Type de source :** choisissez `Personnalisé`.
       * **Source :** choisissez `10.0.0.0/16`.
   * Développez la section **Détails avancés** et pour **Données utilisateur - facultatif**, collez le script suivant :
     ```bash
     #!/bin/bash
     # Turn on password authentication for lab challenge
     echo 'lab-password' | passwd ec2-user --stdin
     sed -i 's|[#]*PasswordAuthentication no|PasswordAuthentication yes|g' /etc/ssh/sshd_config
     systemctl restart sshd.service
     ```
     > ℹ️ Ce script permet de se connecter à l'aide d'un mot de passe. Ce script est fourni pour écourter les étapes de l'atelier. Il n'est pas recommandé pour les déploiements d'instance normaux.
2. Choisissez **Lancer l'instance**.
3. Pour afficher l'instance lancée, choisissez **Afficher toutes les instances**.

### 💻 Connexion au serveur Bastion

L'instance que vous venez de lancer se trouve dans le sous-réseau privé, il n'est donc pas possible de se connecter directement à l'instance. Vous devez d'abord vous connecter au serveur Bastion dans le sous-réseau public, puis vous connecter à l'instance privée à partir du serveur Bastion.

1. Dans la Console de gestion AWS, dans la barre de recherche, saisissez et sélectionnez `EC2` pour ouvrir la Console de gestion EC2.
2. Dans le volet de navigation, sélectionnez **Instances**.
3. Dans la liste des instances, sélectionnez l'instance **Bastion Server**.
4. Sélectionnez **Connexion**.
5. Dans l'onglet **EC2 Instance Connect**, sélectionnez **Connexion**.
   > 💡 **Remarque :** Si vous préférez utiliser un client SSH pour vous connecter à l'instance EC2, consultez les instructions fournies dans *Connect to Your Linux Instance (Connexion à votre instance Linux)*.

### 🔗 Connexion à l'instance privée

Vous devriez maintenant être connecté(e) au serveur Bastion, qui se trouve dans le sous-réseau public. Laissez cette fenêtre de terminal ouverte pour pouvoir l'utiliser ultérieurement.

Vous allez maintenant vous connecter à l'instance privée, qui se trouve dans le sous-réseau privé.

1. Dans la console Amazon EC2, choisissez **Instances**, puis sélectionnez **Private Instance** *(désélectionnez toutes les autres instances)*.
2. Copiez la liste **Private IPv4 addresses (Adresses IPv4 privées)** *(dans la partie inférieure de la page)* dans votre presse-papiers.
   > ℹ️ Cette adresse IP est une adresse IP privée qui commence par `10.0.2.x` ou `10.0.3.x`. Cette adresse n'est pas accessible directement depuis Internet. C'est pourquoi vous vous êtes d'abord connecté au serveur Bastion. Vous allez maintenant vous connecter à l'instance privée.
3. Revenez dans la fenêtre de terminal et exécutez la commande suivante. Dans la commande, remplacez `PRIVATE-IP` par l'adresse IP que vous venez de copier dans votre presse-papiers :
   ```bash
   ssh PRIVATE-IP
