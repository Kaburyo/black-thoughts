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
#   - CLIC DROIT sur une icône : ouvre un petit menu d'actions
#     ("Examiner", "Combiner").
#   - "Combiner" prend l'objet EN MAIN ; le prochain CLIC GAUCHE sur
#     un autre objet tente l'assemblage (service Combinaison). L'objet
#     en main se repère car les autres icônes s'estompent. Échap repose.
#   - le bouton "Récap" (à côté du portrait) ouvre/ferme le
#     récapitulatif de dialogue ; il ne sert que hors conversation,
#     puisque le HUD est caché pendant un dialogue (voir cacher()).
#
# Le HUD sait aussi S'EFFACER : pendant un dialogue, il se cache
# entièrement (voir cacher() / montrer()), pour que le joueur ne
# puisse pas ouvrir le carnet en pleine conversation (bible L.11).
#
# Niveaux d'interface (du moins profond au plus profond) :
#   menu fermé  ->  menu ouvert  ->  inventaire ouvert  ->  objet en main
# Échap defait toujours le niveau le plus profond d'abord.

extends CanvasLayer


# --- Identifiants des actions du menu clic droit ---
# Un numéro par action. Le PopupMenu nous renvoie ce numéro quand
# le joueur choisit une ligne ; on sait ainsi quoi faire.
const ACTION_EXAMINER: int = 0
const ACTION_COMBINER: int = 1


# --- Références aux nœuds ---
@onready var portrait: TextureButton = $AlPortrait
@onready var bouton_recap: Button = $BoutonRecap
@onready var menu_panel: Panel = $MenuPanel
@onready var inventaire_bouton: Button = $MenuPanel/InventaireBouton
@onready var inventaire_panel: Panel = $MenuPanel/InventairePanel
@onready var grille_objets: GridContainer = $MenuPanel/InventairePanel/MargeInventaire/GrilleObjets
@onready var menu_objet: PopupMenu = $MenuObjet


# --- Réglages du glissement de l'inventaire ---
const INVENTAIRE_X_OUVERT: float = 20.0     # bord gauche visible (position finale)
const INVENTAIRE_X_CACHE: float = -850.0    # bord gauche hors écran (panneau sorti)
const DUREE_GLISSEMENT: float = 0.25        # secondes que dure le glissement

# --- Réglage de la grille d'objets ---
# Taille (en pixels) d'une icône d'objet dans la grille.
const TAILLE_ICONE: float = 128.0

# Opacité des AUTRES icônes quand un objet est "en main" (les estomper
# met en avant celui qu'on tient — même principe qu'en dialogue).
const OPACITE_OBJET_ESTOMPE: float = 0.4

# Pensée d'Al' quand le joueur tente d'assembler deux objets qui ne
# vont pas ensemble.
const PENSEE_COMBINAISON_RATEE: String = "Ces deux-là n'ont rien à voir ensemble."


# --- État de l'interface ---
var _menu_ouvert: bool = false
var _inventaire_ouvert: bool = false

# Verrou : true pendant qu'une animation de l'inventaire joue.
var _inventaire_en_animation: bool = false

# Id de l'objet sur lequel on vient de faire un clic droit (celui que
# le menu d'actions concerne).
var _id_du_menu: String = ""

# Id de l'objet actuellement "pris en main" pour une combinaison.
# Vide ("") = aucun objet en main.
var _objet_en_main: String = ""


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
    bouton_recap.pressed.connect(_sur_clic_recap)

    # Quand le joueur choisit une ligne du menu clic droit,
    # le PopupMenu nous renvoie le numéro de l'action choisie.
    menu_objet.id_pressed.connect(_sur_action_menu)

    # On se tient au courant des changements de l'inventaire :
    # à chaque ajout/retrait d'objet, la grille se redessine toute seule.
    Inventaire.inventaire_modifie.connect(_rafraichir_grille)

    # Premier remplissage de la grille (objets déjà présents au lancement).
    _rafraichir_grille()


# --- Écoute du clavier ---
# Échap defait le niveau le plus profond actuellement actif.
func _unhandled_input(event: InputEvent) -> void:
    if not event.is_action_pressed("ui_cancel"):
        return
    if _objet_en_main != "":
        _reposer_objet_en_main()
    elif _inventaire_ouvert:
        fermer_inventaire()
    elif _menu_ouvert:
        fermer_menu()


# --- EFFACER / RÉAFFICHER TOUT LE HUD ---
# Appelées par le service Dialogue : le HUD disparaît pendant une
# conversation, puis revient à la fin (bible L.11).

func cacher() -> void:
    # On referme d'abord menu et inventaire : au retour, le HUD doit
    # repartir d'un état propre (rien d'ouvert).
    fermer_menu()
    visible = false


func montrer() -> void:
    visible = true


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


# --- Clic sur le bouton Récap : bascule le récapitulatif de dialogue ---
# Le HUD ne connaît ni le panneau ni l'historique : il transmet
# simplement l'ordre au service Dialogue, qui s'occupe de tout.
func _sur_clic_recap() -> void:
    Dialogue.basculer_recap()


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
    # Refermer l'inventaire repose un éventuel objet en main : état propre.
    _reposer_objet_en_main()
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
        grille_objets.add_child(_creer_icone(id_objet, fiche))

    # 3. On remet l'estompage à jour (utile si un objet est en main).
    _rafraichir_surlignage()


# Construit une icône d'objet (un TextureButton) à partir d'une fiche.
func _creer_icone(id_objet: String, fiche: ObjetInventaire) -> TextureButton:
    var icone := TextureButton.new()
    icone.texture_normal = fiche.icone

    # Taille fixe : l'image est redimensionnée pour tenir dans la case.
    icone.ignore_texture_size = true
    icone.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
    icone.custom_minimum_size = Vector2(TAILLE_ICONE, TAILLE_ICONE)

    # Nom de l'objet affiché au survol (infobulle native de Godot).
    icone.tooltip_text = fiche.nom_affiche

    # On garde l'id de l'objet SUR l'icône : sert à l'estompage pour
    # retrouver l'icône de l'objet "en main".
    icone.set_meta("id_objet", id_objet)

    # On écoute les clics "bruts" sur l'icône (clic droit = menu,
    # clic gauche = tentative de combinaison si un objet est en main).
    # bind(id_objet) : on retient de quel objet il s'agit.
    icone.gui_input.connect(_sur_input_icone.bind(id_objet))

    return icone


# --- Clic "brut" sur une icône d'objet ---
func _sur_input_icone(event: InputEvent, id_objet: String) -> void:
    if not (event is InputEventMouseButton and event.pressed):
        return
    if event.button_index == MOUSE_BUTTON_RIGHT:
        _ouvrir_menu_objet(id_objet)
    elif event.button_index == MOUSE_BUTTON_LEFT:
        # Le clic gauche ne sert (pour l'instant) qu'à désigner le 2e
        # morceau quand un objet est déjà en main.
        if _objet_en_main != "":
            _tenter_combinaison_avec(id_objet)


# Ouvre le menu d'actions, à l'endroit de la souris, pour cet objet.
func _ouvrir_menu_objet(id_objet: String) -> void:
    _id_du_menu = id_objet

    # On (re)construit la liste des actions à chaque ouverture.
    # Les actions restent toujours présentes (non contextuelles).
    menu_objet.clear()
    menu_objet.add_item("Examiner", ACTION_EXAMINER)
    menu_objet.add_item("Combiner", ACTION_COMBINER)

    # On place le menu sous le curseur, puis on l'affiche.
    menu_objet.position = Vector2i(get_viewport().get_mouse_position())
    menu_objet.popup()


# --- Le joueur a choisi une ligne du menu d'actions ---
func _sur_action_menu(id_action: int) -> void:
    if _id_du_menu == "":
        return
    match id_action:
        ACTION_EXAMINER:
            var fiche: ObjetInventaire = CatalogueObjets.fiche_de(_id_du_menu)
            if fiche != null:
                Voix.afficher_pensee(fiche.description)
        ACTION_COMBINER:
            _prendre_en_main(_id_du_menu)


# --- Objet "en main" pour une combinaison ---

# Prend un objet en main : on note son id et on estompe les autres.
func _prendre_en_main(id_objet: String) -> void:
    _objet_en_main = id_objet
    _rafraichir_surlignage()


# Repose l'objet en main (annulation) : plus rien d'estompé.
func _reposer_objet_en_main() -> void:
    if _objet_en_main == "":
        return
    _objet_en_main = ""
    _rafraichir_surlignage()


# Tente d'assembler l'objet en main avec l'objet cliqué.
func _tenter_combinaison_avec(id_cible: String) -> void:
    # On repose AVANT d'agir : ainsi les rafraîchissements déclenchés
    # par la combinaison ne laissent aucun estompage parasite.
    var id_tenu := _objet_en_main
    _objet_en_main = ""

    # Cliquer le même objet = simple annulation.
    if id_cible == id_tenu:
        _rafraichir_surlignage()
        return

    # On demande au service d'assembler. Lui seul touche l'inventaire
    # et fait parler Al' en cas de réussite.
    var ids: Array[String] = [id_tenu, id_cible]
    var reussi := Combinaison.combiner(ids)
    if not reussi:
        Voix.afficher_pensee(PENSEE_COMBINAISON_RATEE)

    _rafraichir_surlignage()


# Met l'estompage à jour : si un objet est en main, les AUTRES icônes
# sont estompées ; sinon, toutes les icônes sont à pleine opacité.
func _rafraichir_surlignage() -> void:
    for icone in grille_objets.get_children():
        var id_icone: String = icone.get_meta("id_objet", "")
        if _objet_en_main != "" and id_icone != _objet_en_main:
            icone.modulate = Color(1, 1, 1, OPACITE_OBJET_ESTOMPE)
        else:
            icone.modulate = Color(1, 1, 1, 1)
