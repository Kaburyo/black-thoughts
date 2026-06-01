extends Control

# ============================================================
#  CINÉMATIQUE D'INTRO — Planche BD façon "Blacksad"
#
#  Déroulé :
#    0. Carton-titre : "BLACK THOUGHTS" + "Chapitre 1 : ...".
#    1. Écran noir, cases invisibles, la musique tourne déjà.
#    2. Les trois cases apparaissent une à une (fondu court).
#    3. Sur la dernière case, l'image 3 laisse place à l'image 4
#       (l'ombre de la main se lève) -> effet "comic animé".
#    4. "TOC TOC" : lettrage BD + SFX ; la musique PLONGE en fond
#       (elle ne se coupe pas, elle reste discrète).
#    5. Lettrage "Entrez." (dans l'image, pas une pensée).
#    6. SFX d'ouverture de porte + fondu au noir, et la musique
#       fait son fade-out EN MÊME TEMPS que l'écran.
#    7. On charge le bureau, qui enchaîne sur l'entretien.
#
#  Réutilise le service Fondu (fondu écran). Le portrait d'Al' du
#  HUD est masqué le temps de la cinématique : il réapparaît tout
#  seul à la fin de l'entretien (Dialogue rappelle Hud.montrer()).
# ============================================================


# --- Rythme du carton-titre ---
const TITRE_FONDU_IN: float = 1.2
const TITRE_ENTRE_DEUX: float = 0.7  # pause entre le titre et le sous-titre
const TITRE_HOLD: float = 2.6
const TITRE_FONDU_OUT: float = 1.0
const TITRE_AVANT_CASES: float = 0.5

# --- Rythme des cases ---
const FONDU_CASE: float = 1.0        # apparition d'une case
const PAUSE_APRES_CASE: float = 2.0  # temps de lecture entre deux cases
const SWITCH_IMAGE_3_4: float = 0.15 # bascule image 3 -> 4 (rapide = "animé")

# --- Rythme du climax ---
const AVANT_LE_TOC: float = 0.6      # tension avant les coups
const APRES_LE_TOC: float = 1.5      # le temps des coups, avant "Entrez."
const APRES_ENTREZ: float = 1.0      # respiration avant de partir

# --- Musique ---
const MUSIQUE_DB_FOND: float = -10.0 # niveau "en fond" pendant le climax
const DUCK_DUREE: float = 1.5        # temps pour plonger en fond
const FADE_FINAL_DUREE: float = 0.7  # fade-out final, calé sur le fondu écran

# Scène à charger une fois la cinématique finie.
const SCENE_BUREAU: String = "res://scenes/rooms/office_room.tscn"


# --- Références aux nœuds ---
@onready var case1: TextureRect = $Case1
@onready var case2: TextureRect = $Case2
@onready var case3: TextureRect = $Case3
@onready var case3_detail: TextureRect = $Case3/Case3_detail  # image 4
@onready var lettrage_toc: Label = $LettrageTocToc
@onready var boite_dialogue: Panel = $BoiteDialogue
@onready var lettrage_entrez: Label = $BoiteDialogue/LettrageEntrez
@onready var carton_titre: Control = $CartonTitre
@onready var titre_jeu: Label = $CartonTitre/TitreJeu
@onready var sous_titre: Label = $CartonTitre/SousTitre
@onready var musique: AudioStreamPlayer = $MusiqueIntro
@onready var sfx_toc_toc: AudioStreamPlayer = $SfxTocToc
@onready var sfx_porte: AudioStreamPlayer = $SfxPorteOuvre


func _ready() -> void:
    # Le portrait d'Al' (et tout le HUD) ne doit pas s'afficher pendant
    # la cinématique. On le cache ; il reviendra de lui-même à la fin de
    # l'entretien (le service Dialogue rappelle Hud.montrer()).
    Hud.cacher()

    # État de départ : tout est invisible, on révèlera au bon moment.
    case1.modulate.a = 0.0
    case2.modulate.a = 0.0
    case3.modulate.a = 0.0

    # Les lettrages BD sont posés mais cachés. On règle leur texte ici :
    # le "TOC TOC" tient sur deux lignes pour le rythme des quatre coups.
    lettrage_toc.text = "TOC TOC\nTOC TOC..."
    lettrage_toc.modulate.a = 0.0
    boite_dialogue.modulate.a = 0.0

    # Carton-titre : on neutralise ses deux textes dès maintenant pour
    # éviter un flash à pleine opacité avant le début de l'animation.
    titre_jeu.modulate.a = 0.0
    sous_titre.modulate.a = 0.0

    # On peut arriver ici avec l'écran ENCORE NOIR : l'écran-titre fait un
    # fondu au noir avant de lancer la cinématique, et ce voile (service
    # Fondu, persistant) resterait opaque par-dessus toute la scène. On
    # révèle donc l'écran maintenant que tout est en place et invisible :
    # le voile se lève sur le fond noir de la cinématique, puis le carton-
    # titre apparaît proprement. (Lancée seule en F6, le voile est déjà
    # transparent : cet appel est alors sans effet visible. Sûr partout.)
    Fondu.fondu_depuis_noir()

    _jouer_cinematique()


func _jouer_cinematique() -> void:
    # 0. Carton-titre.
    await _jouer_carton_titre()

    # 1. Les cases apparaissent une à une.
    await _faire_apparaitre(case1)
    await get_tree().create_timer(PAUSE_APRES_CASE).timeout

    await _faire_apparaitre(case2)
    await get_tree().create_timer(PAUSE_APRES_CASE).timeout

    await _faire_apparaitre(case3)
    await get_tree().create_timer(PAUSE_APRES_CASE).timeout

    # 2. Switch "animé" : l'ombre de la main se lève (image 3 -> image 4).
    await _basculer_vers_image_4()

    # 3. Tension, puis les coups : lettrage + SFX + la musique plonge.
    await get_tree().create_timer(AVANT_LE_TOC).timeout
    _toc_toc()
    await get_tree().create_timer(APRES_LE_TOC).timeout

    # 4. La réponse, en lettrage dans l'image.
    _pop(boite_dialogue)
    await get_tree().create_timer(APRES_ENTREZ).timeout

    # 5. Ouverture de porte + fondu, puis on entre dans le bureau.
    await _aller_au_bureau()


# --- CARTON-TITRE ---
# Écran noir, puis le titre du jeu apparaît, PUIS le sous-titre en
# dessous. Temps de lecture, puis tout disparaît ensemble.
func _jouer_carton_titre() -> void:
    carton_titre.visible = true
    carton_titre.modulate.a = 1.0   # le conteneur est visible...
    titre_jeu.modulate.a = 0.0      # ...mais ses deux textes partent invisibles
    sous_titre.modulate.a = 0.0

    # 1. Le titre du jeu apparaît.
    var apparition_titre := create_tween()
    apparition_titre.tween_property(titre_jeu, "modulate:a", 1.0, TITRE_FONDU_IN)
    await apparition_titre.finished

    # Petite respiration avant le sous-titre.
    await get_tree().create_timer(TITRE_ENTRE_DEUX).timeout

    # 2. Puis le sous-titre, en dessous.
    var apparition_sous := create_tween()
    apparition_sous.tween_property(sous_titre, "modulate:a", 1.0, TITRE_FONDU_IN)
    await apparition_sous.finished

    # 3. Temps de lecture, puis tout le carton disparaît d'un bloc.
    await get_tree().create_timer(TITRE_HOLD).timeout

    var disparition := create_tween()
    disparition.tween_property(carton_titre, "modulate:a", 0.0, TITRE_FONDU_OUT)
    await disparition.finished

    carton_titre.visible = false
    await get_tree().create_timer(TITRE_AVANT_CASES).timeout


# Fait apparaître une case en fondu (et attend la fin du fondu).
func _faire_apparaitre(case: TextureRect) -> void:
    var tween := create_tween()
    tween.tween_property(case, "modulate:a", 1.0, FONDU_CASE)
    await tween.finished


# Bascule la dernière case de l'image 3 vers l'image 4 : on fait
# apparaître le détail (image 4) par-dessus, en fondu très court,
# pour un effet de dessin qui "bouge".
func _basculer_vers_image_4() -> void:
    case3_detail.modulate.a = 0.0
    case3_detail.visible = true
    var tween := create_tween()
    tween.tween_property(case3_detail, "modulate:a", 1.0, SWITCH_IMAGE_3_4)
    await tween.finished


# Les coups à la porte : le SFX joue, le lettrage "TOC TOC" claque,
# et la musique PLONGE en fond (sans se couper).
func _toc_toc() -> void:
    sfx_toc_toc.play()
    _pop(lettrage_toc)
    var duck := create_tween()
    duck.tween_property(musique, "volume_db", MUSIQUE_DB_FOND, DUCK_DUREE)


# Petit "pop" de lettrage façon BD : surgit en grossissant puis se cale.
func _pop(noeud: Control) -> void:
    noeud.scale = Vector2(1.25, 1.25)
    noeud.modulate.a = 0.0
    var tween := create_tween()
    tween.set_parallel(true)
    tween.tween_property(noeud, "modulate:a", 1.0, 0.12)
    tween.tween_property(noeud, "scale", Vector2.ONE, 0.22) \
        .set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


# Transition finale, calquée sur la sortie de pièce du jeu :
# son de porte + fondu au noir, ET la musique qui fait son fade-out
# en même temps que l'écran, puis chargement du bureau.
#
# Le service Fondu est un autoload PERSISTANT : après le fondu au noir,
# son voile reste opaque même une fois le bureau chargé. Le bureau ne
# se révèle pas tout seul ; on rallume donc l'écran ici, juste après
# avoir basculé sur sa scène. Ainsi le bureau reste intact.
func _aller_au_bureau() -> void:
    sfx_porte.play()

    # La musique s'éteint en même temps que l'image (fade-out parallèle).
    var fade_musique := create_tween()
    fade_musique.tween_property(musique, "volume_db", -60.0, FADE_FINAL_DUREE)

    await Fondu.fondu_au_noir(FADE_FINAL_DUREE)
    musique.stop()

    get_tree().change_scene_to_file(SCENE_BUREAU)
    # Pas d'await ici : ce nœud va être libéré par le changement de scène.
    # Le fondu tourne sur l'autoload Fondu (persistant) et se terminera seul.
    Fondu.fondu_depuis_noir()
