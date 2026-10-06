# Kito

Téléchargement Android : https://yunki0.github.io/Kito/

Kito est une application Flutter en français pour gérer l'inventaire matériel
d'une unité scoute, même hors ligne. Les données sont enregistrées localement dans une base
SQLite sur l'appareil. Android, iOS, macOS, Linux et Windows sont pris en charge.
L'application suit automatiquement le thème clair ou sombre du système.

L'identité visuelle reprend le logo montagne-sapin, le vert forêt (`#0F5132`),
le vert olive (`#688F58`), l'ambre (`#F5A623`) et l'ivoire (`#F8F7EF`) du visuel
fourni. L'écran de démarrage est entièrement vectoriel : symbole Kito centré sur 
fond ivoire, nom et baseline en fondu, collines en arrière-plan. 
Le splash natif obligatoire des plateformes reste volontairement limité à un
fond ivoire uni ; l'écran de démarrage Flutter détaillé est celui à conserver.

Les sources graphiques sont regroupées dans `assets/branding/`. Les fichiers
`kito_mark_monochrome.svg` et `kito_mark_monochrome_white.svg` sont les variantes
monochromes du symbole. Le logo de l'écran de démarrage Flutter est rendu en
SVG, tandis que les variantes PNG carrées sont utilisées par les écrans de
démarrage natifs.
La palette, la typographie et le thème Material sont centralisés dans
`lib/core/theme/`.

Les données peuvent être exportées dans un fichier JSON depuis le menu de
l'application, puis restaurées sur cet appareil ou un autre. La restauration
remplace l'inventaire et le journal après confirmation. Conservez vos
sauvegardes dans un emplacement sûr.
Le même menu permet d'exporter l'inventaire en PDF, avec un résumé des stocks
et un tableau adapté à l'impression, ou en CSV pour l'ouvrir dans un tableur.
Lors de la mise à jour, les éventuels prêts en cours sont considérés comme
rendus ; leur historique d'activité reste consultable.

## Démarrer

Installez le SDK Flutter puis, depuis la racine du projet :

```sh
flutter pub get
flutter run
```

### Lancer sur un téléphone Android

1. Activez les **Options pour les développeurs** et le **Débogage USB** sur le
   téléphone, branchez-le et acceptez la demande d'autorisation affichée.
2. Vérifiez que Flutter voit l'appareil :

   ```sh
   flutter doctor -v
   flutter devices
   ```

3. Lancez l'application en remplaçant `<id>` par l'identifiant affiché par
   `flutter devices` :

   ```sh
   flutter run -d <id>
   ```

Pour créer et installer une APK de test destinée aux téléphones Android récents
(ARM64) :

```sh
flutter build apk --release --target-platform android-arm64
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

La version Android est incrémentée dans `pubspec.yaml` pour permettre
l'installation d'une mise à jour sur une version antérieure. La configuration
de signature actuelle convient aux essais personnels ; une clé de signature
de publication est nécessaire avant une diffusion publique.

L'application démarre avec un inventaire vide. Utilisez **Ajouter du matériel**
pour créer les premières fiches. Les quantités sont réparties par état ; seuls
les articles neufs ou en bon état sont considérés disponibles. Dans une fiche,
**Consommable** active le seuil d'alerte de stock.

## Fonctionnalités

- Inventaire consultable, recherche et filtres par catégorie / stock bas.
- Création, modification et suppression des fiches de matériel.
- Indicateurs de stock disponible, à réparer et hors service.
- Journal local des ajouts, modifications et suppressions.
- Sauvegarde et restauration locale de l'inventaire et du journal.
- Export de l'inventaire en PDF ou CSV.

Les fiches supprimées restent consignées dans le journal.

## Vérification

```sh
flutter analyze
flutter test
```

## Publication Android

La page de téléchargement est publiée sur GitHub Pages à chaque mise à jour de
`main`. Pour créer une nouvelle version Android, incrémentez `version` dans
`pubspec.yaml`, poussez le commit puis créez et poussez un tag correspondant
(par exemple `v1.0.7`). GitHub Actions construit des APK Android séparés par
architecture et les joint à la release GitHub. La page propose la dernière
version disponible.

La version iOS est définie par le même champ `version` Flutter, mais sa
distribution sera ajoutée lorsque l’application sera publiée sur l’App Store
ou TestFlight.

Les données restent sur l'appareil : aucune synchronisation ni sauvegarde cloud
n'est actuellement configurée. La suppression des données de l'application
efface également sa base locale.

## Régénérer l'icône et l'écran de démarrage

Les images et vecteurs de marque se trouvent dans `assets/branding/`. Après les
avoir modifiées, régénérez les ressources des plateformes avec :

```sh
dart run flutter_launcher_icons
dart run flutter_native_splash:create
```
