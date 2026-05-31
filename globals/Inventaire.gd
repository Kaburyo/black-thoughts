# Inventaire.gd
# Inventaire du joueur — script AUTOLOAD (global).
# Un autoload est chargé une seule fois et reste accessible depuis
# TOUTES les scènes : c'est ce qui permet à l'inventaire de SURVIVRE
# quand on change de Room.
extends Node


# Signal émis à chaque fois que l'inventaire change.
# Le menu d'inventaire s'y connecte pour se rafraîchir.
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


# Retire un objet de l'inventaire (ignoré s'il n'y est pas).
# Le miroir de ajouter() : même logique, même signal, pour que
# la grille du carnet se redessine toute seule après un retrait.
func retirer(id_objet: String) -> void:
    if id_objet not in objets:
        return
    objets.erase(id_objet)
    inventaire_modifie.emit()
    print("Objet retiré de l'inventaire : ", id_objet)


# Renvoie true si le joueur possède cet objet.
func possede(id_objet: String) -> bool:
    return id_objet in objets


# Renvoie la liste de TOUS les objets possédés.
# Le guichet officiel pour lire l'inventaire de l'extérieur :
# on passe par ici plutôt que de lire la variable directement,
# pour que le reste du jeu ne dépende pas du rangement interne.
func tout() -> Array[String]:
    return objets.duplicate()
