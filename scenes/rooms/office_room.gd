# office_room.gd
# Pièce "Bureau d'Al'".
#
# Ce script est très court : toute la MÉCANIQUE (examiner, ramasser,
# voix intérieure, verrou, sortie de pièce) vit dans le moule room_base.gd.
# Ici, on ne déclare que ce qui est PROPRE au bureau :
#   - le contenu des pensées et des objets ramassables
#   - la porte (objet à comportement spécifique à cette pièce)

extends RoomBase


# --- Textes de la porte ---
const PORTE_VERROUILLEE: String = "Je ferais mieux de prendre\n mon MANTEAU et mes CLES\n avant de partir."
const PORTE_OUVERTE: String = "Bon, il est temps d'y aller.\n Cette enquête n'avancera pas toute seule."


# --- Contenu propre au bureau ---
# Appelée par le moule (room_base.gd) au tout début de _ready().
# On remplit ici les données de la pièce et on branche la porte.
func _definir_contenu() -> void:
    # Les objets EXAMINABLES : clé = nom du nœud Area2D, valeur = pensée.
    pensees = {
        "LampArea": "Cette lampe a vu plus de nuits blanches que moi.",
        "WindowArea": "Temps de merde, pour une ville de merde...",
        "AlcoolArea": "Ce n'est pas raisonnable durant une enquête...",
        "PaintingArea": "Je me souviens même pas avoir acheté ce truc.",
        "FilesArea": "Encore tellement de paperasse à régler.\n Si il y a bien quelque chose que je déteste,\n c'est la PAPERASSE !",
    }

    # Les objets RAMASSABLES : pour chaque zone, la pensée, l'id
    # d'inventaire et le sprite à montrer.
    objets_ramassables = {
        "JacketArea": {
            "pensee": "Mon manteau. Les CLES du bureau sont\n toujours dans la poche.",
            "id": "cles",
            "sprite": "res://assets/art/ui/item_keys.png",
        },
        "AshtrayArea": {
            "pensee": "Mon paquet. Une mauvaise habitude\n de plus à traîner.",
            "id": "cigarettes",
            "sprite": "res://assets/art/ui/item_cigarettes.png",
        },
    }

    # La porte a son propre branchement (objet à comportement).
    $DoorArea.input_event.connect(_sur_clic_porte)


# --- LA PORTE ---
# Appelée quand on clique la porte.
func _sur_clic_porte(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
    if _interactions_bloquees:
        return
    if event is InputEventMouseButton:
        if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
            # La porte s'ouvre si Al' possède les clés.
            if Inventaire.possede("cles"):
                afficher_pensee(PORTE_OUVERTE)
                _quitter_la_piece()
            else:
                afficher_pensee(PORTE_VERROUILLEE)
