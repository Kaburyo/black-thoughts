# hud.gd
# Couche d'interface persistante (autoload "Hud").
# Vit au-dessus de toutes les pièces et leur survit.
#
# Rôle actuel : gérer le menu d'Al' (le "carnet").
#   - le portrait (bas-droite) ouvre/ferme le menu.
#   - le bouton "Inventaire" ouvre/ferme la vue inventaire (bascule).
#   - la touche I ouvre/ferme le carnet+inventaire d'un coup (raccourci).
#   - la grille d'inventaire affiche les objets possédés (icônes).
#   - le nom d'un objet s'affiche au survol de son icône.
#   - CLIC DROIT sur une icône : menu d'actions "Examiner / Combiner /
#     Utiliser" (toujours visibles, non contextuelles).
#       * Examiner -> pensée d'Al' sur l'objet.
#       * Combiner -> prend l'objet EN MAIN (non persistant), carnet
#         GARDÉ ouvert ; clic gauche sur une AUTRE icône tente l'assemblage.
#         Refermer le carnet annule (repose).
#       * Utiliser -> prend l'objet EN MAIN (persistant) et REFERME le
#         carnet, pour aller cliquer une cible dans le décor.
#   - le bouton "Récap" ouvre/ferme le récapitulatif de dialogue.
#
# OBJET EN MAIN (L.26) : l'objet tenu appartient au service global
# ObjetEnMain. Un objet pris pour "Utiliser" est PERSISTANT : il survit
# à la fermeture du carnet (on va cliquer une cible au-dehors). Un objet
# pris pour "Combiner" n'est pas persistant : refermer le carnet le
# repose. ANNULATION : Échap, OU clic droit dans le décor. Un dialogue
# qui démarre repose toujours tout (voir cacher()).
# Le HUD écoute "objet_change" et réagit de DEUX façons : l'estompage
# des autres icônes + le FAUX CURSEUR (vraie souris cachée, image =
# icône de l'objet réduite).
#
# Le HUD sait aussi S'EFFACER : pendant un dialogue, il se cache
# entièrement (voir cacher() / montrer()) (bible L.11). Tant qu'il est
# caché, les raccourcis du carnet (I) sont sans effet.

extends CanvasLayer


# --- Identifiants des actions du menu clic droit ---
const ACTION_EXAMINER: int = 0
const ACTION_COMBINER: int = 1
const ACTION_UTILISER: int = 2


# --- Références aux nœuds ---
@onready var portrait: TextureButton = $AlPortrait
@onready var bouton_recap: Button = $BoutonRecap
@onready var menu_panel: Panel = $MenuPanel
@onready var inventaire_bouton: Button = $MenuPanel/InventaireBouton
@onready var inventaire_panel: Panel = $MenuPanel/InventairePanel
@onready var grille_objets: GridContainer = $MenuPanel/InventairePanel/MargeInventaire/GrilleObjets
@onready var menu_objet: PopupMenu = $MenuObjet
@onready var curseur: TextureRect = $CurseurObjet
@onready var bouton_menu: TextureButton = $BoutonMenu


# --- Réglages du glissement de l'inventaire ---
const INVENTAIRE_X_OUVERT: float = 20.0     # bord gauche visible (position finale)
const INVENTAIRE_X_CACHE: float = -850.0    # bord gauche hors écran (panneau sorti)
const DUREE_GLISSEMENT: float = 0.25        # secondes que dure le glissement

# --- Réglage de la grille d'objets ---
const TAILLE_ICONE: float = 128.0

# Opacité des AUTRES icônes quand un objet est "en main".
const OPACITE_OBJET_ESTOMPE: float = 0.4

# Taille (en pixels) de l'image du faux curseur.
const TAILLE_CURSEUR: float = 64.0

# Pensée d'Al' quand le joueur tente d'assembler deux objets qui ne
# vont pas ensemble.
const PENSEE_COMBINAISON_RATEE: String = "Ces deux-là n'ont rien à voir ensemble."


# Pensée d'Al' quand on tente de lui appliquer un objet qui n'a aucun
# effet (un objet non consommable, comme la clé).
const PENSEE_OBJET_INUTILE_AL: String = "Ça ne m'avancerait à rien."

# --- État de l'interface ---
var _menu_ouvert: bool = false
var _inventaire_ouvert: bool = false

# Verrou : true pendant qu'une animation de l'inventaire joue.
var _inventaire_en_animation: bool = false

# Id de l'objet sur lequel on vient de faire un clic droit.
var _id_du_menu: String = ""


# Appelée automatiquement une fois, au lancement.
func _ready() -> void:
    # Le menu démarre fermé. Le bouton Récap, comme le contenu du carnet,
    # n'apparaît qu'à l'ouverture du carnet — mais la touche R reste un
    # raccourci actif partout (gérée par le service Dialogue).
    menu_panel.visible = false
    bouton_recap.visible = false
    _menu_ouvert = false

    # L'inventaire démarre caché ET déjà rangé hors écran, à gauche.
    inventaire_panel.visible = false
    inventaire_panel.offset_left = INVENTAIRE_X_CACHE
    _inventaire_ouvert = false
    _inventaire_en_animation = false

    # Réglage du faux curseur : caché au départ, carré de TAILLE_CURSEUR,
    # transparent aux clics, l'image se réduit pour tenir dans le carré.
    curseur.visible = false
    curseur.texture = null
    curseur.size = Vector2(TAILLE_CURSEUR, TAILLE_CURSEUR)
    curseur.mouse_filter = Control.MOUSE_FILTER_IGNORE
    curseur.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    curseur.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

    # Branchements des clics.
    portrait.pressed.connect(_sur_clic_portrait)
    inventaire_bouton.pressed.connect(_sur_clic_inventaire)
    bouton_recap.pressed.connect(_sur_clic_recap)
    bouton_menu.pressed.connect(_sur_clic_menu)

    # Le PopupMenu nous renvoie le numéro de l'action choisie.
    menu_objet.id_pressed.connect(_sur_action_menu)

    # À chaque ajout/retrait d'objet, la grille se redessine toute seule.
    Inventaire.inventaire_modifie.connect(_rafraichir_grille)

    # À chaque changement de l'objet en main (pris ou reposé), on met à
    # jour l'estompage ET le faux curseur d'un seul coup.
    ObjetEnMain.objet_change.connect(_sur_objet_en_main_change)

    # Premier remplissage de la grille.
    _rafraichir_grille()


# --- Suivi de la souris par le faux curseur ---
func _process(_delta: float) -> void:
    if not curseur.visible:
        return
    # Point de clic au CENTRE : on décale l'image d'une demi-taille.
    var souris := get_viewport().get_mouse_position()
    curseur.position = souris - curseur.size / 2.0


# --- Raccourci clavier : la touche I bascule le carnet+inventaire ---
# Calqué sur la touche R du récap. Sans effet quand le HUD est caché
# (pendant un dialogue, le carnet est gelé).
func _input(event: InputEvent) -> void:
    if not visible:
        return
    if event is InputEventKey and event.pressed and not event.echo:
        if event.keycode == KEY_I:
            _basculer_inventaire()


# --- Écoute du clavier et de la souris "non capturée" ---
# (Ce qui arrive ici n'a été intercepté ni par un bouton, ni par une
#  icône du carnet. C'est donc l'écran de jeu "nu".)
func _unhandled_input(event: InputEvent) -> void:
    # Échap : défait le niveau le plus profond (objet en main d'abord,
    # puis l'inventaire, puis le menu).
    if event.is_action_pressed("ui_cancel"):
        if ObjetEnMain.a_un_objet():
            ObjetEnMain.reposer()
        elif _inventaire_ouvert:
            fermer_inventaire()
        elif _menu_ouvert:
            fermer_menu()
        return

    # Clic DROIT dans le décor : repose l'objet en main (annulation).
    # Le clic droit SUR une icône du carnet ouvre son menu et n'arrive
    # jamais jusqu'ici, donc aucun conflit. Si rien n'est en main, le
    # clic droit dans le décor ne fait rien.
    if event is InputEventMouseButton and event.pressed \
            and event.button_index == MOUSE_BUTTON_RIGHT:
        if ObjetEnMain.a_un_objet():
            ObjetEnMain.reposer()


# --- EFFACER / RÉAFFICHER TOUT LE HUD ---
func cacher() -> void:
    # Un dialogue commence : on repart d'un état totalement propre.
    # C'est ICI qu'on repose un éventuel objet en main, pour qu'il
    # SURVIVE au carnet fermé en jeu normal (mais pas pendant un dialogue).
    ObjetEnMain.reposer()
    fermer_menu()
    visible = false


func montrer() -> void:
    visible = true


# --- Clic sur le portrait d'Al' ---
# Avec un objet EN MAIN, le portrait est une CIBLE : on applique le
# consommable sur Al'. Sans objet, c'est le bouton d'ouverture du carnet.
func _sur_clic_portrait() -> void:
    if ObjetEnMain.a_un_objet():
        _utiliser_sur_al(ObjetEnMain.id())
        return
    if _menu_ouvert:
        fermer_menu()
    else:
        ouvrir_menu()


# --- UTILISER un objet sur Al' (le portrait) ---
func _utiliser_sur_al(id_objet: String) -> void:
    var fiche: ObjetInventaire = CatalogueObjets.fiche_de(id_objet)
    if fiche == null or fiche.effets.is_empty():
        Voix.afficher_pensee(PENSEE_OBJET_INUTILE_AL)
        return

    for effet in fiche.effets:
        effet.appliquer()

    if fiche.pensee_utilisation != "":
        Voix.afficher_pensee(fiche.pensee_utilisation)

    # Usage réussi : on consomme une charge (l'objet disparaît à 0),
    # puis on repose.
    Inventaire.consommer(id_objet)
    ObjetEnMain.reposer()


# --- Clic sur le bouton Inventaire : bascule l'inventaire ---
func _sur_clic_inventaire() -> void:
    if _inventaire_ouvert:
        fermer_inventaire()
    else:
        ouvrir_inventaire()


# --- Raccourci I : ouvre carnet+inventaire d'un coup, ou referme tout ---
func _basculer_inventaire() -> void:
    if _inventaire_ouvert:
        # Tout refermer (inventaire + carnet) : retour à zéro propre.
        fermer_menu()
    else:
        if not _menu_ouvert:
            ouvrir_menu()
        ouvrir_inventaire()


# --- Clic sur le bouton Récap ---
func _sur_clic_recap() -> void:
    Dialogue.basculer_recap()


# --- Clic sur le bouton roue crantée : ouvre le menu pause ---
# On referme d'abord le carnet (et tout objet en main) pour repartir
# d'un état propre, puis on ouvre le menu pause (service autonome qui
# met le jeu en pause).
func _sur_clic_menu() -> void:
    fermer_menu()
    MenuPause.ouvrir()


# --- Le menu (le carnet) ---
func ouvrir_menu() -> void:
    menu_panel.visible = true
    bouton_recap.visible = true
    _menu_ouvert = true


func fermer_menu() -> void:
    # Fermer le carnet referme aussi l'inventaire (on repart propre côté
    # affichage). Le repos d'un objet "Combiner" se fait dans
    # fermer_inventaire() ; un objet "Utiliser" persistant, lui, survit.
    fermer_inventaire()
    menu_panel.visible = false
    bouton_recap.visible = false
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
    # Un objet pris pour COMBINER ne sert qu'à l'intérieur du carnet :
    # si on referme, on l'annule (repose). Un objet pris pour UTILISER
    # est "persistant" : il survit à la fermeture (on va l'utiliser sur
    # le décor / Al').
    if ObjetEnMain.a_un_objet() and not ObjetEnMain.est_persistant():
        ObjetEnMain.reposer()
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
    for ancienne_icone in grille_objets.get_children():
        ancienne_icone.queue_free()

    for id_objet in Inventaire.tout():
        var fiche: ObjetInventaire = CatalogueObjets.fiche_de(id_objet)
        if fiche == null:
            continue
        grille_objets.add_child(_creer_icone(id_objet, fiche))

    _rafraichir_surlignage()


# Construit une icône d'objet (un TextureButton) à partir d'une fiche.
func _creer_icone(id_objet: String, fiche: ObjetInventaire) -> TextureButton:
    var icone := TextureButton.new()
    icone.texture_normal = fiche.icone

    icone.ignore_texture_size = true
    icone.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
    icone.custom_minimum_size = Vector2(TAILLE_ICONE, TAILLE_ICONE)

    icone.tooltip_text = fiche.nom_affiche
    icone.set_meta("id_objet", id_objet)
    icone.gui_input.connect(_sur_input_icone.bind(id_objet))

    # Pour un CONSOMMABLE (usages limités), on affiche le nombre restant
    # dans le coin bas-droite de l'icône. Un outil illimité n'affiche rien.
    if fiche.utilisations_max != ObjetInventaire.ILLIMITE:
        var compte := Label.new()
        compte.text = str(Inventaire.charges_restantes(id_objet))
        compte.add_theme_font_size_override("font_size", 28)
        compte.add_theme_color_override("font_color", Color.WHITE)
        compte.add_theme_color_override("font_outline_color", Color.BLACK)
        compte.add_theme_constant_override("outline_size", 6)
        compte.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
        compte.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
        compte.mouse_filter = Control.MOUSE_FILTER_IGNORE  # ne bloque pas le clic
        compte.set_anchors_preset(Control.PRESET_FULL_RECT)
        compte.offset_right = -6
        compte.offset_bottom = -2
        icone.add_child(compte)

    return icone


# --- Clic "brut" sur une icône d'objet ---
func _sur_input_icone(event: InputEvent, id_objet: String) -> void:
    if not (event is InputEventMouseButton and event.pressed):
        return
    if event.button_index == MOUSE_BUTTON_RIGHT:
        _ouvrir_menu_objet(id_objet)
    elif event.button_index == MOUSE_BUTTON_LEFT:
        # Clic gauche sur une icône = désigner le 2e morceau d'une
        # combinaison, seulement si un objet est déjà en main.
        if ObjetEnMain.a_un_objet():
            _tenter_combinaison_avec(id_objet)


# Ouvre le menu d'actions, à l'endroit de la souris, pour cet objet.
func _ouvrir_menu_objet(id_objet: String) -> void:
    _id_du_menu = id_objet

    # Actions toujours présentes (non contextuelles).
    menu_objet.clear()
    menu_objet.add_item("Examiner", ACTION_EXAMINER)
    menu_objet.add_item("Combiner", ACTION_COMBINER)
    menu_objet.add_item("Utiliser/Montrer", ACTION_UTILISER)

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
            # Pris pour COMBINER (non persistant) : carnet GARDÉ ouvert ;
            # on clique ensuite une autre icône pour tenter l'assemblage.
            # Refermer le carnet reposera l'objet (geste abandonné).
            ObjetEnMain.prendre(_id_du_menu, false)
        ACTION_UTILISER:
            # Pris pour UTILISER (persistant) : il survivra à la fermeture
            # du carnet. On referme alors le carnet pour aller cliquer une
            # cible dans le décor. C'est la cible qui réagira.
            ObjetEnMain.prendre(_id_du_menu, true)
            fermer_menu()


# --- Combinaison : tenter d'assembler l'objet en main avec un autre ---
func _tenter_combinaison_avec(id_cible: String) -> void:
    var id_tenu := ObjetEnMain.id()
    ObjetEnMain.reposer()

    if id_cible == id_tenu:
        return

    var ids: Array[String] = [id_tenu, id_cible]
    if not Combinaison.combiner(ids):
        Voix.afficher_pensee(PENSEE_COMBINAISON_RATEE)


# --- Réaction à un changement de l'objet en main ---
func _sur_objet_en_main_change() -> void:
    _rafraichir_surlignage()
    _rafraichir_curseur()


# Met l'estompage à jour : si un objet est en main, les AUTRES icônes
# sont estompées ; sinon, toutes les icônes sont à pleine opacité.
func _rafraichir_surlignage() -> void:
    var id_en_main := ObjetEnMain.id()
    for icone in grille_objets.get_children():
        var id_icone: String = icone.get_meta("id_objet", "")
        if id_en_main != "" and id_icone != id_en_main:
            icone.modulate = Color(1, 1, 1, OPACITE_OBJET_ESTOMPE)
        else:
            icone.modulate = Color(1, 1, 1, 1)


# Met le faux curseur à jour selon l'objet en main.
func _rafraichir_curseur() -> void:
    if ObjetEnMain.a_un_objet():
        var fiche: ObjetInventaire = CatalogueObjets.fiche_de(ObjetEnMain.id())
        if fiche != null:
            curseur.texture = fiche.icone
        curseur.visible = true
        Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
    else:
        curseur.visible = false
        curseur.texture = null
        Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


# --- CURSEUR : BASCULE MENU <-> JEU ---
# Force la VRAIE souris à réapparaître et cache le faux curseur-objet.
# À appeler quand on ouvre un menu PAR-DESSUS le jeu (menu pause) ou
# qu'on quitte vers le titre : sinon, un objet en main laisse la vraie
# souris invisible et le faux curseur figé -> impossible de cliquer.
func curseur_systeme() -> void:
    curseur.visible = false
    Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


# Rétablit le curseur du JEU : le faux curseur-objet si un objet est en
# main, sinon la vraie souris. À appeler quand on REVIENT au jeu.
func curseur_jeu() -> void:
    _rafraichir_curseur()
