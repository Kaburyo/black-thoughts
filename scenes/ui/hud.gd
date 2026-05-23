# hud.gd
# Couche d'interface persistante (autoload "Hud").
# Vit au-dessus de toutes les pièces et leur survit.
#
# Rôle actuel : gérer le menu d'Al' (le "carnet").
#   - le portrait (bas-droite) ouvre/ferme le menu.
#   - le menu se ferme aussi avec Échap.
#   - le bouton "Inventaire" ouvre/ferme la vue inventaire (bascule).
#   - l'inventaire GLISSE depuis la gauche pour entrer/sortir.
#
# Niveaux d'interface (du moins profond au plus profond) :
#   menu fermé  ->  menu ouvert  ->  inventaire ouvert
# Échap referme toujours le niveau le plus profond d'abord.
#
# À venir : contenu réel de l'inventaire (C3-b), 5 sprites du portrait,
# masquage du portrait en dialogue/cinématique (chantier D).

extends CanvasLayer


# --- Références aux nœuds ---
@onready var portrait: TextureButton = $AlPortrait
@onready var menu_panel: Panel = $MenuPanel
@onready var inventaire_bouton: Button = $MenuPanel/InventaireBouton
@onready var inventaire_panel: Panel = $MenuPanel/InventairePanel


# --- Réglages du glissement de l'inventaire ---
const INVENTAIRE_X_OUVERT: float = 20.0     # bord gauche visible (position finale)
const INVENTAIRE_X_CACHE: float = -850.0    # bord gauche hors écran (panneau sorti)
const DUREE_GLISSEMENT: float = 0.25        # secondes que dure le glissement


# --- État de l'interface ---
var _menu_ouvert: bool = false
var _inventaire_ouvert: bool = false

# Verrou : true pendant qu'une animation de l'inventaire joue.
# Empêche un nouveau clic de lancer une 2e animation par-dessus (cf. L.9).
var _inventaire_en_animation: bool = false


# Appelée automatiquement une fois, au lancement.
func _ready() -> void:
    # Le menu démarre fermé.
    menu_panel.visible = false
    _menu_ouvert = false

    # L'inventaire démarre caché ET déjà rangé hors écran, à gauche.
    inventaire_panel.visible = false
    inventaire_panel.offset_left = INVENTAIRE_X_CACHE
    _inventaire_ouvert = false
    _inventaire_en_animation = false

    # Branchements des clics.
    portrait.pressed.connect(_sur_clic_portrait)
    inventaire_bouton.pressed.connect(_sur_clic_inventaire)


# --- Écoute du clavier ---
# Échap referme le niveau le plus profond actuellement ouvert.
func _unhandled_input(event: InputEvent) -> void:
    if not event.is_action_pressed("ui_cancel"):
        return
    if _inventaire_ouvert:
        fermer_inventaire()
    elif _menu_ouvert:
        fermer_menu()


# --- Clic sur le portrait : bascule le menu ---
func _sur_clic_portrait() -> void:
    if _menu_ouvert:
        fermer_menu()
    else:
        ouvrir_menu()


# --- Clic sur le bouton Inventaire : bascule l'inventaire ---
func _sur_clic_inventaire() -> void:
    if _inventaire_ouvert:
        fermer_inventaire()
    else:
        ouvrir_inventaire()


# --- Le menu (le carnet) ---
func ouvrir_menu() -> void:
    menu_panel.visible = true
    _menu_ouvert = true


func fermer_menu() -> void:
    # Fermer le carnet referme aussi l'inventaire : on repart d'un état propre.
    fermer_inventaire()
    menu_panel.visible = false
    _menu_ouvert = false


# --- La vue inventaire : ouverture/fermeture avec glissement ---
func ouvrir_inventaire() -> void:
    # Verrou : on ignore le clic si une animation est déjà en cours.
    if _inventaire_en_animation:
        return
    # Déjà ouvert : rien à faire.
    if _inventaire_ouvert:
        return

    _inventaire_ouvert = true
    _glisser_inventaire(INVENTAIRE_X_OUVERT)


func fermer_inventaire() -> void:
    # Verrou : on ignore le clic si une animation est déjà en cours.
    if _inventaire_en_animation:
        return
    # Déjà fermé : rien à faire.
    if not _inventaire_ouvert:
        return

    _inventaire_ouvert = false
    _glisser_inventaire(INVENTAIRE_X_CACHE)


# --- Le glissement lui-même ---
# Fait voyager le panneau jusqu'à la position x demandée.
func _glisser_inventaire(x_cible: float) -> void:
    # On lève le verrou : plus aucun clic ne sera pris pendant le voyage.
    _inventaire_en_animation = true

    # Le panneau doit être visible pour qu'on voie le glissement
    # (utile surtout à l'ouverture, où il part de l'état caché).
    inventaire_panel.visible = true

    # Animation : on déplace le bord gauche du panneau jusqu'à la cible.
    var tween := create_tween()
    tween.tween_property(inventaire_panel, "offset_left", x_cible, DUREE_GLISSEMENT)
    await tween.finished

    # Si on vient de fermer, le panneau est hors écran : on le cache vraiment.
    if not _inventaire_ouvert:
        inventaire_panel.visible = false

    # Voyage terminé : on baisse le verrou.
    _inventaire_en_animation = false
