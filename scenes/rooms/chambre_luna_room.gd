# chambre_luna_room.gd — Pièce "Chambre de Luna".
extends RoomBase


# Pensée si Al' tente de partir sans le ticket (indice dur, anti-softlock).
const PORTE_VERROUILLEE: String = "Je ferais mieux de chercher un peu\n avant de retourner voir Jenny."


func _definir_contenu() -> void:
    pensees = {
        "LitArea": "Son lit à été fait,\n soit par elle, soit par sa mère.",
        "PeluchesArea": "Elle aime visiblement les peluches,\n je note...",
        "BureauArea": "On peut voir à son bureau que c'est une fille studieuse.",
        "FenetreArea": "Toujours cette météo pourri à la con...",
        "CadreArea": "Tiens ?\n On a clairement retirer la photo du cadre récemment.",
        "ArmoireLivresArea": "C'est remplit de livre à ras bord.\n Dont je ne comprendrais même pas la moitié. ",
        "ArmoireRobesArea": "Ma mère m'a toujours dit :\n Al', les gardes robes des femmes,\n c'est privé !",
        "LivresArea": "Je peux voir qu'elle aime les livres d'enquêtes.\n Moi aussi.\n Et heureusement...",
    }

    objets_ramassables = {
        "PoubelleArea": {
            "pensee": "Pourquoi cette moité de photo est à la poubelle ?\n Je devrais poser des questions à Jenny\n à son sujet!",
            "id": "picture_flora",
            "sprite": "res://assets/art/characters/picture/picture_flora.png",
        },
        "RobeArea": {
            "pensee": "Tiens, tiens, tiens.\n Qu'est ce qu'on a là ?",
            "id": "bar_ticket",
            "sprite": "res://assets/art/ui/item_barticket_clean.png",
        },
    }

    # La PORTE : la 1re sortie exige le ticket (indice dur) et ouvre la cuisine.
    porte = {
        "zone": "PorteChambreArea",
        "fait_sortie": "chambre_quittee",
        "objet_requis": "bar_ticket",
        "pensee_manque": PORTE_VERROUILLEE,
        "debloque": "cuisine_jenny",
    }

    # La demi-photo de Flora est posée sur la poubelle au départ.
    # Visible tant qu'elle n'est pas ramassée (y compris si on revient).
    _montrer_photo_flora(not Inventaire.possede("picture_flora"))
    Inventaire.inventaire_modifie.connect(_sur_inventaire_modifie)


func _montrer_photo_flora(est_visible: bool) -> void:
    $PoubelleArea.visible = est_visible
    $PoubelleArea.input_pickable = est_visible


# L'inventaire a changé : si la photo de Flora vient d'y entrer, on
# l'enlève de la poubelle. (Le déblocage de la cuisine ne se fait PLUS au
# ramassage du ticket : il a lieu à la 1re sortie par la porte.)
func _sur_inventaire_modifie() -> void:
    if Inventaire.possede("picture_flora"):
        _montrer_photo_flora(false)
