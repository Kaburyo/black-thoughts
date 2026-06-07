# ecran_carte.gd
# L'ÉCRAN de la carte de navigation — service AUTOLOAD (global).
# Un calque qui se superpose au jeu, comme le Menu pause ou la Confirmation.
#
# Son rôle : MONTRER. Il lit le "cerveau" Carte (qui sait quelles zones
# sont ouvertes) et dessine UN BOUTON par zone. Cliquer un bouton voyage
# vers cette zone. Il ne décide RIEN des déblocages : ça, c'est Carte.

extends CanvasLayer


# --- Couleurs et polices reprises de l'identité visuelle du jeu ---
const COULEUR_VOILE: Color = Color(0.0, 0.0, 0.0, 0.65)
const COULEUR_FOND_PANNEAU: Color = Color(0.078, 0.067, 0.051, 1.0)
const COULEUR_BORDURE: Color = Color(0.902, 0.882, 0.831, 1.0)
const COULEUR_TEXTE: Color = Color(0.902, 0.882, 0.831, 1.0)
const COULEUR_TEXTE_TERNE: Color = Color(0.694, 0.671, 0.616, 1.0)
const COULEUR_TEXTE_SURVOL: Color = Color(1.0, 1.0, 1.0, 1.0)

const POLICE_TITRE: String = "res://assets/fonts/PirataOne-Regular.ttf"
const POLICE_TEXTE: String = "res://assets/fonts/Amarante-Regular.ttf"

const DUREE_FONDU_MUSIQUE: float = 0.6

# Le conteneur qu'on vide puis remplit à chaque ouverture.
var _liste_boutons: VBoxContainer

# Vrai pendant qu'une conversation (service Dialogue) est en cours. Sert
# de VERROU : la carte refuse de s'ouvrir tant qu'un dialogue n'est pas
# fini, peu importe qui tente de l'ouvrir.
var _dialogue_en_cours: bool = false


func _ready() -> void:
    # Au-dessus des pièces (calque 0), mais SOUS le menu pause (calque 100).
    layer = 90
    _construire_ui()
    visible = false

    # Quand une zone se débloque, l'écran se redessine TOUT SEUL.
    Carte.carte_modifiee.connect(_rafraichir_boutons)

    # On suit l'état des dialogues pour notre verrou de sécurité.
    Dialogue.conversation_demarree.connect(_sur_dialogue_demarre)
    Dialogue.conversation_terminee.connect(_sur_dialogue_termine)


func _sur_dialogue_demarre() -> void:
    _dialogue_en_cours = true


func _sur_dialogue_termine() -> void:
    _dialogue_en_cours = false


# --- API PUBLIQUE (ce que les portes appellent) ---

# Ouvre la carte. REFUSE de s'ouvrir pendant un dialogue (ceinture de
# sûreté contre une téléportation en plein milieu d'une conversation).
func ouvrir() -> void:
    if _dialogue_en_cours:
        return
    _rafraichir_boutons()
    visible = true


# Ferme la carte sans voyager (on reste où on est).
func fermer() -> void:
    visible = false


# --- CONSTRUCTION DE L'INTERFACE (faite une seule fois, au démarrage) ---
func _construire_ui() -> void:
    var police_titre: Font = load(POLICE_TITRE)
    var police_texte: Font = load(POLICE_TEXTE)

    # 1. Le voile sombre qui couvre tout l'écran ET bloque les clics
    #    sur ce qu'il y a derrière (la pièce reste intouchable).
    var voile := ColorRect.new()
    voile.color = COULEUR_VOILE
    voile.set_anchors_preset(Control.PRESET_FULL_RECT)
    voile.mouse_filter = Control.MOUSE_FILTER_STOP
    add_child(voile)

    # 2. Un centreur plein écran : il pose le panneau pile au milieu.
    var centreur := CenterContainer.new()
    centreur.set_anchors_preset(Control.PRESET_FULL_RECT)
    centreur.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(centreur)

    # 3. Le panneau : fond sombre + fine bordure claire.
    var panneau := PanelContainer.new()
    var style := StyleBoxFlat.new()
    style.bg_color = COULEUR_FOND_PANNEAU
    style.border_color = COULEUR_BORDURE
    style.set_border_width_all(2)
    style.set_corner_radius_all(4)
    style.set_content_margin_all(40)
    panneau.add_theme_stylebox_override("panel", style)
    centreur.add_child(panneau)

    # 4. La colonne verticale : titre, puis boutons, puis "Fermer".
    var colonne := VBoxContainer.new()
    colonne.add_theme_constant_override("separation", 22)
    colonne.custom_minimum_size = Vector2(420, 0)
    panneau.add_child(colonne)

    # 5. Le titre du panneau.
    var titre := Label.new()
    titre.text = "Où se rendre ?"
    titre.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    titre.add_theme_font_override("font", police_titre)
    titre.add_theme_font_size_override("font_size", 56)
    titre.add_theme_color_override("font_color", COULEUR_TEXTE)
    colonne.add_child(titre)

    # 6. Le conteneur des boutons de zones (rempli à chaque ouverture).
    _liste_boutons = VBoxContainer.new()
    _liste_boutons.add_theme_constant_override("separation", 14)
    colonne.add_child(_liste_boutons)

    # 7. Le bouton "Fermer" (rester sur place / annuler).
    var bouton_fermer := Button.new()
    bouton_fermer.text = "Fermer"
    bouton_fermer.flat = true
    bouton_fermer.custom_minimum_size = Vector2(0, 56)
    bouton_fermer.add_theme_font_override("font", police_texte)
    bouton_fermer.add_theme_font_size_override("font_size", 28)
    bouton_fermer.add_theme_color_override("font_color", COULEUR_TEXTE_TERNE)
    bouton_fermer.add_theme_color_override("font_hover_color", COULEUR_TEXTE_SURVOL)
    bouton_fermer.pressed.connect(fermer)
    colonne.add_child(bouton_fermer)


# --- (RE)DESSINER LES BOUTONS DE ZONES ---
func _rafraichir_boutons() -> void:
    for ancien in _liste_boutons.get_children():
        _liste_boutons.remove_child(ancien)
        ancien.queue_free()

    var police_texte: Font = load(POLICE_TEXTE)

    for id in Carte.zones_debloquees():
        var bouton := Button.new()
        bouton.text = Carte.nom_de(id)
        bouton.flat = true
        bouton.custom_minimum_size = Vector2(0, 64)
        bouton.add_theme_font_override("font", police_texte)
        bouton.add_theme_font_size_override("font_size", 34)
        bouton.add_theme_color_override("font_color", COULEUR_TEXTE)
        bouton.add_theme_color_override("font_hover_color", COULEUR_TEXTE_SURVOL)
        bouton.pressed.connect(_aller_a.bind(id))
        _liste_boutons.add_child(bouton)


# --- VOYAGER VERS UNE ZONE ---
func _aller_a(id: String) -> void:
    var chemin: String = Carte.scene_de(id)
    if chemin == "":
        return
    fermer()
    _fondre_musique_piece_courante()
    await Fondu.fondu_au_noir()
    get_tree().change_scene_to_file(chemin)


# Adoucit la musique de la pièce qu'on quitte, EN MÊME TEMPS que le fondu
# au noir (au lieu d'une coupure sèche). La pièce est encore vivante sous
# la carte : on attrape son lecteur et on le baisse. Le changement de
# scène, derrière le noir, finira de la couper.
func _fondre_musique_piece_courante() -> void:
    var scene := get_tree().current_scene
    if scene is RoomBase:
        var mp: AudioStreamPlayer = scene.music_player
        var t := scene.create_tween()
        t.tween_property(mp, "volume_db", -60.0, DUREE_FONDU_MUSIQUE)


# --- RACCOURCI CLAVIER : OUVRIR / FERMER LA CARTE ---
# La touche C déplie ou replie la carte (un coup d'œil au plan d'Al').
# Garde-fous : on ne l'ouvre QUE pendant le jeu (le HUD est masqué à
# l'écran-titre et pendant la cinématique, donc C n'y fait rien) ; et
# ouvrir() refuse déjà de s'ouvrir pendant un dialogue. Si le menu pause
# est ouvert, le jeu est en pause -> cet input ne se déclenche pas.
func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo:
        if event.keycode == KEY_C:
            if visible:
                fermer()
            elif Hud.visible:
                ouvrir()
