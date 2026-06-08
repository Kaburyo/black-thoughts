# filtre_sonore.gd
# LE VOILE SONORE — le pendant AUDIO du filtre mental. AUTOLOAD (global).
#
# Quand la santé mentale d'Al' baisse, le son du monde s'enfonce SOUS
# L'EAU : il s'ÉTOUFFE (passe-bas, on coupe les aigus) ET se noie dans une
# RÉVERBÉRATION lointaine. Deux effets complémentaires, sur DEUX bus :
# Musique ET SFX (la machine à écrire comprise).
#
# Sur chaque bus, on attend DEUX effets, dans cet ordre :
#   index 0 = Low Pass Filter  (l'étouffement)
#   index 1 = Reverb           (la noyade, le lointain)
# Ce service règle leurs paramètres selon la santé, et rien d'autre
# (règle A.5/A.8). Il se met à jour tout seul via le signal de SanteMentale.

extends Node


# --- Les bus traités et la place de chaque effet ---
const NOMS_BUS: Array[String] = ["Musique", "SFX"]
const INDEX_PASSE_BAS: int = 0
const INDEX_REVERB: int = 1

# --- Étouffement (passe-bas) ---
const COUPURE_CLAIRE: float = 20000.0   # son intact
const COUPURE_SOURDE: float = 10000.0     # très mat, lointain

# --- Noyade (reverb) : proportion de son "mouillé" ---
const REVERB_CLAIR: float = 0.0         # aucune réverbération
const REVERB_SOURD: float = 0.45        # très noyé
const REVERB_TAILLE: float = 0.85       # ampleur de la "pièce" (fixe)

# Au-dessus de cette santé, le son reste clair ; en dessous, le voile
# s'installe. Calé sur la santé de départ d'Al' (70).
const SEUIL_CLAIR: float = 75.0
# Durée du glissement quand la santé change (évite un saut sec).
const DUREE_GLISSE: float = 0.7


# Effets récupérés une fois, regroupés par type.
var _passe_bas: Array[AudioEffectLowPassFilter] = []
var _reverbs: Array[AudioEffectReverb] = []
var _glisse: Tween = null


func _ready() -> void:
    _recuperer_effets()

    # Taille de la réverbération : réglée une fois, fixe.
    for rev in _reverbs:
        rev.room_size = REVERB_TAILLE

    # On se cale sur la santé de départ, puis on suit chaque changement.
    _appliquer(false)
    SanteMentale.modifiee.connect(_sur_sante_modifiee)
    print("FiltreSonore prêt.")


# Récupère, pour chaque bus, son passe-bas (index 0) et sa reverb (index 1).
# Un bus mal configuré est ignoré proprement (le service ne casse rien).
func _recuperer_effets() -> void:
    for nom in NOMS_BUS:
        var idx: int = AudioServer.get_bus_index(nom)
        if idx == -1:
            push_warning("FiltreSonore : bus '%s' introuvable." % nom)
            continue
        var pb := AudioServer.get_bus_effect(idx, INDEX_PASSE_BAS) as AudioEffectLowPassFilter
        var rev := AudioServer.get_bus_effect(idx, INDEX_REVERB) as AudioEffectReverb
        if pb == null or rev == null:
            push_warning("FiltreSonore : effets manquants sur '%s' " % nom
                    + "(attendu : Low Pass en 0, Reverb en 1).")
            continue
        _passe_bas.append(pb)
        _reverbs.append(rev)


func _sur_sante_modifiee() -> void:
    _appliquer(true)


# Calcule les cibles selon la santé et les pose sur tous les effets :
# d'un coup au démarrage, en douceur ensuite.
func _appliquer(avec_glisse: bool) -> void:
    if _passe_bas.is_empty():
        return

    var t: float = clampf(SanteMentale.valeur() / SEUIL_CLAIR, 0.0, 1.0)
    # Coupure en échelle LOG (l'oreille perçoit ainsi) ; reverb en linéaire.
    var coupure: float = COUPURE_SOURDE * pow(COUPURE_CLAIRE / COUPURE_SOURDE, t)
    var reverb_wet: float = lerpf(REVERB_SOURD, REVERB_CLAIR, t)

    if not avec_glisse:
        for pb in _passe_bas:
            pb.cutoff_hz = coupure
        for rev in _reverbs:
            rev.wet = reverb_wet
        return

    # Glissement doux et SIMULTANÉ de tous les paramètres.
    if _glisse != null and _glisse.is_valid():
        _glisse.kill()
    _glisse = create_tween()
    _glisse.set_parallel(true)
    for pb in _passe_bas:
        _glisse.tween_property(pb, "cutoff_hz", coupure, DUREE_GLISSE)
    for rev in _reverbs:
        _glisse.tween_property(rev, "wet", reverb_wet, DUREE_GLISSE)
