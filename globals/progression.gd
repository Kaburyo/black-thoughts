# progression.gd
# La PROGRESSION — mémoire des FAITS marquants de la partie. AUTOLOAD (global).
#
# Beaucoup de "retours-clés" reposent sur une question simple : "Est-ce que
# ça s'est DÉJÀ produit ?" (Al' a-t-il déjà parlé à Jenny ? lui a-t-il déjà
# montré le ticket ?). L'Inventaire sait ce qu'on POSSÈDE, la Carte sait où
# l'on PEUT aller — mais aucun des deux ne retient ce qui s'est PASSÉ. C'est
# le rôle de ce service : une petite ardoise de FAITS.
#
# Un "fait" = un simple identifiant texte qu'on POSE une fois
# ("jenny_premier_contact") et qu'on peut RELIRE partout ensuite. On ne
# stocke RIEN d'autre : pas de compte, pas de valeur — juste "vu / pas vu".
# (Les valeurs chiffrées, c'est la santé mentale, la vie, plus tard la
# réputation : d'autres services.)
#
# Pourquoi un AUTOLOAD ? Comme l'Inventaire et la Carte, ces faits doivent
# SURVIVRE aux changements de pièce. (Règle A.9 : un savoir partagé et
# global se construit UNE fois, ici.)
#
# NOTE (L.6) : pour l'instant cette mémoire vit en RAM, le temps d'un run.
# Le jour où l'on fera une vraie sauvegarde, c'est CE service qu'on
# sérialisera — sans rien changer pour ceux qui l'appellent.

extends Node


# Émis à chaque NOUVEAU fait noté. Un futur écran (tableau d'enquête,
# carnet…) pourra s'y abonner pour réagir tout seul, comme la Carte le
# fait avec son propre signal.
signal fait_note(id: String)


# L'ardoise : l'ensemble des faits déjà survenus. On se sert d'un
# Dictionary comme d'un "ensemble" : la CLÉ est le fait ; la valeur, peu
# importe (toujours true).
var _faits: Dictionary = {}


func _ready() -> void:
    print("Progression prête.")


# Pose un fait. Renvoie true s'il était NOUVEAU (pratique pour ne réagir
# qu'UNE fois), false s'il avait déjà été posé. Idempotent : reposer le
# même fait ne casse rien et n'émet pas deux fois le signal.
func marquer(id: String) -> bool:
    if id == "":
        return false
    if _faits.has(id):
        return false
    _faits[id] = true
    fait_note.emit(id)
    print("Progression : fait noté -> ", id)
    return true


# Ce fait s'est-il déjà produit ?
func a_vu(id: String) -> bool:
    return _faits.has(id)


# --- REMETTRE À ZÉRO (pour une nouvelle partie) ---
# Efface tous les faits. Appelé par l'écran-titre, comme les autres
# services, pour qu'une nouvelle partie reparte d'une ardoise vierge.
func reinitialiser() -> void:
    _faits.clear()
    print("Progression : remise à zéro.")
