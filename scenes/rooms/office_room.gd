# office_room.gd
# Pièce "Bureau d'Al'" — gère les interactions de type EXAMINER.
# Chaque objet cliquable affiche une pensée d'Al'.

extends Node2D


# --- Référence à la boîte de texte ---
@onready var thought_label: Label = $ThoughtLabel


# --- Les objets examinables de la pièce ---
# Clé    = nom exact du nœud Area2D dans la scène.
# Valeur = pensée d'Al' affichée quand on clique cet objet.
# Pour ajouter un objet examinable : UNE SEULE ligne à ajouter ici.
const PENSEES: Dictionary = {
    "LampArea": "Cette lampe a vu plus de nuits blanches que moi.",
    "WindowArea": "Temps de merde, pour une ville de merde...",
}


# Appelée automatiquement une fois, au lancement de la scène.
func _ready() -> void:
    # On parcourt chaque objet examinable déclaré dans PENSEES.
    for nom_zone in PENSEES:
        var zone := get_node(nom_zone) as Area2D
        var texte: String = PENSEES[nom_zone]
        # .bind(texte) attache le texte au branchement du signal.
        # Résultat : quand cette zone est cliquée, _sur_clic reçoit
        # directement la bonne pensée, sans avoir à la chercher.
        zone.input_event.connect(_sur_clic.bind(texte))


# Appelée quand une zone examinable reçoit un événement souris.
# Les 3 premiers paramètres viennent du signal ; "texte" vient du .bind().
func _sur_clic(_viewport: Node, event: InputEvent, _shape_idx: int, texte: String) -> void:
    if event is InputEventMouseButton:
        if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
            afficher_pensee(texte)


# Affiche une pensée d'Al' dans la boîte de texte.
func afficher_pensee(texte: String) -> void:
    thought_label.text = texte
    thought_label.visible = true
