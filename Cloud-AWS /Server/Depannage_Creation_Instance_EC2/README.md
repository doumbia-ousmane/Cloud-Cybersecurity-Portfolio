# Dépannage de la création d'une instance EC2

## Présentation de l'activité

Dans le cadre de cette activité, vous allez utiliser l'interface de la ligne de commande AWS (AWS CLI) pour lancer des instances Amazon Elastic Compute Cloud (Amazon EC2).

Lors de la création de l'instance, vous allez indiquer un script de données utilisateur pour la configurer de façon à ce qu'un serveur web Apache, une base de données relationnelle MariaDB (qui est une branche de la base de données relationnelle MySQL) et PHP soient exécutés sur cette instance. Ensemble, ces packages logiciels installés sur une seule machine sont souvent appelés pile LAMP (Linux, serveur web Apache, MySQL et PHP). L'utilisation d'une pile LAMP est un moyen courant de créer un site web avec un backend de base de données sur une seule machine.

Ce même fichier de données utilisateur va déployer les fichiers de site web et exécuter les scripts de configuration de la base de données sur l'instance. Le résultat sera une instance hébergeant l'application web Café.

Le schéma suivant montre l'architecture que vous allez créer lors de cette activité.

## Objectifs

À la fin de cette activité, vous serez en mesure d'effectuer les tâches suivantes :

* Lancer une instance EC2 à l'aide de l'AWS CLI

* Dépanner les commandes de l'AWS CLI et les paramètres du service Amazon EC2 à l'aide de conseils de dépannage de base et de l'utilitaire open source `nmap`

## Durée

Cette activité dure environ 45 minutes.

## Accès à la console de gestion AWS

1. En haut de ces instructions, choisissez **Start Lab** (Démarrer l'atelier) pour lancer l'atelier.

2. Un volet **Start Lab** (Démarrer l'atelier) s'ouvre et affiche le statut de l'atelier.

3. Attendez que le message *« Lab status: ready »* (Statut de l'atelier : prêt) s'affiche, puis cliquez sur **X** pour fermer le volet **Start Lab** (Démarrer l'atelier).

4. À côté de **Start Lab** (Démarrer l'atelier), sélectionnez **AWS** pour ouvrir la console de gestion AWS dans un nouvel onglet de navigateur. Le système vous y connecte automatiquement.

   > **Conseil :** si le nouvel onglet ne s'affiche pas, une bannière ou une icône située en haut du navigateur peut indiquer que votre navigateur bloque l'ouverture des fenêtres contextuelles. Cliquez sur la bannière ou l'icône, puis choisissez **Allow pop-ups** (Autoriser les fenêtres contextuelles).

5. Disposez la console de gestion AWS de façon à l'afficher à côté de ces instructions.

> **Important :** ne modifiez pas la région de l'atelier, sauf si vous y êtes invité.

## Tâche 1 : connexion à l'instance CLI Host

Au cours de cette tâche, vous allez utiliser EC2 Instance Connect pour vous connecter à l'instance EC2 CLI Host qui a été créée lors de la mise en service de l'atelier. Vous utiliserez cette instance pour exécuter les commandes CLI.

1. Dans la barre de recherche de la Console de gestion AWS, saisissez et sélectionnez **EC2** pour ouvrir la Console de gestion Amazon EC2.

2. Dans le volet de navigation, sélectionnez **Instances**.

3. Dans la liste des instances, sélectionnez l'instance **CLI Host**.

4. Au-dessus de la liste des instances, sélectionnez **Connexion**.

5. Dans l'onglet **EC2 Instance Connect**, sélectionnez **Connexion**.

   > **Remarque :** si vous préférez utiliser un client SSH pour vous connecter à l'instance EC2, consultez les instructions fournies dans *Connect to Your Linux Instance (Connexion à votre instance Linux)*.

Maintenant que vous êtes connecté à l'instance CLI Host, vous pouvez configurer et utiliser l'AWS CLI pour appeler les services AWS.

## Tâche 2 : configuration de l'AWS CLI

Au cours de cette tâche, vous allez configurer l'AWS CLI en fournissant les paramètres de configuration mis à votre disposition lors de la mise en service de l'atelier. Après la configuration, vous allez exécuter des commandes CLI pour interagir avec les services AWS.

> **Remarque :** l'AWS CLI est déjà préinstallée sur les Amazon Machine Image (AMI) Amazon Linux.

Pour configurer le profil de l'AWS CLI avec des justificatifs, exécutez la commande suivante :

```
aws configure

```

> **Conseil :** dans EC2 Instance Connect, vous devrez peut-être utiliser le menu contextuel (clic droit) pour coller des valeurs dans le terminal.

À l'invite, saisissez les informations suivantes :

* **AWS Access Key ID (Identifiant de la clé d'accès AWS) :** en haut de ces instructions, sélectionnez **Détails**, puis **Afficher**. Copiez la valeur `AccessKey` et collez-la dans la fenêtre du terminal.

* **AWS Secret Access Key (Clé d'accès secrète AWS) :** copiez la valeur `SecretKey` dans les instructions de l'atelier et collez-la dans la fenêtre du terminal.

* **Default region name (Nom de région par défaut) :** copiez la valeur `LabRegion` dans les instructions de l'atelier et collez-la dans la fenêtre du terminal.

* **Default output format (Format de sortie par défaut) :** entrez `json`.

## Tâche 3 : création d'une instance EC2 à l'aide de l'AWS CLI

Au cours de cette tâche, vous allez observer et exécuter un script shell, qui vous a été fourni, pour créer une instance LAMP EC2 à l'aide de commandes de l'AWS CLI. Ce script contient volontairement des erreurs. Le défi consiste à trouver les problèmes et à les résoudre. Au fur et à mesure que vous résolvez chaque problème, vous pouvez exécuter le script à nouveau pour vérifier la résolution du problème.

### Tâche 3.1 : observation des détails du script

Tout d'abord, créez une sauvegarde du script que vous allez modifier ultérieurement.

1. Pour passer dans le répertoire où se trouve le fichier de script et en créer une sauvegarde, exécutez les commandes suivantes :

   ```
   cd ~/sysops-activity-files/starters
   cp create-lamp-instance-v2.sh create-lamp-instance.backup
   
   ```

   > **Conseil :** une bonne pratique consiste à sauvegarder les fichiers avant de les modifier.

2. Ouvrez le fichier de script `create-lamp-instance-v2.sh` dans un éditeur de texte de ligne de commande tel que VI.

   > **Conseil :** pour ouvrir le fichier en mode lecture seule dans l'éditeur VI, utilisez la commande suivante :
   >
   > ```
   > view create-lamp-instance-v2.sh
   > 
   > ```

3. Analysez le contenu du script :

   > **Conseil :** si vous utilisez VI, vous pouvez afficher les numéros de ligne en saisissant `:set number`, puis en appuyant sur **Entrée**.

   * **Ligne 1 :** il s'agit d'un fichier bash, donc la première ligne contient `#!/bin/bash`.

   * **Lignes 7 à 11 :** la taille d'instance est définie sur `t3.small`, ce qui doit être suffisant pour exécuter la base de données et le serveur web.

   * **Lignes 16 à 29 :** le script appelle la commande `describe-regions` de l'AWS CLI pour obtenir la liste de toutes les régions AWS. Dans chaque région, le script recherche un VPC existant nommé `Cafe VPC`. Après avoir trouvé le VPC, le script capture l'ID de VPC et la Région, puis sort de la boucle `while`. C'est le VPC où l'instance LAMP de l'application web Café doit être déployée.

   * **Lignes 31 à 55 :**
     * le script appelle les commandes de l'AWS CLI pour rechercher les valeurs des champs ID de sous-réseau, Nom de la paire de clés et ID d'AMI qui sont nécessaires pour créer l'instance EC2.
     * Notez que la ligne 32 se termine par une barre oblique inversée (`\`). Ce caractère peut être utilisé pour renvoyer une seule commande sur une autre ligne dans le fichier de script. Cette technique est utilisée plusieurs fois dans le script pour faciliter sa lecture.

   * **Lignes 57 à 122 :** le script nettoie le compte AWS pour éliminer les situations où ce script a déjà été exécuté sur le compte et est maintenant à nouveau en cours d'exécution. Le script vérifie s'il existe déjà une instance nommée `cafeserver` et un groupe de sécurité incluant `cafeSG` dans son nom. S'il trouve ces ressources, le script vous invite à les supprimer.

   * **Lignes 124 à 152 :** le script crée un nouveau groupe de sécurité avec les ports 22 et 80 ouverts.

   * **Lignes 154 à 168 :**
     * le script crée une nouvelle instance EC2. Notez que cette partie du script utilise les valeurs qui étaient définies dans les lignes 8 et 10, et celles qui ont été collectées dans les lignes 16 à 57.
     * Notez la référence au fichier de données utilisateur. Vous passerez en revue les détails de ce fichier lors d'une autre étape.
     * L'appel complet pour créer l'instance est capturé dans une variable nommée `instanceDetails`. Le contenu de cette variable est ensuite affiché dans la fenêtre de terminal à la ligne 177, et il est mis en forme pour faciliter l'affichage à l'aide d'un outil Python JSON.

   * **Lignes 179 à 188 :** la valeur `instanceId` est analysée à partir de la variable `instanceDetails`. Ensuite, une boucle `while` vérifie toutes les 10 secondes si une adresse IP publique a été attribuée à l'instance. Lorsque la vérification aboutit, l'adresse IP publique est écrite dans la fenêtre de terminal.

4. Quittez l'éditeur de texte.

   > **Conseil :** si vous utilisez VI, entrez `:q!`

5. Pour afficher le contenu du script de données utilisateur, exécutez la commande suivante :

   ```
   cat create-lamp-instance-userdata-v2.txt
   
   ```

   Notez la manière dont le script de données utilisateur exécute une série de commandes sur l'instance après son lancement. Ces commandes installent un serveur web, PHP et un serveur de base de données.

### Tâche 3.2 : tentative d'exécution du script

Maintenant que vous avez une idée des tâches que ce script shell est conçu pour effectuer, essayez de l'exécuter :

```
./create-lamp-instance-v2.sh

```

Le script échoue et se ferme sans aboutir. Ce comportement est normal.

### Tâche 3.3 : résolution des problèmes

#### Problème n° 1

La sortie du terminal affiche le message suivant :
> *« An error occurred (InvalidAMIID.NotFound) when calling the RunInstances operation: The image id '[ami-xxxxxxxxxx]' does not exist. »* (Une erreur s'est produite (InvalidAMIID.NotFound) lors de l'appel de l'opération RunInstances : l'ID d'image [ami-xxxxxxxxxx] n'existe pas.)

##### Conseils pour vous aider à résoudre le problème n° 1 :

* Localisez la ligne du script qui a provoqué cette erreur. Est-ce que quelque chose semble incorrect dans le script ?

* La valeur de région correcte a-t-elle été utilisée pour la commande `run-instances` ?

Après avoir identifié le problème, mettez le script à jour afin de le résoudre, puis exécutez à nouveau le script. Si vous êtes invité à supprimer des instances ou des groupes de sécurité existants créés lors de l'exécution précédente du script, répondez toujours par **Y**. L'erreur est-elle résolue ?

Une fois que vous avez résolu le problème, la commande `run-instances` aboutit et une adresse IPv4 publique est attribuée à la nouvelle instance.

##### Essayez de vous connecter à la page web :

Dans un navigateur, accédez à l'adresse suivante. Remplacez `<public-ip>` par l'adresse IPv4 publique de la nouvelle instance que vous avez créée :
`http://<public-ip>`

La tentative échoue. Vous devez résoudre le problème n° 2.

#### Problème n° 2

La commande `run-instances` aboutit et une adresse IP publique est attribuée à la nouvelle instance. Toutefois, vous ne pouvez pas charger la page web de test.

Connectez-vous à la nouvelle instance LAMP à l'aide d'EC2 Instance Connect, qui est la méthode que vous avez utilisée pour vous connecter à l'instance CLI Host.

##### Conseils pour vous aider à résoudre le problème n° 2 :

* Le serveur web s'exécute sur le port TCP 80. Est-il ouvert ?

* Pouvez-vous vérifier que le service de serveur web est en cours d'exécution ? Le nom du service de serveur web est `httpd`.

1. Dans la fenêtre de terminal de l'instance CLI Host, exécutez la commande suivante pour installer `nmap`, qui est un outil d'analyse des ports :

   ```
   sudo yum install -y nmap
   
   ```

2. Exécutez ensuite la commande suivante. Remplacez `<public-ip>` par l'adresse IPv4 publique réelle de votre instance LAMP :

   ```
   nmap -Pn <public-ip>
   
   ```

   La sortie de cette commande affiche les ports qui sont accessibles. Les résultats correspondent-ils à ce que vous attendiez ? Savez-vous ce qui doit être modifié d'après la sortie ?

##### Testez l'exécution du script de données utilisateur :

Après avoir identifié et résolu le problème, accédez à l'adresse suivante dans un navigateur. Remplacez `<public-ip>` par l'adresse IPv4 publique de la nouvelle instance que vous avez créée :
`http://<public-ip>`

Si vous avez résolu le problème n° 2, vous devriez voir le message suivant : *« Hello From Your Web Server! »* (Bonjour de votre serveur web !)

##### Consultez le fichier journal qui indique si le script de données utilisateur s'est exécuté comme prévu :

1. Dans la fenêtre de terminal de l'instance LAMP, exécutez la commande suivante afin de voir les entrées du fichier journal à mesure qu'elles sont écrites :

   ```
   sudo tail -f /var/log/cloud-init-output.log
   
   ```

   Sur une instance Amazon Linux, le service `cloud-init` exécute les commandes du fichier de données utilisateur.

2. Observez les entrées du fichier journal. Notez le message relatif à l'installation de MariaDB et PHP. Il ne devrait y avoir aucun message d'erreur.

3. Vous devriez également voir les messages relatifs aux fichiers de l'application web Café qui ont été téléchargés et extraits sur cette instance, tel que *« Create Database script completed »* (Script Créer une base de données terminé). Lorsque vous avez terminé vos observations, entrez `Ctrl+C` pour quitter l'utilitaire `tail`.

   > **Conseil :** pour afficher l'intégralité du fichier journal, exécutez :
   >
   > ```
   > sudo cat /var/log/cloud-init-output.log
   > 
   > ```

## Tâche 4 : vérification des fonctionnalités du site web

1. **Vérifiez que le site web est déployé :**
   Dans un navigateur, accédez à l'adresse suivante. Remplacez `<public-ip>` par l'adresse IPv4 publique de la nouvelle instance que vous avez créée :
   `http://<public-ip>/cafe`

   Si l'opération aboutit, vous devriez voir la page d'accueil du site web Café. Félicitations !

2. **Testez si vous pouvez commander des articles sur le site web :**
   * Cliquez sur le lien **Menu**. Une nouvelle page se charge à l'adresse `http://<public-ip>/cafe/menu.php`.

   * Choisissez quelques desserts à commander, puis sélectionnez **Submit Order** (Envoyer la commande). La page **Order Confirmation** (Confirmation de commande) s'affiche et présente les détails des articles.

   * Passez une autre commande d'articles différents. Ensuite, sélectionnez la page **Order History** (Historique des commandes). Les détails des deux commandes ont été enregistrés.

   > **Remarque :** les détails des commandes sont enregistrés et stockés dans la base de données qui s'exécute sur l'instance LAMP que vous avez lancée.

## Conclusion

Félicitations ! Vous avez réussi à effectuer les tâches suivantes :

* Lancer une instance EC2 à l'aide de l'AWS CLI

* Dépanner les commandes de l'AWS CLI et les paramètres du service Amazon EC2 à l'aide de conseils de dépannage de base et de l'utilitaire open source `nmap`
