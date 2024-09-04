# applilocali


## Getting Started

Créer un fichier README bien structuré est essentiel pour documenter votre projet. Voici un modèle que vous pouvez utiliser pour votre projet Flutter. Adaptez-le selon les spécificités de votre projet :

---

# Nom du Projet

## Description

Une brève description de ce que fait votre projet. Par exemple :
```
Cette application Flutter permet de gérer et d'afficher des incidents. Les utilisateurs peuvent signaler des incidents, consulter la liste des incidents, et voir les incidents sur un graphique selon différents critères (mois, année, type).
```

## Fonctionnalités

- Affichage des incidents signalés avec leurs détails (type, commentaire, date).
- Graphiques pour visualiser les incidents par mois, année, et type.
- Notification des incidents signalés via OneSignal.
- Possibilité de commenter les incidents.
- Page d'accueil attrayante avec des options pour se connecter ou s'inscrire.

## Technologies Utilisées

- **Flutter** : Framework pour construire des applications mobiles.
- **Firebase** : Backend pour la base de données et les notifications.
- **OneSignal** : Service pour les notifications push.
- **OpenStreetMap** : Service de carte pour la localisation des incidents.
- **OpenRouteService** : Service pour le calcul d'itinéraire.

## Installation

1. Clonez le dépôt :
   ```sh
   git clone https://github.com/AMESONSTACK/applilocali.git
   ```

2. Accédez au répertoire du projet :
   ```sh
   cd repository
   ```

3. Assurez-vous que vous avez [Flutter](https://flutter.dev/docs/get-started/install) installé sur votre machine.

4. Installez les dépendances :
   ```sh
   flutter pub get
   ```

5. Configurez Firebase en suivant [la documentation officielle](https://firebase.google.com/docs/flutter/setup).

6. Exécutez l'application :
   ```sh
   flutter run
   ```

## Configuration

Pour configurer Firebase , suivez ces étapes :

1. **Firebase** :
   - Créez un projet Firebase sur [Firebase Console](https://console.firebase.google.com/).
   - Téléchargez le fichier `google-services.json` et placez-le dans le répertoire `android/app`.
   - Ajoutez les configurations nécessaires dans votre projet Flutter comme indiqué dans la documentation de Firebase.



## Utilisation

- **Page d'accueil** : Affiche la page de bienvenue avec des options pour se connecter ou s'inscrire.
- **Page d'administration** : Permet de gérer les incidents, avec des options pour filtrer par mois, année ou type, et afficher les graphiques.
- **Page des incidents** : Affiche la liste des incidents signalés avec des détails et des options pour commenter.


---

.
