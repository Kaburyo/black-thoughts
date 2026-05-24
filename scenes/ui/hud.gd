# hud.gd
# Couche d'interface persistante (autoload "Hud").
# Vit au-dessus de toutes les pièces et leur survit.
#
# Rôle actuel : gérer le menu d'Al' (le "carnet").
#   - le portrait (bas-droite) ouvre/ferme le menu.
#   - le menu se ferme aussi avec Échap.
#   - le bouton "Inventaire" ouvre/ferme la vue inventaire (bascule).
#   - l'inventaire GLISSE depuis la gauche pour entrer/sortir.
#   - la grille d'inventaire affiche les objets possédés (icônes).
#   - le nom d'un objet s'affiche au survol de son icône.
#   - cliquer une icône déclenche une pensée d'Al' qui décrit l'objet.
#
# Niveaux d'interface (du moins profond au plus profond) :
#   menu fermé  ->  menu ouvert  ->  inventaire ouvert
# Échap referme toujours le niveau le plus profond d'abord.
#
# À venir : 5 sprites du portrait selon l'état d'Al'.

extends CanvasLayer


# --- Références aux nœuds ---
@onready var portrait: TextureButton = $AlPortrait
@onready var menu_panel: Panel = $MenuPanel
@onready var inventaire_bouton: Button = $MenuPanel/InventaireBouton
@onready var inventaire_panel: Panel = $MenuPanel/InventairePanel
@onready var grille_objets: GridContainer = $MenuPanel/InventairePanel/MargeInventaire/GrilleObjets


# --- Réglages du glissement de l'inventaire ---
const INVENTAIRE_X_OUVERT: float = 20.0     # bord gauche visible (position finale)
const INVENTAIRE_X_CACHE: float = -850.0    # bord gauche hors écran (panneau sorti)
const DUREE_GLISSEMENT: float = 0.25        # secondes que dure le glissement

# --- Réglage de la grille d'objets ---
# Taille (en pixels) d'une icône d'objet dans la grille.
# Trop grand ou trop petit ? Change ce seul nombre.
const TAILLE_ICONE: float = 128.0


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

    # On se tient au courant des changements de l'inventaire :
    # à chaque ajout d'objet, la grille se redessine toute seule.
    Inventaire.inventaire_modifie.connect(_rafraichir_grille)

    # Premier remplissage de la grille (objets déjà présents au lancement).
    _rafraichir_grille()


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
    if _inventaire_en_animation:
        return
    if _inventaire_ouvert:
        return
    _inventaire_ouvert = true
    _glisser_inventaire(INVENTAIRE_X_OUVERT)


func fermer_inventaire() -> void:
    if _inventaire_en_animation:
        return
    if not _inventaire_ouvert:
        return
    _inventaire_ouvert = false
    _glisser_inventaire(INVENTAIRE_X_CACHE)


# --- Le glissement lui-même ---
func _glisser_inventaire(x_cible: float) -> void:
    _inventaire_en_animation = true
    inventaire_panel.visible = true

    var tween := create_tween()
    tween.tween_property(inventaire_panel, "offset_left", x_cible, DUREE_GLISSEMENT)
    await tween.finished

    if not _inventaire_ouvert:
        inventaire_panel.visible = false

    _inventaire_en_animation = false


# --- Remplissage de la grille d'objets ---
# Appelée au lancement, et à chaque fois que l'inventaire change.
func _rafraichir_grille() -> void:
    # 1. On vide la grille de son contenu précédent.
    for ancienne_icone in grille_objets.get_children():
        ancienne_icone.queue_free()

    # 2. Pour chaque objet possédé, on crée une icône.
    for id_objet in Inventaire.tout():
        var fiche: ObjetInventaire = CatalogueObjets.fiche_de(id_objet)
        # Sécurité : si l'objet n'est pas au catalogue, on le saute.
        if fiche == null:
            continue
        grille_objets.add_child(_creer_icone(fiche))


# Construit une icône d'objet (un TextureButton) à partir d'une fiche.
func _creer_icone(fiche: ObjetInventaire) -> TextureButton:
    var icone := TextureButton.new()
    icone.texture_normal = fiche.icone

    # Taille fixe : l'image est redimensionnée pour tenir dans la case.
    icone.ignore_texture_size = true
    icone.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
    icone.custom_minimum_size = Vector2(TAILLE_ICONE, TAILLE_ICONE)

    # Nom de l'objet affiché au survol (infobulle native de Godot).
    icone.tooltip_text = fiche.nom_affiche

    # Clic sur l'icône -> pensée d'Al' qui décrit l'objet.
    # .bind(fiche) "accroche" la fiche cliquée : elle revient en
    # argument de _sur_clic_objet quand le clic arrive.
    icone.pressed.connect(_sur_clic_objet.bind(fiche))

    return icone


# --- Clic sur un objet du carnet ---
# Al' pense la description de l'objet (sa voix intérieure).
func _sur_clic_objet(fiche: ObjetInventaire) -> void:
    Voix.afficher_pensee(fiche.description)
