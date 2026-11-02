# Création d'un site web sur S3

## Présentation de l'atelier
Dans cet atelier, vous allez vous exercer à utiliser les commandes de l'interface de la ligne de commande AWS (AWS CLI) à partir d'une instance Amazon Elastic Compute Cloud (Amazon EC2) pour :
* créer un compartiment Amazon Simple Storage Service (Amazon S3) ;
* créer un utilisateur de Gestion des identités et des accès AWS (AWS IAM) disposant d'un accès complet au service Amazon S3;
* charger des fichiers dans Amazon S3 pour héberger un site web simple pour le café-pâtisserie ;
* créer un fichier de commandes utilisable pour mettre à jour le site web statique lorsque vous modifiez localement l'un des fichiers du site web.

Les clients pourront accéder au site web que vous avez déployé sur Amazon S3. L'URL du site web est similaire à cet exemple : `http://<nom-du-compartiment>.s3-website-us-west-2.amazonaws.com`. Vous pouvez créer le compartiment et y accéder par le biais de la console de gestion AWS ou de l'AWS CLI.

---

## Objectifs
À la fin de cet atelier, vous serez en mesure d'effectuer les opérations suivantes :
* Exécuter des commandes de l'AWS CLI qui utilisent les services IAM et Amazon S3.
* Déployer un site web statique dans un compartiment S3.
* Créer un script qui utilise l'AWS CLI pour copier des fichiers d'un répertoire local vers Amazon S3.

---

## Durée
Cette activité dure environ 45 minutes.

---

## Accès à la console de gestion AWS
1. En haut de ces instructions, choisissez **Start Lab** (Démarrer l'atelier) pour lancer l'atelier.
2. Attendez que le message « Lab status: ready » (Statut de l'atelier : prêt) s'affiche, puis cliquez sur **X** pour fermer le volet **Start Lab** (Démarrer l'atelier).
3. À côté de **Start Lab** (Démarrer l'atelier), choisissez **AWS** pour ouvrir la console de gestion AWS dans un nouvel onglet de navigateur. Le système vous y connecte automatiquement.
   > **Conseil :** si le nouvel onglet ne s'affiche pas, une bannière ou une icône située en haut du navigateur peut indiquer que votre navigateur bloque l'ouverture des fenêtres contextuelles. Cliquez sur la bannière ou l'icône, puis choisissez **Autoriser les pop-ups** (Autoriser les fenêtres contextuelles).
4. Disposez la console de gestion AWS de façon à l'afficher à côté de ces instructions.

> **Important :** ne modifiez pas la région de l'atelier, sauf si vous y êtes invité.

---

## Tâche 1 : connexion à une instance EC2 Amazon Linux via SSM
Au cours de cette tâche, vous vous connectez à votre instance Amazon EC2 à l'aide d'AWS Systems Manager Session Manager.

1. Cliquez sur le bouton **Détails** en haut de la fenêtre, puis choisissez **Afficher**.
2. Copiez la valeur `InstanceSessionUrl` dans la liste, puis collez-la dans un nouvel onglet du navigateur web.
3. Une connexion entre la console et l'instance s'établit dans la fenêtre du navigateur web avec `ssm-user` et une invitation s'affiche.
4. Exécutez les commandes suivantes pour modifier l'utilisateur et le répertoire de base :
   ```bash
   sudo su -l ec2-user
   ```
   ```bash
   pwd
   ```

> **Remarque :** il s'agit du terminal SSH dans lequel vous exécutez les commandes comme indiquées tout au long de l'atelier.

---

## Tâche 2 : configuration de l'AWS CLI
Contrairement aux autres distributions Linux disponibles via Amazon Web Services (AWS), l'interface de ligne de commande AWS est déjà préinstallée sur les instances Amazon Linux.

Dans la fenêtre du terminal de la session SSH, exécutez la commande `aws configure` pour mettre à jour le logiciel AWS CLI avec les justificatifs.

### Configurer AWS
```bash
aws configure
```
À l'invite, configurez les paramètres suivants :
* **AWS Access Key ID (Identifiant de la clé d'accès AWS) :** copiez la valeur du champ `AccessKey` du volet de gauche et collez-la dans la fenêtre du terminal.
* **AWS Secret Access Key (Clé d'accès secrète AWS) :** copiez la valeur du champ `SecretKey` du volet de gauche et collez-la dans la fenêtre du terminal.
* **Nom de la région par défaut :** entrez `us-west-2`.
* **Format de sortie par défaut :** entrez `json`.

---

## Tâche 3 : création d'un compartiment S3 à l'aide de l'AWS CLI
La commande `s3api` crée un nouveau compartiment S3 avec les justificatifs AWS dans cet atelier. Par défaut, le compartiment S3 est créé dans la région `us-east-1`.

> **Conseil :** dans cet atelier, vous pouvez utiliser la commande `s3api` ou la commande `s3`. Les commandes `s3` exploitent les opérations des commandes `s3api`.

Vous créez un nouveau compartiment S3, le compartiment doit avoir un nom unique, tel que l'initiale de votre prénom, suivie de votre nom et de trois chiffres aléatoires. Par exemple, pour l'utilisateur Terry Whitlock, un nom de compartiment pourrait être `twhitlock256`.

Pour créer un compartiment dans Amazon S3, vous utilisez la commande `aws s3api create-bucket`. Lorsque vous utilisez cette commande pour créer un compartiment S3, vous incluez également les éléments suivants :
* `--region us-west-2`
* Ajoutez `--create-bucket-configuration LocationConstraint=us-west-2` à la fin de la commande.

Voici un exemple de commande qui permet de créer un nouveau compartiment S3. Vous pouvez utiliser `twhitlock256` comme nom de compartiment ou vous pouvez remplacer `<twhitlock256>` par un nom de compartiment que vous préférez pour cet atelier :

```bash
aws s3api create-bucket --bucket <twhitlock256> --region us-west-2 --create-bucket-configuration LocationConstraint=us-west-2
```

Si la commande réussit, vous obtenez une réponse au format JSON avec une paire nom-valeur `Location`, où la valeur reflète le nom du compartiment. Voici un exemple :
```json
{
        "Location": "http://twhitlock256.s3.amazonaws.com/"
}
```

---

## Tâche 4 : création d'un nouvel utilisateur IAM disposant d'un accès complet à Amazon S3
La commande `aws iam create-user` de l'AWS CLI crée un nouvel utilisateur IAM pour votre compte AWS. L'option `--user-name` est utilisée pour créer le nom de l'utilisateur et doit être unique au sein du compte.

1. À l'aide de l'AWS CLI, créez un nouvel utilisateur IAM avec la commande `aws iam create-user` et le nom d'utilisateur `awsS3user` :
   ```bash
   aws iam create-user --user-name awsS3user
   ```

2. Créez un profil de connexion pour le nouvel utilisateur à l'aide de la commande suivante :
   ```bash
   aws iam create-login-profile --user-name awsS3user --password Training123!
   ```

3. Copiez le numéro de compte AWS :
   * Dans la console de gestion AWS, choisissez le menu déroulant du compte `VocLabsUser…` situé en haut à droite de l'écran.
   * Copiez le numéro à 12 chiffres du champ **ID de compte**.
   * Dans le menu déroulant actuel, choisissez **Déconnexion**.

4. Connectez-vous à la console de gestion AWS en tant que nouvel utilisateur `awsS3user` :
   * Dans l'onglet du navigateur à partir duquel vous venez de vous déconnecter de la console de gestion AWS, choisissez **Log back in** (Se reconnecter) ou **Se connecter à la console**.
   * Dans l'écran de connexion, choisissez la case d'option **Utilisateur IAM**.
   * Dans le champ de texte, collez ou saisissez l'ID du compte sans tirets.
   * Choisissez **Suivant**.
   * Un nouvel écran de connexion s'affiche avec le champ **Connexion en tant qu'utilisateur IAM**. L'ID de compte est renseigné sur la base de l'écran précédent.
   * Pour **Nom d'utilisateur IAM**, entrez `awsS3user`.
   * Pour **Mot de passe**, entrez `Training123!`.
   * Choisissez **Connexion**.

5. Dans la console de gestion AWS, dans la zone **Rechercher**, entrez `S3` et choisissez **S3**. Cette option vous redirige vers la page de la console Amazon S3.
   > **Remarque :** le compartiment que vous avez créé peut ne pas être visible. Actualisez la page de la console Amazon S3 pour voir s'il apparaît. L'utilisateur `awsS3user` n'a pas d'accès Amazon S3 au compartiment que vous avez créé. Il se peut donc que vous obteniez une erreur pour l'accès à ce compartiment.

6. Dans la fenêtre du terminal, recherchez la politique gérée par AWS qui accorde l'accès complet à Amazon S3 en exécutant la commande suivante :
   ```bash
   aws iam list-policies --query "Policies[?contains(PolicyName,'S3')]"
   ```
   Le résultat affiche les politiques qui ont un attribut `PolicyName` contenant le terme S3. Recherchez la politique qui accorde un accès complet à Amazon S3. Vous utiliserez cette politique à l'étape suivante.

7. Pour accorder à l'utilisateur `awsS3user` un accès complet au compartiment S3, remplacez `<policyYouFound>` dans la commande suivante par l'attribut `PolicyName` approprié figurant dans les résultats, et exécutez la commande modifiée :
   ```bash
   aws iam attach-user-policy --policy-arn arn:aws:iam::aws:policy/<policyYouFound> --user-name awsS3user
   ```

8. Revenez à la console de gestion AWS et actualisez l'onglet du navigateur.

---

## Tâche 5 : ajustement des autorisations du compartiment S3
1. Dans la console de gestion AWS, dans la console Amazon S3, choisissez le nom de votre compartiment.
2. Accédez aux autorisations, puis, sous **Bloquer l'accès public (paramètres de compartiment)**, choisissez **Modifier**.
3. Désélectionnez **Bloquer tous les accès publics**.
4. Sélectionnez **Enregistrer les modifications** (et confirmer si vous y êtes invité).
5. Dans l'onglet Autorisations, sous **Propriétaire de l'objet**, choisissez **Modifier**.
6. Choisissez **Listes ACL activées**.
7. Choisissez **Je reconnais que les ACL seront restaurées**.
8. Sélectionnez **Enregistrer les modifications**.

---

## Tâche 6 : extraction des fichiers requis pour cet atelier
Un fichier contenant le contenu `static-website` du compartiment Amazon S3 devra être extrait à l'étape suivante.

1. De retour dans le terminal SSH, extrayez les fichiers dont vous avez besoin pour cet atelier en exécutant les commandes suivantes :
   ```bash
   cd ~/sysops-activity-files
   tar xvzf static-website-v2.tar.gz
   cd static-website
   ```

2. Pour confirmer que les fichiers ont été correctement extraits, exécutez la commande `ls`. 
   Vous devriez voir un fichier nommé `index.html` et des répertoires nommés `css` et `images`.

---

## Tâche 7 : chargement des fichiers dans Amazon S3 à l'aide de l'AWS CLI
Une fois les fichiers extraits, vous chargez leur contenu dans Amazon S3. Ces fichiers incluent ce que vous avez exploré quand vous avez exécuté la commande `ls`.

1. Pour que le compartiment puisse fonctionner comme un site web, remplacez `<my-bucket>` dans la commande suivante par votre nom de compartiment, et exécutez la commande modifiée :
   ```bash
   aws s3 website s3://<my-bucket>/ --index-document index.html
   ```
   Ce processus permet de s'assurer que le fichier `index.html` sera connu comme le document d'index.

2. Pour charger les fichiers dans le compartiment, remplacez `<my-bucket>` dans la commande suivante par votre nom de compartiment, et exécutez la commande modifiée :
   ```bash
   aws s3 cp /home/ec2-user/sysops-activity-files/static-website/ s3://<my-bucket>/ --recursive --acl public-read
   ```
   Notez que la commande de chargement inclut un paramètre de liste de contrôle d'accès (ACL). Ce paramètre indique que les fichiers chargés ont un accès public en lecture. Il inclut également le paramètre `recursive`, qui indique que tous les fichiers du répertoire actuel de votre machine doivent être chargés.

3. Pour vérifier que les fichiers ont été chargés, remplacez `<my-bucket>` dans la commande suivante par votre nom de compartiment, et exécutez la commande modifiée :
   ```bash
   aws s3 ls <my-bucket>
   ```

4. Dans la console de gestion AWS, dans la console Amazon S3, choisissez le nom de votre compartiment.

5. Choisissez l'onglet **Propriétés**. En bas de cet onglet, notez que le champ **Hébergement de site Web statique** a pour valeur **Activé**. L'exécution de la commande `aws s3 website` de l'AWS CLI active l'hébergement de site web statique pour un compartiment Amazon S3. Cette option est généralement désactivée par défaut.

6. Pour ouvrir l'URL dans une nouvelle page, choisissez l'URL **Point de terminaison de site Web de compartiment** qui s'affiche.

Félicitations ! Vous avez créé un site web statique accessible au public.

---

## Tâche 8 : création d'un fichier de commandes pour pouvoir répéter la mise à jour du site web
Pour créer un déploiement reproductible, vous créez un fichier de commandes à l'aide de l'éditeur VI.

1. Dans la fenêtre de terminal, extrayez l'historique des commandes récentes à l'aide de la commande suivante :
   ```bash
   history
   ```
   Recherchez la ligne dans laquelle vous avez exécuté la commande `aws s3 cp`. Vous allez placer cette ligne dans votre nouveau fichier de commandes.

2. Pour modifier les répertoires et créer un fichier script, exécutez la commande suivante dans la session de terminal SSH :
   ```bash
   cd ~
   touch update-website.sh
   ```

3. Pour ouvrir le fichier vide dans l'éditeur VI, exécutez la commande suivante :
   ```bash
   vi update-website.sh
   ```

4. Pour activer le mode édition dans l'éditeur VI, appuyez sur `i`.

5. À présent, vous allez ajouter la première ligne standard d'un fichier bash, puis ajouter la ligne `s3 cp` de votre historique. Pour cela, remplacez `<my-bucket>` dans la commande suivante par votre nom de compartiment, et copiez et collez la commande modifiée dans votre fichier :
   ```bash
   #!/bin/bash
   aws s3 cp /home/ec2-user/sysops-activity-files/static-website/ s3://<my-bucket>/ --recursive --acl public-read
   ```

6. Pour enregistrer les modifications et quitter le fichier, appuyez sur `Échap`, entrez `:wq` et appuyez sur `Entrée`.

7. Pour faire du fichier un fichier de commandes exécutable, exécutez la commande suivante :
   ```bash
   chmod +x update-website.sh
   ```

8. Pour ouvrir la copie locale du fichier `index.html` dans un éditeur de texte, exécutez la commande suivante :
   ```bash
   vi sysops-activity-files/static-website/index.html
   ```

9. Pour activer le mode édition dans l'éditeur VI, appuyez sur `i` et modifiez le fichier comme suit :
   * Recherchez la première ligne contenant le code HTML `bgcolor="aquamarine"` et remplacez ce code par `bgcolor="gainsboro"`.
   * Recherchez la ligne contenant le code HTML `bgcolor="orange"` et remplacez ce code par `bgcolor="cornsilk"`.
   * Recherchez la deuxième ligne contenant le code HTML `bgcolor="aquamarine"` et remplacez ce code par `bgcolor="gainsboro"`.

10. Pour enregistrer les modifications et quitter le fichier, appuyez sur `Échap`, entrez `:wq` et appuyez sur `Entrée`.

11. Pour mettre à jour le site web, exécutez votre fichier de commandes :
    ```bash
    ./update-website.sh
    ```
    > **Remarque :** la sortie de la ligne de commande doit indiquer que les fichiers ont été copiés dans Amazon S3.

12. Pour voir les modifications proposées au site web, revenez dans le navigateur et actualisez la page du café-pâtisserie.

Félicitations ! Vous venez d'effectuer votre première révision du site web.

Vous disposez désormais d'un outil (le script que vous avez créé) que vous pouvez utiliser pour transférer (push) les modifications des fichiers sources de votre site web vers Amazon S3.

---

## Défi facultatif
Avez-vous remarqué que votre fichier de commandes charge chaque fichier dans Amazon S3 chaque fois que vous l'exécutez, même lorsque la plupart des fichiers n'ont pas été modifiés ?

1. Consultez le document suivant : *Documentation de référence AWS CLI pour sync*.
2. Apportez une légère modification au fichier `index.html`. Par exemple, modifiez l'une des couleurs et enregistrez la modification.
3. Exécutez le fichier de commandes mis à jour.

Pour rendre votre script plus efficace, vous remplacez la commande `aws s3 cp` que vous avez utilisée par la commande `aws s3 sync` de ce document. Voici un exemple de la commande `aws s3 sync` que vous exécutez dans la fenêtre du terminal SSH. Dans cette commande, remplacez `<my-bucket>` par votre nom de compartiment :

```bash
aws s3 sync /home/ec2-user/sysops-activity-files/static-website/ s3://<my-bucket>/ --acl public-read
```

Actualisez le site du café-pâtisserie pour voir vos modifications.

En quoi la commande `aws s3 sync` s'est-elle avérée plus efficace que la commande `aws s3 cp` ? La commande `aws s3 sync` a-t-elle mis à jour uniquement le fichier `index.html` ou a-t-elle chargé tous les fichiers comme la commande `aws s3 cp` ?

---

## Conclusion
Félicitations ! Vous avez réussi à effectuer les tâches suivantes :
* Exécuter des commandes de l'AWS CLI qui utilisent les services IAM et Amazon S3
* Déployer un site web statique dans un compartiment S3
* Créer un script qui utilise l'AWS CLI pour copier des fichiers d'un répertoire local vers Amazon S3
