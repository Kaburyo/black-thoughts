# combinaison.gd
# Service AUTOLOAD "Combinaison".
#
# LE CERVEAU de l'assemblage d'objets.
# Certains objets se trouvent en MORCEAUX (deux moitiés de photo,
# un ticket déchiré...) ; ce service sait reconnaître quels morceaux
# vont ensemble et les remplacer par l'objet reconstitué.
#
# Il ne s'occupe PAS de l'interface (le menu du carnet, lui, appelle
# ce service). Séparation nette : ici la LOGIQUE, ailleurs l'écran.
#
# Pour ajouter un assemblage au jeu : ajouter UNE entrée à RECETTES
# ci-dessous. Aucune autre ligne de code à toucher.

extends Node


# --- Les recettes ---
# Chaque recette dit : tels MORCEAUX (ids d'inventaire) donnent tel
# RÉSULTAT (id d'inventaire), et Al' a telle PENSÉE au moment où ça
# s'assemble. L'ordre des morceaux n'a pas d'importance (gauche +
# droite = droite + gauche).
const RECETTES: Array[Dictionary] = [
    {
        "morceaux": ["picture_luna", "picture_flora"],
        "resultat": "picture_luna_flora",
        "pensee": "Les deux moitiés vont ensemble.\nQuelqu'un les a séparées exprès.",
    },
]


func _ready() -> void:
    print("Combinaison prêt.")


# Renvoie l'id de l'objet reconstitué si ces morceaux forment une
# recette connue, sinon une chaîne vide "". Ne modifie rien.
func resultat_pour(ids: Array[String]) -> String:
    var recette := _recette_pour(ids)
    if recette.is_empty():
        return ""
    return recette["resultat"]


# Tente l'assemblage : si les morceaux forment une recette, on les
# retire de l'inventaire, on ajoute l'objet reconstitué, et Al' pense
# tout haut. Renvoie true si l'assemblage a eu lieu, false sinon.
func combiner(ids: Array[String]) -> bool:
    var recette := _recette_pour(ids)
    if recette.is_empty():
        return false

    # On enlève chaque morceau, puis on ajoute l'objet entier.
    for id_morceau in ids:
        Inventaire.retirer(id_morceau)
    Inventaire.ajouter(recette["resultat"])

    # La voix intérieure d'Al' commente la reconstitution.
    if recette.get("pensee", "") != "":
        Voix.afficher_pensee(recette["pensee"])

    return true


# --- Outils internes ---

# Cherche la recette dont les morceaux correspondent à ids (sans tenir
# compte de l'ordre). Renvoie la recette, ou un dictionnaire vide {}.
func _recette_pour(ids: Array[String]) -> Dictionary:
    for recette in RECETTES:
        if _memes_elements(ids, recette["morceaux"]):
            return recette
    return {}


# Vrai si les deux listes contiennent exactement les mêmes éléments,
# peu importe l'ordre. (On les copie et on les trie avant de comparer.)
func _memes_elements(a: Array, b: Array) -> bool:
    if a.size() != b.size():
        return false
    var a_triee := a.duplicate()
    var b_triee := b.duplicate()
    a_triee.sort()
    b_triee.sort()
    return a_triee == b_triee
