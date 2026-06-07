# Inventaire.gd
# Inventaire du joueur — script AUTOLOAD (global).
# Chargé une fois, accessible partout : c'est ce qui permet à
# l'inventaire de SURVIVRE quand on change de pièce.
extends Node


# Signal émis à chaque changement (le carnet s'y connecte pour se
# rafraîchir : ajout, retrait, OU décompte d'une charge).
signal inventaire_modifie


# Liste des objets possédés (ids texte simples : "cles", "cigarettes"...).
var objets: Array[String] = []

# Charges RESTANTES par objet consommable (id -> nombre d'usages restants).
# Les objets ILLIMITÉS (outils) n'y figurent pas : on ne décompte rien
# pour eux. C'est un ÉTAT de partie, distinct de la simple présence.
var _charges: Dictionary = {}


func _ready() -> void:
    print("Inventaire prêt.")


# Ajoute un objet (ignoré s'il y est déjà). À l'ajout, on initialise ses
# charges depuis sa fiche du catalogue (sauf objet illimité).
func ajouter(id_objet: String) -> void:
    if id_objet in objets:
        return
    objets.append(id_objet)

    var fiche: ObjetInventaire = CatalogueObjets.fiche_de(id_objet)
    if fiche != null and fiche.utilisations_max != ObjetInventaire.ILLIMITE:
        _charges[id_objet] = fiche.utilisations_max

    inventaire_modifie.emit()
    print("Objet ajouté à l'inventaire : ", id_objet)


# Retire un objet (ignoré s'il n'y est pas). On nettoie aussi ses charges.
func retirer(id_objet: String) -> void:
    if id_objet not in objets:
        return
    objets.erase(id_objet)
    _charges.erase(id_objet)
    inventaire_modifie.emit()
    print("Objet retiré de l'inventaire : ", id_objet)


# Consomme UN usage d'un objet (après une utilisation réussie).
#   - objet illimité (outil) -> ne fait rien ;
#   - sinon -> décrémente ; à 0, l'objet est retiré de l'inventaire.
func consommer(id_objet: String) -> void:
    if id_objet not in objets:
        return
    var fiche: ObjetInventaire = CatalogueObjets.fiche_de(id_objet)
    if fiche == null or fiche.utilisations_max == ObjetInventaire.ILLIMITE:
        return  # outil : pas de consommation

    _charges[id_objet] = _charges.get(id_objet, 0) - 1
    if _charges[id_objet] <= 0:
        retirer(id_objet)          # émet déjà inventaire_modifie
    else:
        inventaire_modifie.emit()  # le carnet redessine le nouveau compte


# Renvoie true si le joueur possède cet objet.
func possede(id_objet: String) -> bool:
    return id_objet in objets


# Nombre d'usages restants d'un objet consommable (0 si inconnu/épuisé).
func charges_restantes(id_objet: String) -> int:
    return _charges.get(id_objet, 0)


# Renvoie la liste de TOUS les objets possédés (copie).
func tout() -> Array[String]:
    return objets.duplicate()


# --- REMETTRE À ZÉRO (pour une nouvelle partie) ---
# Vide complètement l'inventaire (objets ET charges) et prévient le
# carnet une seule fois.
func reinitialiser() -> void:
    objets.clear()
    _charges.clear()
    inventaire_modifie.emit()
