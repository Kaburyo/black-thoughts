# catalogue_objets.gd
# Autoload "CatalogueObjets".
#
# LE FOYER UNIQUE des fiches d'objets du jeu.
# Fait le lien entre l'id texte d'un objet (ex. "cles"), tel que
# l'inventaire le stocke, et sa fiche complète (nom + image).
#
# Quand on ajoute un objet au jeu :
#   1. créer sa fiche .tres dans resources/
#   2. ajouter UNE ligne dans le dictionnaire CATALOGUE ci-dessous.
#
# Le carnet (hud.gd) interroge ce catalogue pour afficher l'inventaire.

extends Node


# --- Le catalogue ---
# Clé = id de l'objet (le même texte que dans l'Inventaire).
# Valeur = chemin vers sa fiche .tres.
const CATALOGUE: Dictionary = {
    "cles": "res://resources/objet_cles.tres",
    "cigarettes": "res://resources/objet_cigarettes.tres",
    "bar_ticket" : "res://resources/objet_bar_ticket.tres",
    "picture_flora" : "res://resources/objet_picture_fora.tres",
    "picture_luna" : "res://resources/objet_picture_luna.tres",
    "picture_luna_flora" : "res://resources/objet_picture_luna_flora.tres",
}


# Renvoie la fiche complète (ObjetInventaire) d'un id donné.
# Renvoie null si l'id est inconnu du catalogue.
func fiche_de(id: String) -> ObjetInventaire:
    if not CATALOGUE.has(id):
        push_warning("CatalogueObjets : id inconnu '%s'." % id)
        return null
    return load(CATALOGUE[id]) as ObjetInventaire
