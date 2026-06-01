# chambre_luna_room.gd
# Pièce "Chambre de Luna".
#
# Ce script est court : toute la MÉCANIQUE (examiner, ramasser, quitter,
# verrou, sortie de pièce) vit dans le moule room_base.gd. La voix
# intérieure est le service autoload "Voix".
# Ici, on ne déclare que ce qui est PROPRE à la chambre :
#   - le contenu des pensées et des objets ramassables
#   - la porte (elle exige le ticket de bar ; sinon, fouiller encore)

extends RoomBase


# --- Textes de la porte ---
const PORTE_VERROUILLEE: String = "Je ferais mieux de chercher un peu\n avant de retourner voir Jenny."
const PORTE_OUVERTE: String = "Allons voir Jenny, elle pourra surement m'aiguiller"


# --- Contenu propre à la chambre ---
# Appelée par le moule (room_base.gd) au tout début de _ready().
func _definir_contenu() -> void:
    # Après la chambre, on retourne voir Jenny : sa cuisine.
    # (Note : le fichier de cette scène est en PascalCase, contrairement
    #  aux autres pièces — nommage à harmoniser un jour.)
    scene_suivante = "res://scenes/rooms/cuisine_jenny_room.tscn"

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
            "sprite": "res://assets/art/characters/picture/picture_flora.png",
        },
        "RobeArea": {
            "pensee": "Tiens, tiens, tiens.\n Qu'est ce qu'on a là ?",
            "id": "bar_ticket",
            "sprite": "res://assets/art/ui/item_barticket_clean.png",
        },
    }

    # La porte a son propre branchement (comportement propre à la pièce).
    $PorteChambreArea.input_event.connect(_sur_clic_porte)

    # --- LA PHOTO DE FLORA (cohérence avec la photo de Luna du bureau) ---
    # La demi-photo est POSÉE sur la poubelle dès le départ : son sprite
    # est visible (réduit), et la zone est cliquable. Une fois ramassée
    # (rangée dans l'inventaire), on la retire de la poubelle.
    _montrer_photo_flora(true)
    Inventaire.inventaire_modifie.connect(_sur_inventaire_modifie)


# --- LA PHOTO DE FLORA : visible sur la poubelle, puis retirée ---

# Montre ou cache la photo sur la poubelle, EN MÊME TEMPS que sa zone
# cliquable : on ne peut jamais cliquer une photo invisible, ni voir une
# photo non cliquable. (Même principe que _montrer_photo() du bureau.)
func _montrer_photo_flora(est_visible: bool) -> void:
    $PoubelleArea.visible = est_visible
    $PoubelleArea.input_pickable = est_visible


# L'inventaire a changé : si la photo de Flora vient d'y entrer, on
# l'enlève de la poubelle.
func _sur_inventaire_modifie() -> void:
    if Inventaire.possede("picture_flora"):
        _montrer_photo_flora(false)


# --- LA PORTE ---
# Clic sur la porte :
#   - un objet en main          -> "Inutile ici." (rien à utiliser ici) ;
#   - mains vides + ticket de bar -> "Quitter la pièce ?" puis sortie ;
#   - mains vides sans ticket   -> on invite Al' à fouiller encore.
func _sur_clic_porte(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
    if _interactions_bloquees:
        return
    if not (event is InputEventMouseButton):
        return
    if not (event.button_index == MOUSE_BUTTON_LEFT and event.pressed):
        return

    if ObjetEnMain.a_un_objet():
        Voix.afficher_pensee(PENSEE_OBJET_INUTILE)
        return

    if Inventaire.possede("bar_ticket"):
        demander_a_quitter(PORTE_OUVERTE)
    else:
        Voix.afficher_pensee(PORTE_VERROUILLEE)
