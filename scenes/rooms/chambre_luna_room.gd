# office_room.gd
# Pièce "Bureau d'Al'".
#
# Ce script est très court : toute la MÉCANIQUE (examiner, ramasser,
# verrou, sortie de pièce) vit dans le moule room_base.gd. La voix
# intérieure, elle, est le service autoload "Voix".
# Ici, on ne déclare que ce qui est PROPRE au bureau :
#   - le contenu des pensées et des objets ramassables
#   - la porte (objet à comportement spécifique à cette pièce)

extends RoomBase


# --- Textes de la porte ---
const PORTE_VERROUILLEE: String = "Je ferais mieux de chercher un peu\n avant de retourner voir Jenny."
const PORTE_OUVERTE: String = "Allons voir Jenny, elle pourra surement m'aiguiller"


# --- Contenu propre au bureau ---
# Appelée par le moule (room_base.gd) au tout début de _ready().
# On remplit ici les données de la pièce et on branche la porte.
func _definir_contenu() -> void:
    # Les objets EXAMINABLES : clé = nom du nœud Area2D, valeur = pensée.
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

    # Les objets RAMASSABLES : pour chaque zone, la pensée, l'id
    # d'inventaire et le sprite à montrer.
    objets_ramassables = {
        "PoubelleArea": {
            "pensee": "Pourquoi cette moité de photo est à la poubelle ?\n Je devrais poser des questions à Jenny\n à son sujet!",
            "id": "picture_flora",
            "sprite": "res://assets/art/characters/Picture/picture_flora.png",
        },
        "RobeArea": {
            "pensee": "Tiens, tiens, tiens.\n Qu'est ce qu'on a là ?",
            "id": "bar_ticket",
            "sprite": "res://assets/art/ui/item_barticket_clean.png",
        },
    }

    # La porte a son propre branchement (objet à comportement).
    $PorteChambreArea.input_event.connect(_sur_clic_porte)


# --- LA PORTE ---
# Appelée quand on clique la porte.
func _sur_clic_porte(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
    if _interactions_bloquees:
        return
    if event is InputEventMouseButton:
        if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
            # La porte s'ouvre si Al' possède les clés.
            if Inventaire.possede("bar_ticket"):
                Voix.afficher_pensee(PORTE_OUVERTE)
                _quitter_la_piece()
            else:
                Voix.afficher_pensee(PORTE_VERROUILLEE)
