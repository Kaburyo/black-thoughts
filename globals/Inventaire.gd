# inventaire.gd
# Inventaire du joueur — script AUTOLOAD (global).
# Un autoload est chargé une seule fois et reste accessible depuis
# TOUTES les scènes : c'est ce qui permet à l'inventaire de SURVIVRE
# quand on change de Room.

extends Node


# Signal émis à chaque fois que l'inventaire change.
# Plus tard, le menu d'inventaire s'y connectera pour se rafraîchir.
signal inventaire_modifie


# Liste des objets possédés, identifiés par un texte simple ("cles", ...).
var objets: Array[String] = []


func _ready() -> void:
    # Témoin temporaire : confirme que l'autoload est bien chargé.
    print("Inventaire prêt.")


# Ajoute un objet à l'inventaire (ignoré s'il y est déjà).
func ajouter(id_objet: String) -> void:
    if id_objet in objets:
        return
    objets.append(id_objet)
    inventaire_modifie.emit()
    print("Objet ajouté à l'inventaire : ", id_objet)


# Renvoie true si le joueur possède cet objet.
func possede(id_objet: String) -> bool:
    return id_objet in objets
