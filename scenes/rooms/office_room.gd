# office_room.gd
# Pièce "Bureau d'Al'" — gère les interactions de type EXAMINER.
# Pour l'instant : cliquer la lampe affiche une pensée d'Al'.

extends Node2D


# --- Références aux nœuds de la scène ---
# @onready : la variable est remplie au démarrage de la scène,
# une fois que tous les nœuds existent vraiment.
@onready var lamp_area: Area2D = $LampArea
@onready var thought_label: Label = $ThoughtLabel


# --- Le texte que pense Al' quand on examine la lampe ---
# Stocké dans une constante : facile à retrouver et à modifier.
const PENSEE_LAMPE: String = "Cette lampe a vu plus de nuits blanches que moi."


# Appelée automatiquement une seule fois, au lancement de la scène.
func _ready() -> void:
    # On connecte le signal "input_event" de la zone à notre fonction.
    # Traduction : "quand LampArea reçoit un clic, préviens _sur_clic_lampe".
    lamp_area.input_event.connect(_sur_clic_lampe)


# Appelée par la zone LampArea à chaque événement de souris la concernant.
# On filtre pour ne réagir qu'au vrai clic gauche.
func _sur_clic_lampe(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
    if event is InputEventMouseButton:
        if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
            afficher_pensee(PENSEE_LAMPE)


# Affiche une pensée d'Al' dans la boîte de texte.
func afficher_pensee(texte: String) -> void:
    thought_label.text = texte
    thought_label.visible = true
