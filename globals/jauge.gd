# jauge.gd
# LE MOULE des jauges du jeu (santé mentale, vie...).
#
# Ce script n'est PAS un autoload et ne se déclare PAS dans la liste
# des Globals. C'est un MOULE, comme `room_base.gd` l'est pour les
# pièces : il contient la mécanique COMMUNE à toute jauge, et les
# vraies jauges en héritent par `extends Jauge`.
#
# Une jauge, ici, c'est :
#   - une valeur continue bornée entre 0 et 100 ;
#   - un classement de cette valeur en 5 PALIERS (Good/Ok/Mid/Bof/Bad) ;
#   - un signal émis à chaque changement, pour prévenir les afficheurs.
#
# Ce qui CHANGE d'une jauge à l'autre (sa valeur de départ) n'est PAS
# décidé ici : le moule appelle `_valeur_depart()`, que chaque jauge
# concrète redéfinit pour donner SA propre valeur (même principe que
# `_definir_contenu()` pour les pièces).
#
# Jauges concrètes qui héritent de ce moule :
#   - SanteMentale (globals/sante_mentale.gd)
#   - Vie          (globals/vie.gd)

class_name Jauge
extends Node


# --- Signal ---
# Émis à CHAQUE changement de la jauge. Les afficheurs (portrait,
# filtre mental...) s'y connectent pour se rafraîchir tout seuls.
# Nom volontairement générique : ce moule ne sait pas s'il sert la
# santé ou la vie.
signal modifiee


# --- Les 5 paliers ---
# Un "enum" est juste une liste de noms : ici, les 5 états possibles
# d'une jauge. Manipuler Palier.OK est plus sûr qu'écrire le texte
# "Ok" à la main (aucune faute de frappe possible).
enum Palier { GOOD, OK, MID, BOF, BAD }

# Noms lisibles des paliers, rangés dans l'ordre de l'enum ci-dessus.
# Sert UNIQUEMENT à écrire des messages clairs dans la console.
const NOMS_PALIERS: Array[String] = ["Good", "Ok", "Mid", "Bof", "Bad"]


# --- Réglages communs ---
const VALEUR_MIN: float = 0.0       # plancher : la jauge ne descend pas plus bas
const VALEUR_MAX: float = 100.0     # plafond : la jauge ne monte pas plus haut

# Seuils des paliers : "valeur >= ce seuil" -> on est dans ce palier.
# Valeurs de référence 100/70/50/30/0 ; chaque seuil est le POINT
# MILIEU entre deux d'entre elles. À régler en test si besoin.
const SEUIL_GOOD: float = 85.0      # >= 85            -> Good
const SEUIL_OK: float = 60.0        # de 60 a 84.99    -> Ok
const SEUIL_MID: float = 40.0       # de 40 a 59.99    -> Mid
const SEUIL_BOF: float = 15.0       # de 15 a 39.99    -> Bof
#                                     en dessous de 15 -> Bad


# --- État ---
# La valeur réelle de la jauge. Préfixe "_" = donnée interne : on la
# lit de l'extérieur par valeur(), jamais directement.
var _valeur: float = 0.0


# --- Point d'accroche à remplir par chaque jauge concrète ---
# Le moule appelle cette fonction au démarrage pour connaître la
# valeur de départ de CETTE jauge. Ici, dans le moule, elle renvoie
# une valeur neutre ; chaque jauge concrète la redéfinit.
func _valeur_depart() -> float:
    return VALEUR_MAX


# Appelée automatiquement une fois, au lancement.
func _ready() -> void:
    _valeur = clampf(_valeur_depart(), VALEUR_MIN, VALEUR_MAX)
    # `name` est le nom du nœud autoload (ex. "SanteMentale", "Vie") :
    # le message s'adapte donc tout seul à la jauge concrète.
    print("%s prête. (départ : %.0f -> palier %s)"
            % [name, _valeur, NOMS_PALIERS[palier()]])


# --- LIRE LA JAUGE ---

# Renvoie le chiffre continu de la jauge (0 à 100).
func valeur() -> float:
    return _valeur


# Renvoie le palier courant (l'une des 5 valeurs de l'enum Palier).
func palier() -> Palier:
    return _palier_pour(_valeur)


# --- MODIFIER LA JAUGE ---

# Applique un changement à la jauge. "delta" peut être :
#   - négatif pour faire BAISSER la jauge
#   - positif pour la faire REMONTER
# La valeur est automatiquement maintenue entre VALEUR_MIN et VALEUR_MAX.
func modifier(delta: float) -> void:
    _valeur = clampf(_valeur + delta, VALEUR_MIN, VALEUR_MAX)
    modifiee.emit()
    print("%s -> %.0f (palier %s)"
            % [name, _valeur, NOMS_PALIERS[palier()]])


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
