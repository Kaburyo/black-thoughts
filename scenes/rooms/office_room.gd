# office_room.gd
# Pièce "Bureau d'Al'" — gère les interactions de type EXAMINER.
# Chaque objet cliquable affiche une pensée d'Al'.

extends Node2D


# --- Référence à la boîte de texte ---
@onready var thought_label: Label = $ThoughtLabel
# Jeton de l'animation en cours. Chaque nouvel affichage en crée un neuf ;
# une animation qui voit que le jeton a changé comprend qu'elle est périmée.
var _animation_active: int = 0


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
            # --- Réglages de l'animation du texte ---
            # Regroupés ici en constantes : faciles à ajuster sans fouiller le code.
const VITESSE_LETTRE: float = 0.02   # secondes entre deux lettres
const DUREE_LECTURE: float = 4.5     # secondes d'affichage une fois écrit
const DUREE_FONDU: float = 0.5       # secondes que dure la disparition


# Affiche une pensée d'Al' : écriture lettre par lettre, pause, puis fondu.
# Affiche une pensée d'Al' : écriture lettre par lettre, pause, puis fondu.
# Un nouvel appel rend tout appel précédent "périmé" : il s'arrêtera de lui-même.
func afficher_pensee(texte: String) -> void:
    # On crée un jeton unique pour CETTE animation.
    _animation_active += 1
    var mon_jeton: int = _animation_active

    # Préparation : Label vide, visible et opaque.
    thought_label.text = texte
    thought_label.visible_ratio = 0.0
    thought_label.modulate.a = 1.0
    thought_label.visible = true

    # Écriture lettre par lettre.
    var nb_lettres: int = texte.length()
    for i in range(nb_lettres):
        thought_label.visible_ratio = float(i + 1) / float(nb_lettres)
        await get_tree().create_timer(VITESSE_LETTRE).timeout
        # Après chaque attente : un clic plus récent a-t-il pris la main ?
        if mon_jeton != _animation_active:
            return  # Oui -> cette animation est périmée, on l'abandonne.

    # Pause de lecture.
    await get_tree().create_timer(DUREE_LECTURE).timeout
    if mon_jeton != _animation_active:
        return

    # Fondu de disparition.
    var tween := create_tween()
    tween.tween_property(thought_label, "modulate:a", 0.0, DUREE_FONDU)
    await tween.finished
    if mon_jeton != _animation_active:
        return

    # Nettoyage final.
    thought_label.visible = false
