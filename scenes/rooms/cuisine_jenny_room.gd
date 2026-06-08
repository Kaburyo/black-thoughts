# cuisine_jenny_room.gd — Pièce "Cuisine de Jenny" (Temps 2-bis).
extends RoomBase


func _definir_contenu() -> void:
    # Retour-clé : on note la visite chez Jenny (mémoire durable).
    Progression.marquer("cuisine_jenny_visitee")

    pensees = {
        "ChaiseVideArea": "Une chaise vide, en face d'elle.\n Elle ne l'a pas rangée.\n Comme si quelqu'un allait revenir s'asseoir.",
        "FenetreArea": "Des rideaux propres, repassés.\n Quelqu'un tient encore à cette maison.\n Ou s'accroche à l'idée.",
        "EvierArea": "La vaisselle est faite, rangée à sécher.\n On lave les tasses même quand le monde s'écroule.\n Question d'habitude.",
        "BouteillesArea": "Des bouteilles vides qui traînent.\n Je connais ce remède-là.\n On en partage au moins un, elle et moi.",
        "FrigoArea": "Un frigo d'un autre âge qui ronronne dans le silence.\n Le bruit le plus vivant de la pièce.",
    }

    pnj_presents = {
        "JennyArea": {
            "parler": [
                { "si_vu": "jenny_ticket_montre",
                  "conversation": "res://resources/cuisine_jenny_retour.tres" },
                { "conversation": "res://resources/cuisine_jenny_parler.tres" },
            ],
            "objets": {
                "bar_ticket": "res://resources/cuisine_jenny_bar_ticket.tres",
                "picture_flora": "res://resources/cuisine_jenny_picture_flora.tres",
                "picture_luna_flora": "res://resources/cuisine_jenny_picture_luna_flora.tres",
            },
        },
    }

    # La PORTE : dernière pièce de la démo. Aucun objet requis, rien à
    # débloquer (le bar n'existe pas encore) : juste la validation de sortie.
    porte = {
        "zone": "PorteCuisineArea",
        "fait_sortie": "cuisine_quittee",
        "objet_requis": "",
        "pensee_manque": "",
        "debloque": "",
    }
