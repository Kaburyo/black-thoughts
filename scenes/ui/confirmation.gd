# confirmation.gd
# Service global "Confirmation" — une petite fenêtre Oui / Non, stylée
# noir & blanc, réutilisable partout dans le jeu (règle 8/9).
#
# Usage depuis n'importe où :
#   Confirmation.demander("Quitter la maison ?", action_si_oui)
#   Confirmation.demander("Quitter ?", action_si_oui, action_si_non)
#
# Oui  -> on cache la fenêtre, puis on lance l'action "oui" (si fournie).
# Non  -> on cache la fenêtre, puis on lance l'action "non" (si fournie).
# Échap = Non.
# Au repos la fenêtre est invisible ; ouverte, un voile sombre attrape
# les clics pour bloquer le décor derrière.

extends CanvasLayer

# Police et couleurs reprises de la voix intérieure (cohérence N&B).
const POLICE := preload("res://assets/fonts/Amarante-Regular.ttf")
const COULEUR_FOND: Color = Color(0.15294118, 0.15294118, 0.15294118, 1.0)
const COULEUR_BLANC: Color = Color(1, 1, 1, 1)
const COULEUR_VOILE: Color = Color(0, 0, 0, 0.6)

# Taille de la boîte centrale.
const TAILLE_BOITE: Vector2 = Vector2(560, 240)

# Les actions à lancer selon le choix (mises à jour à chaque demande).
var _sur_oui: Callable = Callable()
var _sur_non: Callable = Callable()

# Le seul nœud qu'on a besoin de retrouver après coup : le texte.
var _question: Label


func _ready() -> void:
    _construire_interface()
    visible = false  # invisible au repos


# --- API PUBLIQUE ---
# Affiche la fenêtre avec une question et les actions à lancer.
func demander(question: String, sur_oui: Callable = Callable(),
        sur_non: Callable = Callable()) -> void:
    _question.text = question
    _sur_oui = sur_oui
    _sur_non = sur_non
    visible = true


# Échap pendant que la fenêtre est ouverte = Non (et on consomme la touche
# pour qu'aucun autre système ne la reçoive).
func _input(event: InputEvent) -> void:
    if not visible:
        return
    if event.is_action_pressed("ui_cancel"):
        _sur_clic_non()
        get_viewport().set_input_as_handled()


# --- CONSTRUCTION DE L'INTERFACE (une seule fois, au démarrage) ---
func _construire_interface() -> void:
    # 1. Voile sombre plein écran : assombrit ET attrape les clics.
    var voile := ColorRect.new()
    voile.color = COULEUR_VOILE
    voile.set_anchors_preset(Control.PRESET_FULL_RECT)
    voile.mouse_filter = Control.MOUSE_FILTER_STOP
    add_child(voile)

    # 2. La boîte centrale, avec le style N&B (fond sombre, bordure blanche).
    var boite := Panel.new()
    boite.anchor_left = 0.5
    boite.anchor_top = 0.5
    boite.anchor_right = 0.5
    boite.anchor_bottom = 0.5
    boite.offset_left = -TAILLE_BOITE.x / 2.0
    boite.offset_top = -TAILLE_BOITE.y / 2.0
    boite.offset_right = TAILLE_BOITE.x / 2.0
    boite.offset_bottom = TAILLE_BOITE.y / 2.0
    boite.add_theme_stylebox_override("panel", _style_boite())
    voile.add_child(boite)

    # 3. Colonne verticale : la question, puis la ligne des boutons.
    var colonne := VBoxContainer.new()
    colonne.set_anchors_preset(Control.PRESET_FULL_RECT)
    colonne.offset_left = 24
    colonne.offset_top = 24
    colonne.offset_right = -24
    colonne.offset_bottom = -24
    colonne.alignment = BoxContainer.ALIGNMENT_CENTER
    colonne.add_theme_constant_override("separation", 28)
    boite.add_child(colonne)

    # 4. La question.
    _question = Label.new()
    _question.add_theme_font_override("font", POLICE)
    _question.add_theme_font_size_override("font_size", 28)
    _question.add_theme_color_override("font_color", COULEUR_BLANC)
    _question.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _question.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    colonne.add_child(_question)

    # 5. La ligne des deux boutons.
    var ligne := HBoxContainer.new()
    ligne.alignment = BoxContainer.ALIGNMENT_CENTER
    ligne.add_theme_constant_override("separation", 40)
    colonne.add_child(ligne)

    var bouton_oui := _creer_bouton("Oui")
    bouton_oui.pressed.connect(_sur_clic_oui)
    ligne.add_child(bouton_oui)

    var bouton_non := _creer_bouton("Non")
    bouton_non.pressed.connect(_sur_clic_non)
    ligne.add_child(bouton_non)


# Fabrique le StyleBoxFlat sombre à bordure blanche (look "voix intérieure").
func _style_boite() -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = COULEUR_FOND
    style.border_width_left = 3
    style.border_width_top = 3
    style.border_width_right = 3
    style.border_width_bottom = 3
    style.border_color = COULEUR_BLANC
    style.corner_radius_top_left = 6
    style.corner_radius_top_right = 6
    style.corner_radius_bottom_right = 6
    style.corner_radius_bottom_left = 6
    return style


# Fabrique un bouton N&B simple et lisible.
func _creer_bouton(texte: String) -> Button:
    var bouton := Button.new()
    bouton.text = texte
    bouton.custom_minimum_size = Vector2(140, 56)
    bouton.add_theme_font_override("font", POLICE)
    bouton.add_theme_font_size_override("font_size", 24)
    return bouton


# --- RÉACTIONS AUX BOUTONS ---
func _sur_clic_oui() -> void:
    visible = false
    if _sur_oui.is_valid():
        _sur_oui.call()


func _sur_clic_non() -> void:
    visible = false
    if _sur_non.is_valid():
        _sur_non.call()
