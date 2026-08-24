# Surveillance d’une instance EC2 avec Amazon CloudWatch et SNS

#### 📌 Présentation
Dans les infrastructures cloud modernes, la journalisation et la surveillance sont deux piliers fondamentaux pour garantir à la fois des performances optimales et un cadre de sécurité robuste [3]. Ce projet présente la mise en œuvre d'une solution de supervision et d'alerte automatisée sur AWS [4]. 

L'objectif principal est de configurer une alarme Amazon CloudWatch basée sur l'utilisation du processeur (CPU) d'une instance Amazon EC2 ("Stress Test") et de l'associer à une notification par e-mail en temps réel via Amazon Simple Notification Service (Amazon SNS) [4]. Pour valider le bon fonctionnement du dispositif, un test de contrainte (stress test) est exécuté directement sur l'instance pour pousser la charge CPU à 100 % et observer la détection automatique de cette anomalie [4].

---

#### 🎯 Objectifs
À l'issue de cet atelier, les objectifs techniques suivants ont été atteints et validés [5] :
* **Créer et configurer une rubrique de notification Amazon SNS** avec un abonnement e-mail opérationnel [5].
* **Créer et paramétrer une alarme CloudWatch** basée sur la métrique d'utilisation de la CPU d'une instance EC2 [5].
* **Soumettre l'instance Amazon EC2 à un test de contrainte** (stress test) pour simuler une surcharge [5].
* **Confirmer la détection et la notification de l'alerte** via la réception d'un e-mail d'alerte Amazon SNS [5].
* **Créer un tableau de bord d'observabilité centralisé CloudWatch** pour suivre les métriques d'utilisation en temps réel [5].

---

#### 🏢 Scénario
Ce cas d'usage simule une réponse à un acte de malveillance ou à un compromis de sécurité [5]. Un attaquant parvenant à prendre le contrôle d'une instance EC2 peut l'exploiter pour exécuter du code malveillant, miner de la cryptomonnaie ou mener des attaques par déni de service, ce qui engendre un pic d'utilisation anormal du processeur (CPU) [5]. 

Afin de protéger l'infrastructure et de minimiser le temps de détection d'une telle menace, il est nécessaire d'établir une surveillance continue [4]. Dès qu'un comportement suspect est identifié (traduit ici par une surcharge CPU persistante), l'administrateur de sécurité doit être immédiatement alerté afin d'initier les mesures de remédiation appropriées [6, 7].

---

#### 🔍 Périmètre du Lab
L'environnement de cet atelier s'appuie sur les composants suivants [8] :
* **Instance EC2 ("Stress Test")** : Instance virtuelle Linux préconfigurée sur laquelle la charge sera simulée [8].
* **Rôle IAM (Identity and Access Management)** : Profil d'instance attaché fournissant les autorisations nécessaires pour une connexion via le gestionnaire de session d'AWS Systems Manager [8].
* **AWS Systems Manager Session Manager** : Service utilisé pour se connecter à distance et de manière sécurisée au terminal de l'instance sans requérir de clés SSH privées ou d'ouverture de port réseau public [8].
* **Composants d'infrastructure AWS** : Services d'infrastructure de base déjà intégrés dans l'atelier pour supporter les services de supervision [8].

---

#### 🛠️ Technologies et outils utilisés

| Technologie / Service | Utilisation |
| :--- | :--- |
| **AWS IAM** | Gestion des accès et des rôles sécurisés pour connecter l'instance EC2 via Systems Manager sans clé d'accès statique [8]. |
| **Amazon EC2** | Instance virtuelle Linux ("Stress Test") faisant l'objet de la surveillance et soumise à la simulation d'incident [6, 8]. |
| **Amazon CloudWatch** | Collecte des métriques d'infrastructure (CPUUtilization), hébergement des alarmes de seuil et création de tableaux de bord personnalisés [6, 9, 10]. |
| **Amazon SNS (Simple Notification Service)** | Service de messagerie entièrement géré utilisé pour diffuser les alertes de sécurité par courrier électronique (modèle de publication/abonnement) [6, 11]. |
| **AWS Systems Manager (Session Manager)** | Outil d'administration pour ouvrir une session terminal sécurisée et chiffrée sur l'instance EC2 [8]. |
| **stress (Utilitaire Linux)** | Outil d'injection de charge CPU pour pousser l'utilisation du processeur de l'instance à 100 % pendant une durée définie [12]. |

---

#### 🧠 Concepts abordés

* **Journalisation vs Surveillance** : 
  * La *journalisation* est l'enregistrement et le stockage d'événements détaillés de bas niveau sous forme de fichiers journaux pour l'analyse a posteriori et la détection de signaux faibles de sécurité [3].
  * La *surveillance* est un processus continu de collecte, de mesure et d'analyse opérationnelle de métriques en temps réel pour s'assurer des performances optimales et détecter les accès non autorisés [4].
* **Alarme de métrique CloudWatch** : Dispositif de supervision évaluant une métrique spécifique par rapport à un seuil défini (statique ou dynamique) sur un nombre donné de périodes afin de déclencher des actions automatisées (notifications, redémarrages, etc.) [13].
* **Modèle de notification asynchrone (Pub/Sub)** : Modèle de communication d'Amazon SNS dans lequel un éditeur envoie des messages à une rubrique ("Topic"), qui sont ensuite automatiquement poussés vers les points de terminaison ("Endpoints") des abonnés (e-mails, requêtes HTTP, fonctions Lambda) [11, 14, 15].
* **Tableaux de bord d'observabilité** : Vues de synthèse personnalisables intégrant des widgets graphiques pour surveiller l'état de santé de multiples ressources réparties au sein d'une ou plusieurs régions AWS [10].

---

#### 🚀 Réalisation du Lab

##### Étape 1 — Configuration d'Amazon SNS
Pour mettre en place le canal de notification, une rubrique de messagerie Amazon SNS nommée `MyCwAlarm` de type **Standard** a été créée [11, 14]. Un abonnement a ensuite été configuré pour cette rubrique en sélectionnant le protocole **Email** et en renseignant une adresse e-mail de destination comme point de terminaison [14, 15]. 

L'état initial de l'abonnement s'affiche sous le statut **Pending confirmation** (En attente de confirmation) [15]. Un e-mail de validation envoyé automatiquement par AWS a été réceptionné, et la validation via le lien **Confirm subscription** a permis de passer l'état à **Confirmed** (Confirmé) dans la console d'administration [6, 15].

![Abonnement SNS validé et confirmé](images/sns-subscription-confirmed.png)

##### Étape 2 — Création de l'alarme CloudWatch
L'analyse initiale des métriques de performance de l'instance `Stress Test` a été menée dans CloudWatch sous les métriques par instance, ciblant l'utilisation du processeur (`CPUUtilization`) [13, 16, 17]. 

Une alarme de métrique nommée `LabCPUUtilizationAlarm` a été créée avec les spécifications suivantes [17-19] :
* **Métrique** : `CPUUtilization` pour l'instance `Stress Test` [17].
* **Statistique** : Moyenne ("Average") [18].
* **Période d'évaluation** : 1 minute [18].
* **Condition de seuil** : Seuil statique supérieur à 60 % (déclenché dès que l'utilisation CPU dépasse 60) [18].
* **Action** : Envoi d'une alerte à la rubrique existante `MyCwAlarm` lorsque l'alarme passe en état **In alarm** (En état d'alarme) [20].

![Configuration de l'alarme CloudWatch](images/cloudwatch-alarm-configuration.png)

##### Étape 3 — Test d'activité et déclenchement de l'alarme (Stress Test)
La connexion au terminal de l'instance EC2 `Stress Test` a été établie de manière sécurisée en accédant au lien fourni par le gestionnaire de session d'AWS Systems Manager [12, 21].

Pour simuler une surcharge applicative ou une intrusion malveillante, la commande suivante a été exécutée pour injecter 10 processus de contrainte pendant une durée de 400 secondes [12] :
```bash
sudo stress --cpu 10 -v --timeout 400s
Une seconde session sur l'instance a été ouverte en parallèle pour exécuter l'utilitaire top, confirmant en temps réel que la charge CPU était poussée à 100 %
.
Dans la console CloudWatch, la métrique CPUUtilization a enregistré une augmentation rapide dépassant largement le seuil de 60 %
. Après l'évaluation de la période, l'alarme est passée du statut OK à In alarm
. Ce changement d'état a immédiatement provoqué l'envoi d'une alerte e-mail par le service SNS vers la boîte de réception configurée
.
Étape 4 — Création d'un tableau de bord CloudWatch
Afin de centraliser la surveillance de cette infrastructure, un tableau de bord CloudWatch personnalisé nommé LabEC2Dashboard a été créé
.
Un widget graphique de type Ligne ("Line") a été configuré et ajouté à ce tableau de bord
. Ce widget affiche de façon continue la métrique CPUUtilization de l'instance Stress Test, offrant un raccourci visuel instantané et permanent pour l'analyse opérationnelle
.
📸 Captures d’écran
Cette section récapitule les preuves visuelles à intégrer pour valider la bonne exécution des tâches
 :
sns-subscription-confirmed.png
Description : Capture d'écran de l'onglet d'abonnements SNS montrant le statut configuré
.
Démonstration : Confirme que l'endpoint e-mail a été validé avec succès (statut "Confirmed") et est prêt à relayer les alertes
.
cloudwatch-alarm-configuration.png
Description : Vue détaillée des conditions et des métriques sélectionnées dans CloudWatch
.
Démonstration : Prouve que l'alarme est correctement configurée pour évaluer des moyennes sur des périodes d'une minute avec un seuil de déclenchement fixé à 60 % de CPU
.
cloudwatch-cpu-stress-alarm.png
Description : Graphique temporel de la métrique CPUUtilization dans CloudWatch au moment du stress test
.
Démonstration : Montre visuellement la courbe qui s'élève jusqu'à 100 % (dépassement du seuil rouge à 60 %) et le basculement officiel de l'état en rouge "In alarm"
.
sns-email-notification.png
Description : Copie d'écran de la boîte de messagerie affichant le contenu de l'e-mail d'alerte reçu de la part d'AWS Notifications
.
Démonstration : Valide le fonctionnement de bout en bout de la chaîne d'alerte automatisée, de la détection de l'anomalie système à la notification humaine
.
cloudwatch-dashboard.png
Description : Interface d'accueil du tableau de bord personnalisé LabEC2Dashboard
.
Démonstration : Montre l'intégration réussie du widget de type ligne pour le suivi visuel permanent des performances
.
🔐 Sécurité et conformité
Sécurité des accès par Moindre Privilège : Le lab met en œuvre les bonnes pratiques de sécurité d'AWS IAM en rattachant à l'instance un rôle IAM de session
. La connexion administrative s'effectue via Systems Manager Session Manager
. Cela évite d'exposer publiquement le port SSH (22) de l'instance à Internet ou de manipuler des paires de clés d'accès statiques (.pem) qui pourraient être compromises ou égarées.
Détection Proactive des Menaces : La surveillance continue au niveau de l'infrastructure permet d'identifier immédiatement les écarts de comportement (un pic CPU à 100 % consécutif à une activité anormale)
. C'est une mesure essentielle de détection d'intrusions, de logiciels malveillants ou d'exécutions de scripts non autorisés (crypto-jacking)
.
Réduction du temps d'intervention (MTTD) : La configuration d'une période de surveillance courte (1 minute) et la transmission instantanée de l'état d'alarme par notification SNS permettent de réduire drastiquement le délai de détection des incidents de sécurité (Mean Time to Detect)
.
💡 Problèmes rencontrés et solutions
Problème
Cause
Solution
Accès refusé ("Access Denied") au démarrage du Lab
Erreur d'initialisation temporaire de la session IAM ou de l'environnement AWS d'apprentissage
.
Fermer la fenêtre d'erreur active et cliquer à nouveau sur le bouton Démarrer l’atelier pour réinitialiser les droits
.
Console AWS bloquée lors de la tentative de redirection
Paramètres de sécurité du navigateur web bloquant l'ouverture des fenêtres contextuelles (pop-ups)
.
Cliquer sur la bannière ou l'icône de restriction dans la barre d'adresse et sélectionner Allow pop-ups (Autoriser les fenêtres contextuelles)
.
Métriques EC2 absentes ou graphiques vides au début dans CloudWatch
Délai d'agrégation d'AWS pour collecter et remonter les premières métriques de l'instance virtuelle (généralement 5 à 10 minutes)
.
Patienter entre 5 et 10 minutes après le démarrage effectif de l'instance pour que l'intégration des métriques soit visible dans CloudWatch
.
📊 Résultats
L'ensemble des tests a permis d'obtenir une architecture de surveillance opérationnelle de bout en bout
. Lors de l'injection de charge artificielle par l'utilitaire stress, la CPU de l'instance a été sollicitée à 100 % pendant une période de 400 secondes
. CloudWatch a détecté ce dépassement du seuil de 60 % de CPU de manière automatique
. L'état de l'alarme LabCPUUtilizationAlarm est passé au rouge ("In alarm") et a déclenché l'envoi en direct d'une alerte par e-mail via la rubrique SNS MyCwAlarm configurée
. De plus, le tableau de bord personnalisé LabEC2Dashboard fournit désormais un outil d'observation pérenne et de haut niveau
.
🎓 Compétences acquises
Observabilité & Supervision Cloud : Configuration et personnalisation de métriques, d'alarmes de seuil et de tableaux de bord opérationnels sous Amazon CloudWatch
.
Architecture d'Alerte Automatisée : Implémentation du service Amazon SNS (Simple Notification Service) avec des abonnements sécurisés selon le modèle Pub/Sub
.
SecOps & Détection Proactive : Mise en place de contrôles automatisés pour identifier des pics d'utilisation système caractéristiques d'attaques malveillantes ou d'infections virales
.
Administration système & Diagnostic Linux : Utilisation de commandes d'évaluation de charge (top) et de génération de stress (stress) pour valider la résilience et l'observabilité
.
Sécurité des Accès Cloud : Utilisation d'AWS Systems Manager (Session Manager) associé à des rôles IAM d'instance pour des sessions console sécurisées et sans clés SSH
.
📚 Ce que j’ai appris
Cet atelier m'a permis de comprendre de façon concrète l'interaction entre les processus systèmes au sein d'une machine virtuelle Linux et les mécanismes de surveillance natifs de l'infrastructure cloud AWS
. J'ai assimilé que la surveillance continue n'est pas uniquement un sujet de gestion de capacité opérationnelle, mais qu'elle constitue un dispositif de défense et d'alerte SecOps capital
. La capacité à corréler une hausse de charge soudaine avec un système automatisé d'alerte par e-mail me dote de compétences précieuses pour concevoir des architectures cloud auto-supervisées et hautement réactives face aux anomalies et aux cybermenaces
.
✅ Conclusion
En conclusion, ce projet valide l'implémentation réussie d'une boucle complète d'observabilité sur AWS, allant de la détection d'une anomalie système sur une instance EC2 au dispatch d'une alerte de sécurité
. L'utilisation d'Amazon CloudWatch et d'Amazon SNS offre une visibilité totale et un temps d'alerte minimal, des atouts stratégiques pour garantir le maintien en conditions de sécurité et de performances des infrastructures cloud de production
.

📊 Souhaitez-vous que je crée un tableau synthétique supplémentaire des métriques Clo
