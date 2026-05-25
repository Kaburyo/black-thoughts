# portrait_al.gd
# Le PORTRAIT d'Al' — script attaché au nœud `AlPortrait` du HUD.
#
# RÔLE UNIQUE : montrer la bonne tête d'Al' selon son état PHYSIQUE.
# Le portrait lit la jauge de VIE (autoload `Vie`) et affiche l'un de
# ses 5 visages, du plus sain (palier Good) au plus blessé (Bad).
# Il se met à jour tout seul à chaque changement de la jauge, en
# écoutant le signal `Vie.modifiee`.
#
# Ce script ne s'occupe PAS du clic d'ouverture du menu : ça, c'est
# `hud.gd` qui le gère, en se branchant sur le signal `pressed` du
# bouton. Le portrait a donc deux casquettes bien séparées :
#   - SON APPARENCE  -> ce script-ci.
#   - SON RÔLE DE BOUTON -> hud.gd.
#
# LA SPRITESHEET. `al_life_state.png` est UNE seule image contenant
# 5 visages côte à côte sur 1 ligne. Pour n'en afficher qu'un, on
# utilise un `AtlasTexture` : une "fenêtre" qui ne montre qu'un
# rectangle de la grande image. Ce script découpe lui-même la
# spritesheet en 5 fenêtres au démarrage (aucune manip à la souris).

extends TextureButton


# --- Réglages de la spritesheet ---
# Chemin de l'image des 5 états d'Al'.
const CHEMIN_SPRITESHEET: String = "res://assets/art/characters/al/al_life_state.png"

# Nombre de visages dans la spritesheet (= nombre de paliers).
const NB_CASES: int = 5


# --- État interne ---
# Les 5 "fenêtres" découpées, rangées dans l'ordre des paliers :
# indice 0 = Good, 1 = Ok, 2 = Mid, 3 = Bof, 4 = Bad.
var _visages: Array[AtlasTexture] = []


# Appelée automatiquement une fois, au lancement.
func _ready() -> void:
    _decouper_spritesheet()

    # On se tient au courant des changements de la jauge de Vie :
    # à chaque coup reçu (ou soin), le portrait se redessine tout seul.
    Vie.modifiee.connect(_rafraichir)

    # Premier affichage. ATTENTION à l'ordre de démarrage : on attend
    # une frame pour être SÛR que l'autoload `Vie` a fini son propre
    # _ready() (et donc posé sa valeur de départ). Sans cette attente,
    # le portrait pourrait lire une Vie encore à 0 et afficher le
    # visage "Bad" au lancement.
    await get_tree().process_frame
    _rafraichir()


# --- Découpe de la spritesheet en 5 fenêtres ---
# Appelée une seule fois, au démarrage.
func _decouper_spritesheet() -> void:
    var feuille: Texture2D = load(CHEMIN_SPRITESHEET)

    # Largeur d'une case = largeur totale divisée par le nombre de cases.
    # Division ENTIÈRE : on reste sur des pixels entiers ; les quelques
    # pixels restants au bord droit sont sans importance.
    var largeur_case: int = feuille.get_width() / NB_CASES
    var hauteur_case: int = feuille.get_height()

    # Pour chaque case, on fabrique une fenêtre (AtlasTexture) posée
    # sur la grande image, décalée vers la droite à chaque tour.
    for i in range(NB_CASES):
        var fenetre := AtlasTexture.new()
        fenetre.atlas = feuille
        fenetre.region = Rect2(
            i * largeur_case, 0,        # coin haut-gauche de la fenêtre
            largeur_case, hauteur_case  # taille de la fenêtre
        )
        _visages.append(fenetre)


# --- Mise à jour du visage affiché ---
# Appelée au lancement, et à chaque fois que la jauge de Vie change.
func _rafraichir() -> void:
    # `Vie.palier()` renvoie une valeur de l'enum Palier (Good..Bad).
    # Cet enum est numéroté 0..4 dans le même ordre que `_visages` :
    # on s'en sert donc directement comme indice dans le tableau.
    var palier: int = Vie.palier()
    texture_normal = _visages[palier]
