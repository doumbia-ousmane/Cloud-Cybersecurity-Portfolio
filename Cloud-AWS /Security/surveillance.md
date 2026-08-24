# Surveillance d’une instance EC2

## Présentation de l'atelier
La journalisation et la surveillance sont deux techniques mises en place pour atteindre un objectif commun. Ensemble, elles garantissent les performances optimales d’un système et un cadre de sécurité. 

La journalisation désigne l’enregistrement et le stockage d’événements de données sous la forme de fichiers journaux. Les journaux contiennent des détails de faible niveau qui offrent une visibilité sur les performances de votre système ou de vos applications dans certaines circonstances. Sur le plan de la sécurité, la journalisation permet aux administrateurs de sécurité d’identifier des signaux d’alerte qui peuvent passer inaperçus sur leur système.

La surveillance désigne le processus d’analyse et de collecte de données qui permet de garantir des performances optimales. La surveillance permet de détecter les accès non autorisés et d’aligner l’utilisation de vos services avec la cadre de sécurité de votre organisation.

Au cours de cet atelier, vous allez créer une alarme Amazon CloudWatch qui se déclenche lorsque l’instance Amazon Elastic Compute Cloud (Amazon EC2) dépasse un certain seuil d’utilisation de la CPU (Central Processing Unit). Vous créerez un abonnement à l’aide du service Amazon Simple Notification Service (Amazon SNS) qui permet de vous envoyer un e-mail quand l’alarme se déclenche. Vous vous connecterez à l’instance EC2 pour exécuter un test de contrainte afin de pousser l’utilisation de la CPU de l’instance EC2 jusqu’à 100 %.

Ce test vise à simuler un acte de malveillance afin de prendre le contrôle de l’instance EC2 et créer un pic de la CPU. L’augmentation de la charge CPU a plusieurs causes possibles, dont la présence d’un logiciel malveillant.

### Objectifs
À la fin de cet atelier, vous serez en mesure d'effectuer les opérations suivantes :
- Créer une notification Amazon SNS
- Créer une alarme CloudWatch
- Soumettre une instance EC2 à un test de contrainte
- Confirmer qu’un e-mail Amazon SNS a été envoyé
- Créer un tableau de bord CloudWatch

### Durée
Cet atelier dure environ 60 minutes.

### Environnement de l'atelier
L’environnement d’atelier comprend une instance EC2 reconfigurée appelée **Stress Test** (Test de contrainte) associée à un rôle IAM (Identity and Access Management) AWS utilisé pour se connecter via le gestionnaire de session d’AWS Systems Manager.

Tous les composants backend, comme Amazon EC2, les rôles IAM et certains services AWS, ont déjà été intégrés à l’atelier. 

### Accès à AWS Management Console
1. En haut à droite de ces instructions, choisissez **Démarrer l’atelier**. 
   * **Conseil de dépannage :** Si vous recevez le message d’erreur *Access Denied (Accès refusé)*, fermez la fenêtre d’erreur, et choisissez de nouveau **Démarrer l’atelier**.
2. Les informations suivantes décrivent les différents états de l’atelier : 
   * Un cercle rouge à côté d'AWS dans le coin supérieur gauche de cette page indique que l'atelier n'a pas démarré.
   * Un cercle jaune à côté d'AWS dans le coin supérieur gauche de cette page indique que l'atelier est en cours de démarrage.
   * Un cercle vert à côté d'AWS dans le coin supérieur gauche de cette page indique que l'atelier est prêt.
3. Attendez que l’atelier soit prêt avant de continuer.
4. En haut de ces instructions, choisissez le cercle vert en regard d'AWS. 
   * Cette option permet d’accéder à AWS Management Console dans un nouvel onglet du navigateur. Le système s’y connecte automatiquement.
   * **Conseil :** Si le nouvel onglet ne s'affiche pas, une bannière ou une icône située en haut du navigateur peut indiquer que votre navigateur bloque l'ouverture des fenêtres contextuelles. Cliquez sur la bannière ou l'icône, puis sélectionnez **Allow pop-ups (Autoriser les fenêtres contextuelles)**.
5. Si un message vous invite à basculer vers la nouvelle page d’accueil de la console, choisissez **Switch to the new Console Home (Basculer vers la nouvelle page d’accueil de la console)**.
6. Placez l'onglet AWS Management Console et ces instructions côte à côte. L’idéal est de pouvoir afficher les deux onglets du navigateur en même temps pour suivre plus facilement les étapes de l'atelier.
7. Ne modifiez pas la région de l'atelier, sauf si vous y êtes invité.

---

## Tâche 1 : Configuration d'Amazon SNS
Au cours de cette tâche, vous allez créer une rubrique SNS et vous vous y abonnerez avec une adresse e-mail.

Amazon SNS est un service de messagerie entièrement géré destiné aux communications A2A (Application-to-Application) et A2P (Application-to-Person).

1. Dans **AWS Management Console**, saisissez `SNS` dans la barre de recherche, puis sélectionnez **Simple Notification Service (Service de notification simple)**.
2. Sur la gauche, cliquez sur le bouton, sélectionnez **Topics (Rubriques)**, puis choisissez **Create topic (Créer une rubrique)**.
3. Sur la page **Create topic (Créer une rubrique)**, dans la section **Details (Détails)**, configurez les options suivantes :
   * **Type :** choisissez **Standard**.
   * **Name (Nom) :** saisissez `MyCwAlarm`. 
4. Sélectionnez **Create topic (Créer une rubrique)**.
5. Sur la page de détails **MyCwAlarm**, cliquez sur l’onglet **Subscriptions (Abonnements)**, puis choisissez **Create subscription (Créer un abonnement)**.
6. Sur la page **Create subscription (Créer un abonnement)**, dans la section **Details (Détails)**, configurez les options suivantes :
   * **Topic ARN (ARN de la rubrique) :** Conservez l’option sélectionnée par défaut.
   * **Protocol (Protocole) :** Dans la liste déroulante, choisissez **Email**.
   * **Endpoint (Point de terminaison) :** saisissez une adresse e-mail valide à laquelle vous avez accès.
7. Sélectionnez **Create subscription (Créer un abonnement)**. 
8. Dans la section **Details (Détails)**, l’option **Status (Statut)** doit indiquer **Pending confirmation (En attente de confirmation)**. Vous devriez avoir reçu par e-mail le message *AWS Notification - Subscription Confirmation (Notification AWS - Confirmation de l’abonnement)* à l’adresse que vous avez spécifiée à l’étape précédente.
9. Ouvrez l’e-mail que vous avez reçu avec la notification d’abonnement Amazon SNS, et cliquez sur **Confirm subscription (Confirmer l’abonnement)**.
10. Retournez dans AWS Management Console. Dans le volet de navigation de gauche, choisissez **Subscriptions (Abonnements)**.
11. L’option **Status (Statut)** doit indiquer à présent **Confirmed (Confirmé)**.

### Résumé de la tâche 1
Au cours de cette tâche, vous avez créé une rubrique SNS et un abonnement à cette rubrique à l’aide d’une adresse e-mail. Avec cette rubrique, des alertes peuvent maintenant être envoyées à l’adresse e-mail associée à l’abonnement Amazon SNS.

---

## Tâche 2 : Création d'une alarme CloudWatch
Au cours de cette tâche, vous allez examiner certaines métriques et journaux stockés dans CloudWatch. Ensuite, vous créerez une alarme CloudWatch pour déclencher l’envoi d’un e-mail à la rubrique SNS dès que l’utilisation de la CPU de l’instance EC2 **Stress Test (Test de contrainte)** dépasse 60 %. 

CloudWatch est un service de surveillance et d'observabilité conçu pour les ingénieurs DevOps, les développeurs, les ingénieurs chargés de la fiabilité du site (SRE), les responsables informatiques et les chefs de produits. CloudWatch fournit les données et les informations exploitables dont vous avez besoin pour surveiller vos applications, réagir aux variations de performance sur l'ensemble du système et optimiser l'utilisation des ressources. CloudWatch collecte des données de surveillance et opérationnelles sous la forme de journaux, de métriques et d'événements. Vous disposez d’une vue complète de l’état opérationnel et d’une visibilité totale de vos ressources, applications et services AWS dans le cloud AWS et sur site.

1. Dans **AWS Management Console**, saisissez `CloudWatch` dans la barre de recherche, puis sélectionnez-le.
2. Dans le volet de navigation de gauche, cliquez dans la liste déroulante **Metrics (Métriques)**, puis choisissez **All metrics (Toutes les métriques)**.
   * En règle générale, à l’issue d’un délai de 5 à 10 minutes suivant la création d’une instance EC2, CloudWatch récupère les détails des métriques.
3. Sur la page **Metrics (Métriques)**, choisissez **EC2**, puis sélectionnez **Per-Instance Metrics (Métriques par instance)**.
   * Sur cette page, vous pouvez afficher toutes les métriques consignées et l’instance EC2 associée à ces métriques.
4. Cochez la case **CPUUtilization** de l’option **Metric name (Nom de métrique)** associée à l’instance EC2 **Stress Test (Test de contrainte)**.
   * Cette option affiche le graphique de la métrique d’utilisation de la CPU, qui doit normalement se rapprocher de 0 puisque rien n’a encore été fait.
5. Dans le volet de navigation de gauche, cliquez dans la liste déroulante **Alarms (Alarmes)**, puis choisissez **All alarms (Toutes les alarmes)**.
   * Vous allez créer une alarme de métrique. Une alarme de métrique surveille une seule métrique CloudWatch ou le résultat d'une expression mathématique basée sur des métriques CloudWatch. L'alarme effectue une ou plusieurs actions en fonction de la valeur de la métrique ou de l'expression par rapport à un seuil sur un certain nombre de périodes. L’action envoie alors une notification à la rubrique SNS que vous avez créée précédemment.
6. Sélectionnez **Create alarm (Créer une alarme)**.
7. Choisissez successivement **Select metric (Sélectionner une métrique)**, **EC2** et **Per-Instance Metrics (Métriques par instance)**.
8. Cochez la case **CPUUtilization** de l’option **Metric name (Nom de métrique)** associée au nom de l’instance **Stress Test (Test de contrainte)**.
9. Choisissez **Select metric (Sélectionner une métrique)**.
10. Sur la page **Specify metric and conditions (Spécifier les métriques et les conditions)**, configurez les options suivantes :
    * **Métrique**
      * **Metric name (Nom de métrique) :** Saisissez `CPUUtilization`
      * **InstanceId :** Conservez l’option sélectionnée par défaut.
      * **Statistic (Statistique) :** Saisissez `Average`
      * **Period (Période) :** Dans la liste déroulante, choisissez `1 minute`.
    * **Conditions**
      * **Threshold type (Type de seuil) :** Choisissez **Static (Statique)**.
      * **Whenever CPUUtilization is... (Lorsque l'utilisation de la CPU est...) :** Choisissez **Greater > threshold (Supérieure au seuil)**.
      * **than... (à...) Define the threshold value (définir la valeur du seuil) :** Saisissez `60`
11. Cliquez sur **Next (Suivant)**.
12. Sur la page **Configure actions (Configurer les actions)**, configurez les options suivantes :
    * **Notification**
      * **Alarm state trigger (Déclenchement de l'état d'alarme) :** Choisissez **In alarm (En état d'alarme)**.
      * **Select an SNS topic (Sélectionner une rubrique SNS) :** Choisissez **Select an existing SNS topic (Sélectionner une rubrique SNS existante)**.
      * **Send a notification to... (Envoyer une notification à...) :** Dans la zone de texte, choisissez `MyCwAlarm`.
13. Cliquez sur **Next (Suivant)**, puis configurez les options suivantes :
    * **Nom et description**
      * **Alarm name (Nom de l’alarme) :** Saisissez `LabCPUUtilizationAlarm`
      * **Alarm description - optional (Description de l’alarme – facultatif) :** Saisissez `CloudWatch alarm for Stress Test EC2 instance CPUUtilization`
14. Cliquez sur **Next (Suivant)**.
15. Lisez la page **Preview and create (Prévisualiser et créer)**, puis choisissez **Create alarm (Créer une alarme)**.

### Résumé de la tâche 2
Au cours de cette tâche, vous avez affiché certaines métriques Amazon EC2 dans CloudWatch. Vous avez ensuite créé une alarme CloudWatch qui déclenche un état **In alarm (En état d'alarme)** lorsque l’utilisation de la CPU dépasse 60 %. 

---

## Tâche 3 : Test de l'alarme CloudWatch
Au cours de cette tâche, vous allez vous connecter à l’instance EC2 **Stress Test (Test de contrainte)** et exécuter une commande qui teste la charge de la CPU à 100 %. Cette augmentation de l’utilisation de la CPU active l’alarme CloudWatch qui déclenche l’envoi par e-mail d’une notification Amazon SNS à l’adresse e-mail associée à la rubrique SNS.

1. Naviguez vers la page de la console Vocareum, et cliquez sur le bouton **AWS Details (Détails AWS)**.
2. En regard de **EC2InstanceURL** figure un lien. Copiez-le et collez-le dans un nouvel onglet du navigateur.
   * Ce lien permet de se connecter à l’instance EC2 **Stress Test (Test de contrainte)**. 
3. Pour augmenter manuellement la charge de la CPU de l’instance EC2, exécutez la commande suivante :
   ```bash
   sudo stress --cpu 10 -v --timeout 400s
   ```
   * Cette commande s’exécute pendant 400 secondes, charge la CPU à 100 %, puis réduit la charge jusqu’à 0 % à l’issue de la durée allouée.
4. Naviguez vers la page de la console Vocareum, et cliquez sur le bouton **AWS Details (Détails AWS)**.
5. Copiez-collez l’URL située en regard de **EC2InstanceURL** dans un autre onglet du navigateur pour ouvrir une deuxième session de l’instance **Stress Test (Test de contrainte)**.
6. Dans la nouvelle session de terminal, exécutez la commande suivante :
   ```bash
   top
   ```
   * Cette commande affiche l’utilisation de la CPU en direct.
7. Retournez sur la console AWS où est déjà ouverte la page **Alarms (Alarmes)** de CloudWatch.
8. Choisissez **LabCPUUtilizationAlarm**.
9. Surveillez le graphique en même temps que vous cliquez sur le bouton **refresh (actualiser)** toutes les minutes jusqu’à ce que le statut de l’alarme devienne **In alarm (En état d’alarme)**.
   * Le changement de statut **In alarm (En état d’alarme)** et l’envoi d’un e-mail ne prennent que quelques minutes.
   * Sur le graphique, vous noterez que la valeur `CPUUtilization` a augmenté et dépasse le seuil de 60 %.
10. Ouvrez votre boîte aux lettres électronique correspondant à l’adresse e-mail utilisée pour configurer l’abonnement Amazon SNS. Vous devriez avoir reçu un nouvel e-mail de notification du service **AWS Notifications (Notifications AWS)**.

### Résumé de la tâche 3
Au cours de cette tâche, vous avez exécuté une commande pour augmenter la charge de la CPU de l’instance EC2 à 100 % pendant 400 secondes. Cette augmentation de l’utilisation de la CPU a activé l’alarme dont l’état est passé à **In alarm (En état d'alarme)**, et vous avez confirmé le pic de charge de la CPU sur le graphique CloudWatch. Vous avez également reçu une notification par e-mail pour vous avertir du changement de statut **In alarm (En état d'alarme)**.

---

## Tâche 4 : Création d'un tableau de bord CloudWatch
Au cours de cette tâche, vous allez créer un tableau de bord CloudWatch à l’aide des mêmes métriques `CPUUtilization` utilisées précédemment dans l’atelier.

Les tableaux de bord CloudWatch sont des pages d'accueil personnalisables via la console CloudWatch que vous pouvez utiliser pour surveiller vos ressources dans une même vue. Avec les tableaux de bord CloudWatch, vous pouvez même surveiller les ressources réparties entre différentes régions. Vous pouvez utiliser les tableaux de bord CloudWatch pour créer des vues personnalisées des métriques et des alarmes de vos ressources AWS.

1. Naviguez jusqu’à la section **CloudWatch** de la console AWS. Dans le volet de navigation de gauche, sélectionnez **Dashboards (Tableaux de bord)**.
2. Cliquez sur **Create dashboard (Créer un tableau de bord)**.
3. Sous **Dashboard name (Nom du tableau de bord)**, saisissez `LabEC2Dashboard`, puis sélectionnez **Create dashboard (Créer un tableau de bord)**.
4. Choisissez **Line (Ligne)**.
5. Choisissez **Metrics (Métriques)**.
6. Sélectionnez **EC2**, puis choisissez **Per-Instance Metrics (Métriques par instance)**.
7. Cochez la case correspondant à **Stress Test (Test de contrainte)** pour **Instance name (Nom de l’instance)** et **CPUUtilization** pour **Metric name (Nom de métrique)**.
8. Sélectionnez **Create a widget (Créer un widget)**.
9. Cliquez sur **Save dashboard (Enregistrer le tableau de bord)**.

Vous venez de créer un raccourci pour accéder rapidement à l’affichage de la métrique `CPUUtilization` de l’instance **Stress Test (Test de contrainte)**.

---

## Récapitulatif de l'atelier
Au cours de cet atelier, vous avez créé une alarme CloudWatch qui a été activée lorsque l’utilisation de la CPU par l’instance **Stress Test (Test de contrainte)** a dépassé un seuil donné. Vous avez créé un abonnement à l’aide du service Amazon SNS qui vous a envoyé un e-mail lorsque l’alarme s’est déclenchée. Vous vous êtes connecté à l’instance EC2 pour exécuter un test de contrainte afin de pousser l’utilisation de la CPU de l’instance EC2 jusqu’à 100 %.

Ce test a simulé ce qui pourrait se passer si un acte malveillant devait prendre le contrôle d’une instance EC2 et créer un pic de la CPU. L’augmentation de la charge CPU a plusieurs causes possibles, dont la présence d’un logiciel malveillant.

---

## Conclusion
Félicitations ! Vous avez réussi à :
- Créer une notification Amazon SNS
- Configurer une alarme CloudWatch
- Soumettre une instance EC2 à un test de contrainte
- Confirmer qu’un e-mail Amazon SNS a été envoyé
- Créer un tableau de bord CloudWatch
