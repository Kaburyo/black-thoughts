# objet_en_main.gd
# Service AUTOLOAD "ObjetEnMain".
#
# LE SEUL responsable d'UNE question : "quel objet le joueur tient-il
# en main, là, maintenant ?" — et, depuis V13-bis, "pour quoi faire ?".
#
# C'est une DONNÉE invisible (un id texte + un drapeau), exactement
# comme l'Inventaire : elle doit survivre au carnet fermé et être
# lisible de PARTOUT (le carnet, le décor, le portrait d'Al'...).
#
# Ce service ne dessine RIEN. Le faux curseur (dans le HUD) n'est qu'un
# SPECTATEUR : il écoute le signal "objet_change" et se met à jour.

extends Node


# Émis CHAQUE fois que l'objet en main change (pris OU reposé).
signal objet_change


# Id de l'objet tenu. Une chaîne vide "" veut dire : rien en main.
var _id: String = ""

# Pourquoi l'objet est en main :
#   true  = pris pour ÊTRE UTILISÉ sur le décor / Al' -> il SURVIT à la
#           fermeture du carnet (on va cliquer une cible au-dehors) ;
#   false = pris pour COMBINER -> geste interne au carnet ; refermer le
#           carnet l'annule (on le repose).
var _persistant: bool = false


func _ready() -> void:
    print("ObjetEnMain prêt.")


# Prend un objet en main. "persistant" dit s'il doit survivre à la
# fermeture du carnet (true pour Utiliser, false pour Combiner).
func prendre(id_objet: String, persistant: bool = false) -> void:
    if id_objet == "":
        return
    _id = id_objet
    _persistant = persistant
    objet_change.emit()


# Repose l'objet en main (annulation). Sans effet si rien en main.
func reposer() -> void:
    if _id == "":
        return
    _id = ""
    _persistant = false
    objet_change.emit()


# Vrai si un objet est actuellement en main.
func a_un_objet() -> bool:
    return _id != ""


# L'id de l'objet en main ("" si rien).
func id() -> String:
    return _id


# Vrai si l'objet en main doit survivre à la fermeture du carnet
# (objet pris pour "Utiliser"). Faux pour un objet pris pour "Combiner".
func est_persistant() -> bool:
    return _persistant
