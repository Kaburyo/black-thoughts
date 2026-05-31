# objet_inventaire.gd
# LE MODÈLE d'une fiche d'objet d'inventaire.
#
# Ce script ne décrit AUCUN objet précis. Il dit seulement quelles
# informations une fiche d'objet contient : un nom, une image, une
# description, une liste d'effets, et un nombre d'usages.
#
# Chaque objet réel du jeu (les clés, les cigarettes...) est un fichier
# .tres séparé, créé à partir de ce modèle. Ces .tres vivent dans resources/.

class_name ObjetInventaire
extends Resource


# Valeur d'usages signifiant "ILLIMITÉ" (un outil, comme la clé : on
# peut s'en servir autant qu'on veut, il ne se consomme jamais).
const ILLIMITE: int = -1


# --- Les cases de la fiche ---
# @export = rempli dans l'éditeur Godot, directement dans le .tres.

# Le nom lisible, affiché au joueur dans le carnet.
@export var nom_affiche: String = ""

# L'image de l'objet, montrée dans l'inventaire.
@export var icone: Texture2D = null

# La pensée d'Al' quand le joueur EXAMINE l'objet dans le carnet.
@export_multiline var description: String = ""


# --- Utilisation sur Al' (verbe UTILISER du curseur-objet) ---

# La LISTE des effets appliqués quand on utilise cet objet sur Al'.
# VIDE = objet non consommable : Al' le refusera.
@export var effets: Array[EffetObjet] = []

# Pensée d'Al' au moment où il utilise l'objet sur lui-même (optionnel).
@export_multiline var pensee_utilisation: String = ""

# Nombre d'usages de l'objet :
#   ILLIMITE (-1) = outil, jamais consommé (clé, photo...) ;
#   N (1, 2, 3...) = consommable à N usages (1 = consommé en une fois).
@export var utilisations_max: int = ILLIMITE
