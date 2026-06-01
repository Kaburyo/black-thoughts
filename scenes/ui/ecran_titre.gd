extends Control

# ============================================================
#  ÉCRAN-TITRE — Menu principal (version sommaire)
#
#  Le point d'entrée du jeu. Deux choix pour l'instant :
#    - "Nouvelle partie" -> lance la cinématique d'intro.
#    - "Quitter"         -> ferme le jeu.
#
#  Volontairement minimal : d'autres entrées (Continuer, Options...)
#  viendront quand les systèmes correspondants existeront.
# ============================================================

# La cinématique d'intro, lancée par "Nouvelle partie".
const SCENE_INTRO: String = "res://scenes/ui/intro_cinematique.tscn"


func _ready() -> void:
    # Sur l'écran-titre, pas de HUD de jeu (portrait, inventaire...).
    # On le cache au cas où il aurait été affiché lors d'une partie.
    Hud.cacher()

    # Si on revient au titre après un fondu au noir (futur bouton
    # "Quitter" du menu pause), on s'assure que l'écran est révélé.
    Fondu.fondu_depuis_noir()

    $Boutons/BoutonNouvellePartie.pressed.connect(_sur_nouvelle_partie)
    $Boutons/BoutonQuitter.pressed.connect(_sur_quitter)


func _sur_nouvelle_partie() -> void:
    # Petit fondu au noir avant d'entrer dans la cinématique, pour une
    # transition propre (la cinématique démarre elle-même sur du noir).
    await Fondu.fondu_au_noir()
    get_tree().change_scene_to_file(SCENE_INTRO)


func _sur_quitter() -> void:
    get_tree().quit()
