# sante_mentale.gd
# Jauge de santé mentale d'Al' — script AUTOLOAD (global).
#
# Un autoload est chargé une seule fois et reste accessible depuis
# TOUTES les scènes : c'est ce qui permet à la jauge de SURVIVRE
# quand on change de pièce (même principe que l'Inventaire).
#
# RÔLE. Cet autoload est la DONNÉE centrale de la santé mentale :
# une simple valeur de 0 à 100 (le "moral brut" d'Al'). Il ne dessine
# rien lui-même — il se contente de garder le chiffre et de prévenir,
# par un signal, ceux qui l'affichent (le portrait, le filtre mental).
#
# DEUX FAÇONS DE LIRE LA JAUGE :
#   - valeur()  : le chiffre continu 0-100  (le filtre mental en a besoin
#                 pour doser son assombrissement en gradient).
#   - palier()  : l'un des 5 paliers Good/Ok/Mid/Bof/Bad  (le portrait
#                 en a besoin pour choisir lequel de ses 5 sprites montrer).
#
# Voir la "bible" du projet, point L.1, pour le design complet.

extends Node


# --- Signal ---
# Émis à CHAQUE changement de la jauge. Le portrait et le filtre mental
# s'y connecteront pour se rafraîchir tout seuls (comme la grille
# d'inventaire se branche sur `inventaire_modifie`).
signal sante_modifiee


# --- Les 5 paliers ---
# Un "enum" est juste une liste de noms : ici, les 5 états possibles
# de la jauge. Manipuler Palier.OK est plus sûr qu'écrire le texte
# "Ok" à la main (aucune faute de frappe possible).
enum Palier { GOOD, OK, MID, BOF, BAD }

# Noms lisibles des paliers, rangés dans l'ordre de l'enum ci-dessus.
# Sert UNIQUEMENT à écrire des messages clairs dans la console.
const NOMS_PALIERS: Array[String] = ["Good", "Ok", "Mid", "Bof", "Bad"]


# --- Réglages de la jauge ---
const VALEUR_MIN: float = 0.0       # plancher : la jauge ne descend pas plus bas
const VALEUR_MAX: float = 100.0     # plafond : la jauge ne monte pas plus haut
const VALEUR_DEPART: float = 70.0   # Al' commence la démo déjà cabossé (palier Ok)

# Seuils des paliers : "valeur >= ce seuil" -> on est dans ce palier.
# Les valeurs de référence de la bible sont 100/70/50/30/0 ; chaque
# seuil ci-dessous est le POINT MILIEU entre deux d'entre elles. Ces
# nombres sont à régler en test si une transition tombe trop tôt/tard.
const SEUIL_GOOD: float = 85.0      # >= 85            -> Good
const SEUIL_OK: float = 60.0        # de 60 a 84.99    -> Ok
const SEUIL_MID: float = 40.0       # de 40 a 59.99    -> Mid
const SEUIL_BOF: float = 15.0       # de 15 a 39.99    -> Bof
#                                     en dessous de 15 -> Bad


# --- État ---
# La valeur réelle de la jauge. Préfixe "_" = donnée interne : on la lit
# de l'extérieur par valeur(), jamais directement (même règle que
# `objets` dans l'Inventaire).
var _valeur: float = VALEUR_DEPART


# Appelée automatiquement une fois, au lancement.
func _ready() -> void:
    print("Santé mentale prête. (départ : %.0f -> palier %s)"
            % [_valeur, NOMS_PALIERS[palier()]])
  

# --- LIRE LA JAUGE ---

# Renvoie le chiffre continu de la jauge (0 à 100).
func valeur() -> float:
    return _valeur


# Renvoie le palier courant (l'une des 5 valeurs de l'enum Palier).
func palier() -> Palier:
    return _palier_pour(_valeur)


# --- MODIFIER LA JAUGE ---

# Applique un changement à la jauge. "delta" peut être :
#   - négatif pour faire BAISSER (choix de dialogue dur, mauvais événement)
#   - positif pour faire REMONTER (cigarette, bon choix de dialogue)
# La valeur est automatiquement maintenue entre VALEUR_MIN et VALEUR_MAX.
func modifier(delta: float) -> void:
    _valeur = clampf(_valeur + delta, VALEUR_MIN, VALEUR_MAX)
    sante_modifiee.emit()
    print("Santé mentale -> %.0f (palier %s)"
            % [_valeur, NOMS_PALIERS[palier()]])


# --- OUTIL INTERNE ---

# Le "calcul pur" : à quel palier correspond une valeur donnée ?
# Séparé de palier() pour pouvoir tester le classement sur n'importe
# quelle valeur sans toucher à la vraie jauge.
func _palier_pour(v: float) -> Palier:
    if v >= SEUIL_GOOD:
        return Palier.GOOD
    elif v >= SEUIL_OK:
        return Palier.OK
    elif v >= SEUIL_MID:
        return Palier.MID
    elif v >= SEUIL_BOF:
        return Palier.BOF
    else:
        return Palier.BAD
