# filtre_mental.gd
# Service autonome du FILTRE MENTAL d'Al' — autoload "FiltreMental".
#
# C'est un voile posé au-dessus du jeu (décor, HUD, voix), qui
# assombrit l'écran en vignettage arrondi : plus la SANTÉ MENTALE
# d'Al' baisse, plus les bords s'assombrissent — comme s'il fermait
# peu à peu les yeux. Voir la "bible", points L.1 et L.3.
#
# RÉPARTITION DES RÔLES :
#   - le SHADER (filtre_mental.gdshader) dessine le vignettage et
#     possède tous les réglages d'aspect (rayons, noirceur, minimum).
#   - CE SCRIPT ne fait qu'une chose : lire la santé mentale et en
#     déduire le réglage `intensite` du shader. Il ne touche à aucun
#     autre réglage d'aspect — ceux-là se règlent dans l'éditeur.
#
# Le filtre vit sur une couche intermédiaire (Layer 15) : au-dessus
# du HUD et de la voix, mais SOUS le Fondu (Layer 20) — le noir de
# transition doit toujours pouvoir tout recouvrir.

extends CanvasLayer


# --- Référence au nœud ---
@onready var voile: ColorRect = $Voile


# --- Réglages ---
# Durée du glissement quand l'intensité change : le filtre "respire"
# vers sa nouvelle valeur au lieu de sauter d'un coup.
const DUREE_TRANSITION: float = 0.6


# Le matériau shader du voile, récupéré une fois pour toutes.
# C'est par lui qu'on règle le paramètre `intensite` du shader.
var _materiau: ShaderMaterial


# Appelée automatiquement une fois, au lancement.
func _ready() -> void:
    _materiau = voile.material as ShaderMaterial

    # On se tient au courant des changements de la santé mentale :
    # à chaque modification, le filtre s'ajuste tout seul.
    SanteMentale.modifiee.connect(_sur_sante_modifiee)

    # Premier réglage. On attend une frame pour être sûr que l'autoload
    # SanteMentale a fini son _ready() (et posé sa valeur de départ).
    # Ici on applique l'intensité DIRECTEMENT, sans glissement : au
    # lancement, le filtre doit déjà être à son état correct.
    await get_tree().process_frame
    _appliquer_intensite(_intensite_voulue(), false)


# --- Réaction à un changement de santé mentale ---
# Appelée à chaque émission du signal `SanteMentale.modifiee`.
func _sur_sante_modifiee() -> void:
    # En cours de jeu, on fait GLISSER l'intensité en douceur.
    _appliquer_intensite(_intensite_voulue(), true)


# --- Calcul de l'intensité voulue ---
# Traduit la santé mentale (0-100) en intensité de filtre (0.0-1.0).
# Les deux vont en SENS CONTRAIRE : santé haute -> filtre faible.
#   santé 100 -> intensite 0.0   (écran clair)
#   santé 0   -> intensite 1.0   (assombrissement maximal)
func _intensite_voulue() -> float:
    return 1.0 - (SanteMentale.valeur() / 100.0)


# --- Application de l'intensité au shader ---
# `en_douceur` = true : on glisse vers la valeur (Tween).
# `en_douceur` = false : on l'applique d'un coup (au lancement).
func _appliquer_intensite(cible: float, en_douceur: bool) -> void:
    if en_douceur:
        var tween := create_tween()
        tween.tween_method(_poser_intensite, _intensite_actuelle(), cible,
                DUREE_TRANSITION)
    else:
        _poser_intensite(cible)


# Écrit une valeur d'intensité dans le shader. Le Tween appelle cette
# fonction plein de fois d'affilée pour créer le glissement progressif.
func _poser_intensite(valeur: float) -> void:
    _materiau.set_shader_parameter("intensite", valeur)


# Relit l'intensité actuellement posée dans le shader (point de départ
# du glissement).
func _intensite_actuelle() -> float:
    return _materiau.get_shader_parameter("intensite")
