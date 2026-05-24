# objet_inventaire.gd
# LE MODÈLE d'une fiche d'objet d'inventaire.
#
# Ce script ne décrit AUCUN objet précis. Il dit seulement quelles
# informations une fiche d'objet contient : un nom, une image, une
# description.
#
# Chaque objet réel du jeu (les clés, les cigarettes...) sera un
# fichier .tres séparé, créé à partir de ce modèle, avec ses cases
# remplies. Ces .tres vivent dans resources/.
#
# "class_name" donne un nom à ce modèle : il apparaît dans le menu
# "Create Resource" de Godot, comme un type d'objet à part entière.

class_name ObjetInventaire
extends Resource


# --- Les cases de la fiche ---
# @export = cette donnée sera REMPLIE dans l'éditeur Godot,
# directement dans le fichier .tres, sans toucher au code.

# Le nom lisible, affiché au joueur dans le carnet.
@export var nom_affiche: String = ""

# L'image de l'objet, montrée dans l'inventaire.
@export var icone: Texture2D = null

# La pensée d'Al' quand le joueur clique l'objet dans le carnet.
# C'est sa voix intérieure : ton cynique, à la première personne.
# multiline = la case d'édition sera une vraie zone de texte (pratique
# pour les phrases longues et les retours à la ligne).
@export_multiline var description: String = ""
