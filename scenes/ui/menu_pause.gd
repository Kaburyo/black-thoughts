extends CanvasLayer

# ============================================================
#  MENU PAUSE — autoload "MenuPause"
#
#  Un voile plein écran avec trois choix (version pré-alpha) :
#    - "Reprendre" -> ferme le menu, le jeu repart.
#    - "Options"   -> ouvre l'écran Options par-dessus la pause.
#    - "Quitter"   -> retour à l'écran-titre.
#
#  Ouvert par le bouton roue crantée du HUD. Met le jeu en pause via
#  get_tree().paused. Tourne TOUJOURS (process_mode ALWAYS), sinon ses
#  propres boutons seraient gelés.
# ============================================================

const SCENE_TITRE: String = "res://scenes/ui/ecran_titre.tscn"

@onready var voile: ColorRect = $Voile
@onready var bouton_reprendre: Button = $Voile/Boutons/BoutonReprendre
@onready var bouton_options: Button = $Voile/Boutons/BoutonOptions
@onready var bouton_quitter: Button = $Voile/Boutons/BoutonQuitter

var _ouvert: bool = false


func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    visible = false
    bouton_reprendre.pressed.connect(reprendre)
    bouton_options.pressed.connect(_ouvrir_options)
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


# --- OUVRIR LES OPTIONS (par-dessus la pause) ---
# Le menu pause reste ouvert et en pause dessous ; l'écran Options
# s'affiche au-dessus (calque 110) et se referme sur lui-même.
func _ouvrir_options() -> void:
    EcranOptions.ouvrir()


# --- QUITTER VERS L'ÉCRAN-TITRE ---
func _quitter_vers_titre() -> void:
    _ouvert = false
    visible = false
    get_tree().paused = false
    # On garde la vraie souris visible pour pouvoir cliquer sur le titre.
    Hud.curseur_systeme()

    await Fondu.fondu_au_noir()
    get_tree().change_scene_to_file(SCENE_TITRE)
