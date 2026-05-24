# fondu.gd
# Service autonome de transition à l'écran — autoload "Fondu".
#
# C'est un voile noir, posé au-dessus de TOUT (HUD et voix compris),
# qu'on rend opaque ou transparent en douceur :
#   - fondu_au_noir()     : l'écran s'éteint  (le voile devient opaque)
#   - fondu_depuis_noir() : l'écran se révèle (le voile redevient clair)
#
# N'importe qui peut l'appeler par une seule ligne :
#     await Fondu.fondu_au_noir()
#
# Le "await" est utile pour ENCHAÎNER une action une fois le fondu fini
# (ex. changer de pièce une fois l'écran noir).
#
# IMPORTANT : la Color du Voile est un noir OPAQUE. La transparence
# (donc le fondu) est pilotée uniquement par son "modulate:a".

extends CanvasLayer


# --- Référence au nœud ---
@onready var voile: ColorRect = $Voile


# --- Réglage ---
# Durée par défaut d'un fondu, en secondes.
const DUREE_FONDU: float = 0.7


# Appelée automatiquement une fois, au lancement.
func _ready() -> void:
    # Au lancement, le voile est invisible : le jeu démarre à l'écran clair.
    voile.modulate.a = 0.0
    

# --- FONDU AU NOIR ---
# L'écran s'éteint : le voile passe de transparent à opaque.
# Paramètre optionnel "duree" pour un fondu plus lent ou plus rapide.
func fondu_au_noir(duree: float = DUREE_FONDU) -> void:
    var tween := create_tween()
    tween.tween_property(voile, "modulate:a", 1.0, duree)
    await tween.finished


# --- FONDU DEPUIS LE NOIR ---
# L'écran se révèle : le voile passe d'opaque à transparent.
func fondu_depuis_noir(duree: float = DUREE_FONDU) -> void:
    var tween := create_tween()
    tween.tween_property(voile, "modulate:a", 0.0, duree)
    await tween.finished

    print("-> J'ai fait un Fade In <-")
