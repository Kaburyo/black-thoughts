# voix_interieure.gd
# Service autonome de la "voix intérieure" d'Al' — autoload "Voix".
#
# C'est la boîte de texte qui s'écrit lettre par lettre, attend un
# temps de lecture, puis disparaît en fondu.
#
# AVANT : cette mécanique vivait dans le moule des pièces (room_base.gd).
# MAINTENANT : c'est un service indépendant, qui flotte au-dessus de
# tout et que n'importe qui peut appeler par une seule ligne :
#     Voix.afficher_pensee("Quelle journée de merde...")
#
# Un nouvel appel rend tout appel précédent "périmé" (système de jeton) :
# une pensée plus récente coupe proprement celle qui était en cours.

extends CanvasLayer


# --- Références aux nœuds ---
# La boîte (ColorRect) est le parent ; le label est son enfant.
# On allume / fait disparaître la BOÎTE : le texte, étant son enfant,
# suit automatiquement (il hérite de la transparence du parent).
@onready var boite: ColorRect = $TextBox
@onready var thought_label: Label = $TextBox/ThoughtLabel


# --- Réglages de l'animation du texte ---
const VITESSE_LETTRE: float = 0.03   # secondes entre deux lettres
const DUREE_LECTURE: float = 4.0     # secondes d'affichage une fois écrit
const DUREE_FONDU: float = 0.7       # secondes que dure la disparition


# --- Jeton de l'animation en cours ---
# Chaque nouvel affichage crée un jeton neuf ; une animation qui voit
# que le jeton a changé comprend qu'elle est périmée et s'arrête.
var _animation_active: int = 0


# Appelée automatiquement une fois, au lancement.
func _ready() -> void:
    # La boîte démarre cachée : on ne la voit qu'au moment d'une pensée.
    boite.visible = false
    
# --- AFFICHER UNE PENSÉE ---
# Écriture lettre par lettre, pause de lecture, puis fondu.
# Un nouvel appel rend tout appel précédent "périmé" : il s'arrête seul.
func afficher_pensee(texte: String) -> void:
    _animation_active += 1
    var mon_jeton: int = _animation_active

    # Préparation : texte posé, label vide à l'écran, boîte opaque et visible.
    thought_label.text = texte
    thought_label.visible_ratio = 0.0
    boite.modulate.a = 1.0
    boite.visible = true

    # Écriture lettre par lettre.
    var nb_lettres: int = texte.length()
    for i in range(nb_lettres):
        thought_label.visible_ratio = float(i + 1) / float(nb_lettres)
        await get_tree().create_timer(VITESSE_LETTRE).timeout
        if mon_jeton != _animation_active:
            return

    # Pause de lecture.
    await get_tree().create_timer(DUREE_LECTURE).timeout
    if mon_jeton != _animation_active:
        return

    # Fondu de disparition.
    var tween := create_tween()
    tween.tween_property(boite, "modulate:a", 0.0, DUREE_FONDU)
    await tween.finished
    if mon_jeton != _animation_active:
        return

    # Nettoyage final.
    boite.visible = false
    


# --- VARIANTE QUI ATTEND LA FIN ---
# Comme afficher_pensee, mais ATTEND la fin complète de l'animation.
# Utile pour enchaîner une action après le fondu (ex. ranger un objet).
func afficher_pensee_finie(texte: String) -> void:
    afficher_pensee(texte)
    var duree_ecriture: float = texte.length() * VITESSE_LETTRE
    await get_tree().create_timer(
        duree_ecriture + DUREE_LECTURE + DUREE_FONDU).timeout
