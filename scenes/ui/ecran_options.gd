# ecran_options.gd
# L'ÉCRAN des options — service AUTOLOAD (global), calque superposé.
#
# Son rôle : MONTRER et RÉGLER. Il ne stocke rien : chaque curseur lit
# et écrit le service Reglages (la source de vérité). C'est la VUE ;
# Reglages est le cerveau — même séparation que EcranCarte / Carte.
#
# Il est RÉUTILISABLE : on l'ouvre depuis le menu pause ET depuis
# l'écran-titre, avec le même EcranOptions.ouvrir().

extends CanvasLayer


# --- Couleurs et polices (identité visuelle du jeu, reprises d'EcranCarte) ---
const COULEUR_VOILE: Color = Color(0.0, 0.0, 0.0, 0.72)
const COULEUR_FOND_PANNEAU: Color = Color(0.078, 0.067, 0.051, 1.0)
const COULEUR_BORDURE: Color = Color(0.902, 0.882, 0.831, 1.0)
const COULEUR_TEXTE: Color = Color(0.902, 0.882, 0.831, 1.0)
const COULEUR_TEXTE_TERNE: Color = Color(0.694, 0.671, 0.616, 1.0)
const COULEUR_TEXTE_SURVOL: Color = Color(1.0, 1.0, 1.0, 1.0)

const POLICE_TITRE: String = "res://assets/fonts/PirataOne-Regular.ttf"
const POLICE_TEXTE: String = "res://assets/fonts/Amarante-Regular.ttf"


# Polices chargées une fois.
var _police_titre: Font
var _police_texte: Font

# Références aux contrôles, pour les resynchroniser à chaque ouverture.
var _slider_general: HSlider
var _lbl_general: Label
var _slider_musique: HSlider
var _lbl_musique: Label
var _slider_sfx: HSlider
var _lbl_sfx: Label
var _slider_vitesse: HSlider
var _lbl_vitesse: Label
var _drop_affichage: OptionButton


func _ready() -> void:
    # Au-dessus du menu pause (calque 100) pour s'afficher par-dessus lui.
    layer = 110
    # Doit fonctionner même quand le jeu est en pause (ouvert depuis la pause).
    process_mode = Node.PROCESS_MODE_ALWAYS

    _police_titre = load(POLICE_TITRE)
    _police_texte = load(POLICE_TEXTE)

    _construire_ui()
    visible = false


# --- API PUBLIQUE ---
func ouvrir() -> void:
    _synchroniser()      # les curseurs reflètent les valeurs réelles
    visible = true

func fermer() -> void:
    visible = false


# --- CONSTRUCTION DE L'INTERFACE (une seule fois) ---
func _construire_ui() -> void:
    # 1. Voile sombre plein écran qui bloque les clics derrière.
    var voile := ColorRect.new()
    voile.color = COULEUR_VOILE
    voile.set_anchors_preset(Control.PRESET_FULL_RECT)
    voile.mouse_filter = Control.MOUSE_FILTER_STOP
    add_child(voile)

    # 2. Centreur plein écran.
    var centreur := CenterContainer.new()
    centreur.set_anchors_preset(Control.PRESET_FULL_RECT)
    centreur.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(centreur)

    # 3. Panneau : fond sombre + fine bordure claire.
    var panneau := PanelContainer.new()
    var style := StyleBoxFlat.new()
    style.bg_color = COULEUR_FOND_PANNEAU
    style.border_color = COULEUR_BORDURE
    style.set_border_width_all(2)
    style.set_corner_radius_all(4)
    style.set_content_margin_all(40)
    panneau.add_theme_stylebox_override("panel", style)
    centreur.add_child(panneau)

    # 4. Colonne verticale.
    var colonne := VBoxContainer.new()
    colonne.add_theme_constant_override("separation", 22)
    colonne.custom_minimum_size = Vector2(640, 0)
    panneau.add_child(colonne)

    # 5. Titre.
    var titre := Label.new()
    titre.text = "Options"
    titre.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    titre.add_theme_font_override("font", _police_titre)
    titre.add_theme_font_size_override("font_size", 56)
    titre.add_theme_color_override("font_color", COULEUR_TEXTE)
    colonne.add_child(titre)

    # 6. Les trois volumes (0..1, affichés en %).
    var g := _ligne_slider(colonne, "Volume général", 0.0, 1.0, 0.01,
            Reglages.volume_general(), _fmt_pourcent, Reglages.definir_volume_general)
    _slider_general = g["slider"]
    _lbl_general = g["valeur"]

    var m := _ligne_slider(colonne, "Musique", 0.0, 1.0, 0.01,
            Reglages.volume_musique(), _fmt_pourcent, Reglages.definir_volume_musique)
    _slider_musique = m["slider"]
    _lbl_musique = m["valeur"]

    var s := _ligne_slider(colonne, "Effets (SFX)", 0.0, 1.0, 0.01,
            Reglages.volume_sfx(), _fmt_pourcent, Reglages.definir_volume_sfx)
    _slider_sfx = s["slider"]
    _lbl_sfx = s["valeur"]

    # 7. La vitesse de jeu (1.0 à 2.5, affichée "× x.xx").
    var v := _ligne_slider(colonne, "Vitesse de jeu",
            Reglages.VITESSE_MIN, Reglages.VITESSE_MAX, 0.05,
            Reglages.vitesse(), _fmt_vitesse, Reglages.definir_vitesse)
    _slider_vitesse = v["slider"]
    _lbl_vitesse = v["valeur"]

    # 8. L'affichage (menu déroulant).
    _ligne_affichage(colonne)

    # 9. Bouton "Fermer".
    var fermer_btn := Button.new()
    fermer_btn.text = "Fermer"
    fermer_btn.flat = true
    fermer_btn.custom_minimum_size = Vector2(0, 56)
    fermer_btn.add_theme_font_override("font", _police_texte)
    fermer_btn.add_theme_font_size_override("font_size", 28)
    fermer_btn.add_theme_color_override("font_color", COULEUR_TEXTE_TERNE)
    fermer_btn.add_theme_color_override("font_hover_color", COULEUR_TEXTE_SURVOL)
    fermer_btn.pressed.connect(fermer)
    colonne.add_child(fermer_btn)


# Construit une LIGNE "libellé — curseur — valeur" et la branche.
# `formate` transforme la valeur en texte (% ou ×x.xx) ; `setter`
# applique la valeur à Reglages. Renvoie le curseur et son label valeur.
func _ligne_slider(parent: VBoxContainer, libelle: String,
        vmin: float, vmax: float, pas: float, valeur: float,
        formate: Callable, setter: Callable) -> Dictionary:
    var ligne := HBoxContainer.new()
    ligne.add_theme_constant_override("separation", 16)
    parent.add_child(ligne)

    var nom := Label.new()
    nom.text = libelle
    nom.custom_minimum_size = Vector2(200, 0)
    nom.add_theme_font_override("font", _police_texte)
    nom.add_theme_font_size_override("font_size", 26)
    nom.add_theme_color_override("font_color", COULEUR_TEXTE)
    ligne.add_child(nom)

    var slider := HSlider.new()
    slider.min_value = vmin
    slider.max_value = vmax
    slider.step = pas
    slider.value = valeur
    slider.custom_minimum_size = Vector2(300, 0)
    slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
    ligne.add_child(slider)

    var val := Label.new()
    val.text = formate.call(valeur)
    val.custom_minimum_size = Vector2(90, 0)
    val.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    val.add_theme_font_override("font", _police_texte)
    val.add_theme_font_size_override("font_size", 26)
    val.add_theme_color_override("font_color", COULEUR_TEXTE_TERNE)
    ligne.add_child(val)

    # À chaque mouvement : on applique au moteur ET on rafraîchit l'étiquette.
    slider.value_changed.connect(func(nouvelle: float) -> void:
        setter.call(nouvelle)
        val.text = formate.call(nouvelle)
    )

    return { "slider": slider, "valeur": val }


# Construit la ligne "Affichage" avec son menu déroulant.
func _ligne_affichage(parent: VBoxContainer) -> void:
    var ligne := HBoxContainer.new()
    ligne.add_theme_constant_override("separation", 16)
    parent.add_child(ligne)

    var nom := Label.new()
    nom.text = "Affichage"
    nom.custom_minimum_size = Vector2(200, 0)
    nom.add_theme_font_override("font", _police_texte)
    nom.add_theme_font_size_override("font_size", 26)
    nom.add_theme_color_override("font_color", COULEUR_TEXTE)
    ligne.add_child(nom)

    _drop_affichage = OptionButton.new()
    _drop_affichage.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    _drop_affichage.add_theme_font_override("font", _police_texte)
    _drop_affichage.add_theme_font_size_override("font_size", 24)
    for label in Reglages.AFFICHAGE_LABELS:
        _drop_affichage.add_item(label)
    _drop_affichage.select(Reglages.affichage())
    _drop_affichage.item_selected.connect(func(index: int) -> void:
        Reglages.definir_affichage(index)
    )
    ligne.add_child(_drop_affichage)


# Recale tous les contrôles sur les valeurs réelles de Reglages.
# set_value_no_signal : on change l'aiguille SANS rejouer le setter.
func _synchroniser() -> void:
    _slider_general.set_value_no_signal(Reglages.volume_general())
    _lbl_general.text = _fmt_pourcent(Reglages.volume_general())

    _slider_musique.set_value_no_signal(Reglages.volume_musique())
    _lbl_musique.text = _fmt_pourcent(Reglages.volume_musique())

    _slider_sfx.set_value_no_signal(Reglages.volume_sfx())
    _lbl_sfx.text = _fmt_pourcent(Reglages.volume_sfx())

    _slider_vitesse.set_value_no_signal(Reglages.vitesse())
    _lbl_vitesse.text = _fmt_vitesse(Reglages.vitesse())

    _drop_affichage.select(Reglages.affichage())


# --- Mises en forme des valeurs ---
func _fmt_pourcent(v: float) -> String:
    return "%d %%" % int(round(v * 100.0))

func _fmt_vitesse(v: float) -> String:
    return "× %.2f" % v
