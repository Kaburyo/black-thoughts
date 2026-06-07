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
#  Cet autoload tourne TOUJOURS, même en pause (process_mode ALWAYS),
#  sinon ses propres boutons seraient gelés.
#
#  CURSEUR : quand un objet est en main, le HUD cache la vraie souris au
#  profit d'un faux curseur qui suit le _process du HUD. En pause, ce
#  _process gèle -> plus de curseur utilisable. On rend donc la vraie
#  souris à l'ouverture, et on rétablit le curseur du jeu à la reprise.
# ============================================================

const SCENE_TITRE: String = "res://scenes/ui/ecran_titre.tscn"

@onready var voile: ColorRect = $Voile
@onready var bouton_reprendre: Button = $Voile/Boutons/BoutonReprendre
@onready var bouton_quitter: Button = $Voile/Boutons/BoutonQuitter

var _ouvert: bool = false


func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    visible = false
    bouton_reprendre.pressed.connect(reprendre)
    bouton_quitter.pressed.connect(_quitter_vers_titre)


# --- OUVRIR LE MENU ---
func ouvrir() -> void:
    if _ouvert:
        return
    _ouvert = true
    visible = true
    get_tree().paused = true
    # La vraie souris doit réapparaître pour cliquer les boutons du menu.
    Hud.curseur_systeme()


# --- REPRENDRE ---
func reprendre() -> void:
    if not _ouvert:
        return
    _ouvert = false
    get_tree().paused = false
    visible = false
    # On rend au jeu son curseur (faux curseur-objet si un objet est encore
    # en main, sinon vraie souris).
    Hud.curseur_jeu()


# --- QUITTER VERS L'ÉCRAN-TITRE ---
func _quitter_vers_titre() -> void:
    _ouvert = false
    visible = false
    get_tree().paused = false
    # On garde la vraie souris visible pour pouvoir cliquer sur le titre.
    Hud.curseur_systeme()

    await Fondu.fondu_au_noir()
    get_tree().change_scene_to_file(SCENE_TITRE)
