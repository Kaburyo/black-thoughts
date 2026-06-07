# cuisine_jenny_room.gd
# Pièce "Cuisine de Jenny" (Temps 2-bis).
#
# Toute la MÉCANIQUE vit dans le moule room_base.gd. Ici, on ne déclare
# que ce qui est PROPRE à la cuisine.
#
# ÉTAT : zones d'ambiance (examiner) + Jenny en PNJ (parler RÉACTIF +
# montrer, table complète) + porte avec confirmation (helper du moule).

extends RoomBase


# Pensée de départ propre à la cuisine (sa "voix"). PLACEHOLDER.
const PENSEE_SORTIE: String = "Assez traîné ici.\n En route."


# --- Contenu propre à la cuisine ---
func _definir_contenu() -> void:
    # RETOUR-CLÉ (étape 2) : on NOTE qu'Al' est venu chez Jenny. C'est un
    # FAIT durable (il survit aux allers-retours) que les réactions futures
    # pourront relire. marquer() est idempotent : seule la 1re entrée le
    # pose réellement (et l'affiche dans la console) ; les suivantes sont
    # silencieuses — la preuve que la mémoire persiste.
    Progression.marquer("cuisine_jenny_visitee")

    # Dernière pièce de la démo : la suite (le bar) n'existe pas encore.
    # On laisse donc scene_suivante vide -> la porte fait son fondu et
    # s'arrête là (repli géré par le moule). À renseigner quand le bar
    # sera créé : scene_suivante = "res://scenes/rooms/bar_room.tscn".

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
            # PARLER en mode RÈGLES (étape 2) : la 1re règle qui s'applique
            # gagne. La plus spécifique d'abord, le DÉFAUT en dernier.
            "parler": [
                # Si Al' lui a DÉJÀ montré le ticket, elle l'accueille
                # autrement — et laisse échapper une faille (le twist se
                # sème ici, sans rien expliquer).
                { "si_vu": "jenny_ticket_montre",
                  "conversation": "res://resources/cuisine_jenny_retour.tres" },
                # Sinon : sa conversation normale (le filet).
                { "conversation": "res://resources/cuisine_jenny_parler.tres" },
            ],
            # MONTRER : un objet en main -> la conversation correspondante.
            "objets": {
                "bar_ticket": "res://resources/cuisine_jenny_bar_ticket.tres",
                "picture_flora": "res://resources/cuisine_jenny_picture_flora.tres",
                "picture_luna_flora": "res://resources/cuisine_jenny_picture_luna_flora.tres",
            },
        },
    }
    
    
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
