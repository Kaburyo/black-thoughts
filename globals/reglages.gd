# reglages.gd
# LES RÉGLAGES du joueur — AUTOLOAD (global).
#
# La SOURCE DE VÉRITÉ unique des préférences : volumes (général /
# musique / SFX), vitesse de jeu, mode d'affichage. Ce service garde
# chaque valeur ET l'APPLIQUE au moteur (AudioServer, Engine, fenêtre).
# Le futur menu Options ne sera qu'une VUE par-dessus : il lira/écrira
# ici, comme l'écran de carte est une vue par-dessus Carte (cerveau /
# écran séparés — règles A.8/A.9).
#
# Pourquoi un autoload ? Les réglages sont globaux et doivent survivre
# aux changements de scène. Et quand la sauvegarde (L.6) arrivera,
# c'est CE service qu'on sérialisera, sans rien changer côté UI.

extends Node


# --- Bus audio (créés à la brique précédente) ---
const BUS_GENERAL: String = "Master"
const BUS_MUSIQUE: String = "Musique"
const BUS_SFX: String = "SFX"

# --- Vitesse de jeu ---
const VITESSE_MIN: float = 1.0
const VITESSE_MAX: float = 2.5
const VITESSE_DEFAUT: float = 1.8

# --- Modes d'affichage ---
# L'ordre de cet enum = l'ordre du futur menu déroulant.
enum Affichage { FENETRE_720, FENETRE_900, PLEIN_ECRAN }
# Étiquettes lisibles (pour le menu déroulant à venir).
const AFFICHAGE_LABELS: Array[String] = [
    "Fenêtré — 1280 × 720",
    "Fenêtré — 1600 × 900",
    "Plein écran",
]
# Tailles de fenêtre associées (ignorées en plein écran).
const AFFICHAGE_TAILLES: Array[Vector2i] = [
    Vector2i(1280, 720),
    Vector2i(1600, 900),
    Vector2i(1280, 720),   # repli, non utilisé en plein écran
]


# --- Valeurs courantes (volumes en LINÉAIRE 0..1, comme un slider %) ---
var _volume_general: float = 1.0
var _volume_musique: float = 1.0
var _volume_sfx: float = 1.0
var _vitesse: float = VITESSE_DEFAUT
var _affichage: int = Affichage.FENETRE_720


func _ready() -> void:
    # Ce service doit pouvoir agir même en pause (le menu Options
    # s'ouvrira par-dessus le jeu mis en pause).
    process_mode = Node.PROCESS_MODE_ALWAYS

    # Son et vitesse : applicables immédiatement.
    _appliquer_volume(BUS_GENERAL, _volume_general)
    _appliquer_volume(BUS_MUSIQUE, _volume_musique)
    _appliquer_volume(BUS_SFX, _volume_sfx)
    _appliquer_vitesse()
    print("Reglages prêts.")

    # L'AFFICHAGE attend DEUX frames : le temps que la fenêtre principale
    # soit entièrement installée par le moteur. Sinon notre mode (plein
    # écran / taille) se fait écraser par la mise en place initiale.
    await get_tree().process_frame
    await get_tree().process_frame
    _appliquer_affichage()


# Applique TOUTES les valeurs courantes au moteur. Pratique APRÈS un
# futur chargement de sauvegarde (la fenêtre est alors déjà prête).
func _appliquer_tout() -> void:
    _appliquer_volume(BUS_GENERAL, _volume_general)
    _appliquer_volume(BUS_MUSIQUE, _volume_musique)
    _appliquer_volume(BUS_SFX, _volume_sfx)
    _appliquer_vitesse()
    _appliquer_affichage()


# ============================================================
#  VOLUMES
# ============================================================

# Règle le volume d'un bus depuis une valeur LINÉAIRE 0..1 (ce que
# manipulent les sliders). 0 = silence ; 1 = plein volume. On convertit
# en décibels (l'unité du moteur) ; 0 est traité à part car le log de 0
# n'existe pas.
func _appliquer_volume(nom_bus: String, valeur: float) -> void:
    var idx: int = AudioServer.get_bus_index(nom_bus)
    if idx == -1:
        return
    if valeur <= 0.001:
        AudioServer.set_bus_volume_db(idx, -80.0)   # silence
    else:
        AudioServer.set_bus_volume_db(idx, linear_to_db(valeur))


func definir_volume_general(valeur: float) -> void:
    _volume_general = clampf(valeur, 0.0, 1.0)
    _appliquer_volume(BUS_GENERAL, _volume_general)

func definir_volume_musique(valeur: float) -> void:
    _volume_musique = clampf(valeur, 0.0, 1.0)
    _appliquer_volume(BUS_MUSIQUE, _volume_musique)

func definir_volume_sfx(valeur: float) -> void:
    _volume_sfx = clampf(valeur, 0.0, 1.0)
    _appliquer_volume(BUS_SFX, _volume_sfx)

func volume_general() -> float:
    return _volume_general

func volume_musique() -> float:
    return _volume_musique

func volume_sfx() -> float:
    return _volume_sfx


# ============================================================
#  VITESSE DE JEU
# ============================================================

func _appliquer_vitesse() -> void:
    Engine.time_scale = _vitesse

func definir_vitesse(valeur: float) -> void:
    _vitesse = clampf(valeur, VITESSE_MIN, VITESSE_MAX)
    _appliquer_vitesse()

func vitesse() -> float:
    return _vitesse


# ============================================================
#  AFFICHAGE
# ============================================================

# On passe par get_window() (l'API de haut niveau de la fenêtre
# principale), plus robuste que DisplayServer pour ce cas.
func _appliquer_affichage() -> void:
    var w: Window = get_window()

    if _affichage == Affichage.PLEIN_ECRAN:
        w.mode = Window.MODE_FULLSCREEN
    else:
        # Mode fenêtré : on repasse en fenêtré, on règle la taille,
        # puis move_to_center() recentre proprement (et évite le calcul
        # de division entière qui déclenchait l'avertissement).
        w.mode = Window.MODE_WINDOWED
        w.size = AFFICHAGE_TAILLES[_affichage]
        w.move_to_center()

    # Trace de diagnostic : ce qu'on a demandé, et le mode RÉELLEMENT
    # obtenu (0 = Fenêtré, 3 = Plein écran...).
    print("Reglages : affichage demandé -> %s | mode fenêtre obtenu -> %d"
            % [AFFICHAGE_LABELS[_affichage], w.mode])

func definir_affichage(index: int) -> void:
    _affichage = clampi(index, 0, AFFICHAGE_LABELS.size() - 1)
    _appliquer_affichage()

func affichage() -> int:
    return _affichage
