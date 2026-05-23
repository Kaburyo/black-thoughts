# hud.gd
# Couche d'interface persistante (autoload "Hud").
# Vit au-dessus de toutes les pièces et leur survit.
#
# Rôle actuel : gérer le menu d'Al' (le "carnet").
#   - le portrait, en bas à droite, est le bouton qui ouvre/ferme le menu.
#   - le menu est caché au lancement.
#   - le menu se ferme aussi avec la touche Échap.
#
# À venir : masquage du portrait pendant dialogues/cinématiques (chantier D),
# contenu du menu (inventaire, notes) en C3.

extends CanvasLayer


# --- Références aux nœuds ---
@onready var portrait: TextureButton = $AlPortrait
@onready var menu_panel: Panel = $MenuPanel


# --- État du menu ---
# true = le carnet est ouvert et visible.
var _menu_ouvert: bool = false


# Appelée automatiquement une fois, au lancement.
func _ready() -> void:
    # Le menu démarre toujours fermé.
    menu_panel.visible = false
    _menu_ouvert = false

    # Le clic sur le portrait fait basculer le menu (ouvre/ferme).
    portrait.pressed.connect(_sur_clic_portrait)


# --- Écoute du clavier ---
# Appelée automatiquement à chaque touche pressée ou relâchée.
func _unhandled_input(event: InputEvent) -> void:
    # On ne réagit qu'à la touche Échap, et seulement si le menu est ouvert.
    if event.is_action_pressed("ui_cancel") and _menu_ouvert:
        fermer_menu()


# --- Clic sur le portrait : bascule le menu ---
func _sur_clic_portrait() -> void:
    if _menu_ouvert:
        fermer_menu()
    else:
        ouvrir_menu()


# --- Ouvrir le menu ---
func ouvrir_menu() -> void:
    menu_panel.visible = true
    _menu_ouvert = true


# --- Fermer le menu ---
func fermer_menu() -> void:
    menu_panel.visible = false
    _menu_ouvert = false
