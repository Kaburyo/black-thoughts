# cuisine_jenny_room.gd
# Pièce "Cuisine de Jenny" (Temps 2-bis).
#
# Toute la MÉCANIQUE vit dans le moule room_base.gd. Ici, on ne déclare
# que ce qui est PROPRE à la cuisine.
#
# ÉTAT : zones d'ambiance (examiner) + Jenny en PNJ (parler + montrer,
# table complète) + porte avec confirmation (helper du moule).

extends RoomBase


# Pensée de départ propre à la cuisine (sa "voix"). PLACEHOLDER.
const PENSEE_SORTIE: String = "Assez traîné ici.\n En route."


# --- Contenu propre à la cuisine ---
func _definir_contenu() -> void:
    # Zones d'AMBIANCE (examiner) : clé = nom du nœud Area2D, valeur = pensée.
    pensees = {
        "ChaiseVideArea": "Une chaise vide, en face d'elle.\n Elle ne l'a pas rangée.\n Comme si quelqu'un allait revenir s'asseoir.",
        "FenetreArea": "Des rideaux propres, repassés.\n Quelqu'un tient encore à cette maison.\n Ou s'accroche à l'idée.",
        "EvierArea": "La vaisselle est faite, rangée à sécher.\n On lave les tasses même quand le monde s'écroule.\n Question d'habitude.",
        "BouteillesArea": "Des bouteilles vides qui traînent.\n Je connais ce remède-là.\n On en partage au moins un, elle et moi.",
        "FrigoArea": "Un frigo d'un autre âge qui ronronne dans le silence.\n Le bruit le plus vivant de la pièce.",
    }

    # Jenny est PEINTE dans le décor ; sa zone cliquable est "JennyArea".
    pnj_presents = {
        "JennyArea": {
            # Clic mains vides -> sa conversation par défaut.
            "parler": "res://resources/cuisine_jenny_parler.tres",
            # MONTRER : un objet en main -> la conversation correspondante.
            "objets": {
                "bar_ticket": "res://resources/cuisine_jenny_bar_ticket.tres",
                "picture_flora": "res://resources/cuisine_jenny_picture_flora.tres",
                "picture_luna_flora": "res://resources/cuisine_jenny_picture_luna_flora.tres",
            },
        },
    }
    
######    
# --- TEST TEMPORAIRE (à retirer) ---
    Inventaire.ajouter("picture_flora")
    Inventaire.ajouter("picture_luna_flora")
######    
    
    # La porte a son propre branchement (comportement propre à la pièce).
    $PorteCuisineArea.input_event.connect(_sur_clic_porte)


# --- LA PORTE ---
# Clic sur la porte :
#   - un objet en main -> "Inutile ici." ;
#   - mains vides      -> confirmation puis sortie (helper du moule).
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

    demander_a_quitter(PENSEE_SORTIE)
