# carte.gd
# La CARTE de navigation — script AUTOLOAD (global).
#
# C'est le "cerveau" de la carte : il NE dessine RIEN à l'écran.
# Il se contente de SAVOIR deux choses :
#   - quelles ZONES existent dans le monde (leur nom + leur scène),
#   - lesquelles sont DÉBLOQUÉES (visitables) à cet instant.
#
# L'écran de carte (les boutons) viendra à l'ÉTAPE SUIVANTE et se
# contentera de LIRE ces données. On sépare ainsi le "savoir" (ici)
# de "l'affichage" (plus tard) — même esprit que nos jauges, où le
# moule sait et l'écran montre. (Règle A.8, anti-spaghetti.)
#
# Pourquoi un AUTOLOAD ? Parce que la liste des zones débloquées doit
# SURVIVRE aux changements de pièce (comme l'Inventaire ou la Santé
# mentale). Sinon, en changeant de pièce on oublierait tout.

extends Node


# Émis dès qu'une zone est débloquée. L'écran de carte (plus tard)
# s'y abonnera pour se redessiner tout seul, sans qu'on le lui demande.
signal carte_modifiee


# --- LE CATALOGUE DES ZONES ---
# Chaque zone est décrite par un petit dictionnaire :
#   "nom"       : le texte montré au joueur (ex. "Mon bureau")
#   "scene"     : le chemin de la scène à charger (res://...)
#   "debloquee" : true = visitable maintenant ; false = encore cachée
#
# L'ORDRE compte : en Godot 4, un Dictionary garde l'ordre dans lequel
# on a écrit les lignes. La carte montrera donc les zones dans CET ordre.
#
# Pour l'instant on déclare les trois pièces qui existent déjà. Seul le
# bureau est ouvert au départ (la démo commence là) ; le reste se
# débloquera au fil de l'enquête (étape ultérieure).
var _zones: Dictionary = {
    "bureau": {
        "nom": "Mon bureau",
        "scene": "res://scenes/rooms/office_room.tscn",
        "debloquee": true,
    },
    "chambre_luna": {
        "nom": "Chambre de Luna",
        "scene": "res://scenes/rooms/chambre_luna_room.tscn",
        "debloquee": false,
    },
    "cuisine_jenny": {
        "nom": "Cuisine de Jenny",
        "scene": "res://scenes/rooms/cuisine_jenny_room.tscn",
        "debloquee": false,
    },
}


# --- LIRE LES DONNÉES (ce que l'écran de carte utilisera) ---

# Cette zone existe-t-elle dans le catalogue ?
func existe(id: String) -> bool:
    return _zones.has(id)


# Cette zone est-elle débloquée (visitable) ?
func est_debloquee(id: String) -> bool:
    if not existe(id):
        return false
    return _zones[id]["debloquee"]


# Le nom affichable d'une zone (ex. "Mon bureau"). Vide si inconnue.
func nom_de(id: String) -> String:
    if not existe(id):
        return ""
    return _zones[id]["nom"]


# Le chemin de scène d'une zone. Vide si inconnue.
func scene_de(id: String) -> String:
    if not existe(id):
        return ""
    return _zones[id]["scene"]


# La liste des id de zones DÉBLOQUÉES, dans l'ordre du catalogue.
# C'est exactement ce que l'écran de carte transformera en boutons.
func zones_debloquees() -> Array[String]:
    var resultat: Array[String] = []
    for id in _zones:
        if _zones[id]["debloquee"]:
            resultat.append(id)
    return resultat


# --- MODIFIER L'ÉTAT (débloquer une zone) ---

# Débloque une zone (la rend visitable) et prévient l'écran de carte via
# le signal "carte_modifiee". Sans effet si la zone n'existe pas ou est
# déjà débloquée.
func debloquer(id: String) -> void:
    if not existe(id):
        push_warning("Carte.debloquer : zone inconnue '%s'." % id)
        return
    if _zones[id]["debloquee"]:
        return
    _zones[id]["debloquee"] = true
    carte_modifiee.emit()

# --- REMETTRE À ZÉRO (pour une nouvelle partie) ---
# Reverrouille toutes les zones SAUF le bureau (l'état de départ de la
# démo), puis prévient l'écran de carte de se redessiner.
func reinitialiser() -> void:
    for id in _zones:
        _zones[id]["debloquee"] = (id == "bureau")
    carte_modifiee.emit()
