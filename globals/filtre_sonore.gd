# filtre_sonore.gd
# LE VOILE SONORE — le pendant AUDIO du filtre mental. AUTOLOAD (global).
#
# Quand la santé mentale d'Al' baisse, le monde ne s'assombrit pas
# seulement (vignettage du FiltreMental visuel) : il s'ÉTOUFFE aussi.
# La musique se voile, comme entendue à travers un mur, ou sous l'eau.
#
# COMMENT ? La musique passe par un BUS audio nommé "Musique", sur lequel
# on a posé UN filtre passe-bas (Low Pass Filter). Un passe-bas laisse
# passer les graves et coupe les aigus : plus on baisse sa fréquence de
# coupure, plus le son devient sourd et lointain. Ce service ne fait
# qu'UNE chose : régler cette coupure selon la santé mentale.
# (Règle A.5/A.8 : une responsabilité, un service.)
#
# Il s'abonne au signal `modifiee` de SanteMentale : il se met donc à
# jour TOUT SEUL à chaque variation (choix de dialogue, future prise de
# médicament, nouvelle partie...). Personne n'a à l'appeler.

extends Node


# --- Le bus et son filtre ---
const NOM_BUS: String = "Musique"
# Position du passe-bas dans la liste d'effets du bus (le 1er = 0).
const INDEX_EFFET: int = 0

# --- La plage de "flou" ---
# Coupure quand tout va bien : très haute = son intact.
const COUPURE_CLAIRE: float = 20000.0
# Coupure au plus bas : son très sourd, étouffé.
const COUPURE_SOURDE: float = 400.0
# AU-DESSUS de cette santé, le son reste totalement clair. EN DESSOUS,
# le voile s'installe progressivement jusqu'à 0. Calé sur la santé de
# DÉPART d'Al' (70) : son équilibre fragile est le bord de la clarté.
const SEUIL_CLAIR: float = 70.0
# Durée du glissement quand la santé change (évite un saut sec).
const DUREE_GLISSE: float = 0.4


# Le filtre passe-bas du bus Musique (récupéré une fois au démarrage).
var _passe_bas: AudioEffectLowPassFilter = null
# Le glissement en cours (pour ne pas en empiler plusieurs).
var _glisse: Tween = null


func _ready() -> void:
    _passe_bas = _trouver_passe_bas()
    if _passe_bas == null:
        push_warning("FiltreSonore : bus '%s' ou filtre passe-bas introuvable." % NOM_BUS)
        return

    # On se cale tout de suite sur la santé de départ, puis on suit
    # chaque changement.
    _appliquer(false)
    SanteMentale.modifiee.connect(_sur_sante_modifiee)
    print("FiltreSonore prêt.")


# Récupère le passe-bas posé sur le bus Musique. Renvoie null si le bus
# n'existe pas ou n'a pas d'effet à l'index attendu : le service se tait
# alors proprement, sans casser le jeu.
func _trouver_passe_bas() -> AudioEffectLowPassFilter:
    var idx: int = AudioServer.get_bus_index(NOM_BUS)
    if idx == -1:
        return null
    if AudioServer.get_bus_effect_count(idx) <= INDEX_EFFET:
        return null
    return AudioServer.get_bus_effect(idx, INDEX_EFFET) as AudioEffectLowPassFilter


# Réagit à toute variation de la santé mentale.
func _sur_sante_modifiee() -> void:
    _appliquer(true)


# Calcule la coupure visée selon la santé et la pose sur le filtre :
# d'un coup au démarrage, en douceur ensuite.
func _appliquer(avec_glisse: bool) -> void:
    if _passe_bas == null:
        return

    var cible: float = _coupure_pour(SanteMentale.valeur())

    if not avec_glisse:
        _passe_bas.cutoff_hz = cible
        return

    # Glissement doux : on annule un éventuel glissement en cours, puis
    # on fait glisser la coupure jusqu'à la cible.
    if _glisse != null and _glisse.is_valid():
        _glisse.kill()
    _glisse = create_tween()
    _glisse.tween_property(_passe_bas, "cutoff_hz", cible, DUREE_GLISSE)


# Le "calcul pur" : à quelle coupure correspond une santé donnée ?
# Au-dessus du seuil clair -> coupure claire (son intact). En dessous,
# on descend vers la coupure sourde. On interpole en échelle
# LOGARITHMIQUE (l'oreille perçoit les fréquences ainsi) pour que le
# voile s'épaississe régulièrement, et non d'un coup tout à la fin.
func _coupure_pour(sante: float) -> float:
    var t: float = clampf(sante / SEUIL_CLAIR, 0.0, 1.0)
    # t = 1 -> coupure claire ; t = 0 -> coupure sourde.
    return COUPURE_SOURDE * pow(COUPURE_CLAIRE / COUPURE_SOURDE, t)
