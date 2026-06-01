extends CanvasLayer

# ============================================================
#  MENU PAUSE — autoload "MenuPause"
#
#  Un voile plein écran avec deux choix (version pré-alpha) :
#    - "Reprendre" -> ferme le menu, le jeu repart.
#    - "Quitter"   -> retour à l'écran-titre.
#
#  Ouvert par le bouton roue crantée du HUD (Hud appelle
#  MenuPause.ouvrir()). Met le jeu en pause via get_tree().paused.
#
#  Cet autoload tourne TOUJOURS, même en pause (process_mode ALWAYS,
#  réglé dans _ready), sinon ses propres boutons seraient gelés.
#
#  NOTE : la sauvegarde et les options viendront plus tard. Pour
#  l'instant, le strict minimum utile à un testeur.
# ============================================================

# L'écran-titre, vers lequel "Quitter" ramène.
const SCENE_TITRE: String = "res://scenes/ui/ecran_titre.tscn"

@onready var voile: ColorRect = $Voile
@onready var bouton_reprendre: Button = $Voile/Boutons/BoutonReprendre
@onready var bouton_quitter: Button = $Voile/Boutons/BoutonQuitter

var _ouvert: bool = false


func _ready() -> void:
    # Le menu doit rester actif quand le reste du jeu est en pause :
    # sans ça, ses propres boutons seraient gelés avec le reste.
    process_mode = Node.PROCESS_MODE_ALWAYS

    # Caché au départ.
    visible = false

    bouton_reprendre.pressed.connect(reprendre)
    bouton_quitter.pressed.connect(_quitter_vers_titre)


# --- OUVRIR LE MENU ---
# Appelé par le bouton roue crantée du HUD.
func ouvrir() -> void:
    if _ouvert:
        return
    _ouvert = true
    visible = true
    get_tree().paused = true


# --- REPRENDRE ---
# Ferme le menu et relance le jeu.
func reprendre() -> void:
    if not _ouvert:
        return
    _ouvert = false
    get_tree().paused = false
    visible = false


# --- QUITTER VERS L'ÉCRAN-TITRE ---
# On lève la pause AVANT le fondu (sinon le tween du fondu serait gelé),
# on assombrit l'écran, puis on charge l'écran-titre.
func _quitter_vers_titre() -> void:
    _ouvert = false
    visible = false
    get_tree().paused = false

    await Fondu.fondu_au_noir()
    get_tree().change_scene_to_file(SCENE_TITRE)
