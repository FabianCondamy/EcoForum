La carte des batiments est telechargée par exportation du fichier depuis https://overpass-turbo.eu/
On utilise script suivant :
  // Faculté des Sciences Montpellier
 # [out:json][timeout:60];(way["building"](43.630,3.860,43.640,3.870);relation["building"](43.630,3.860,43.640,3.870););out body;>;out skel qt;

Le type de fichier est .geoson. On peut ajuster les coordonnées du rectangle de capture au besoin.
Le fichier brute obtenu contient des batiments voisins et d'autres objets qui ne sont pas des batiments.
On lance ensuite l'utilitaire de nettoyage nettoyage_geoson.R.
On execute ce fichier qui filtre les documents hors université et l'autre construction non utiles.
Le fichier Controle.R permet de visualiser l'efficité de nettoyage
************************************************************************************************
The building map is downloaded by exporting the file from https://overpass-turbo.eu/
We use the following script:
// Faculty of Sciences Montpellier
# [out:json][timeout:60];(way["building"](43.630,3.860,43.640,3.870); relation["building"](43.630,3.860,43.640,3.870););out body;>;out skel qt;

The file type is .geojson. The coordinates of the capture rectangle can be adjusted as needed.
The raw file obtained contains neighboring buildings and other objects that are not buildings.
We then run the cleaning utility nettoyage_geoson.R.
This script filters out documents outside the university and other non‑useful constructions.
The file Controle.R is used to visualize the effectiveness of the cleaning process.
