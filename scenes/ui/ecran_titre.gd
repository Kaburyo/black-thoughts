extends Control

# ============================================================
#  ÉCRAN-TITRE — Menu principal (version sommaire)
#
#  Trois choix : Nouvelle partie, Options (réglages à l'avance),
#  Quitter.
# ============================================================

const SCENE_INTRO: String = "res://scenes/ui/intro_cinematique.tscn"


func _ready() -> void:
    # La vitesse de jeu est désormais possédée et appliquée par Reglages
    # (au démarrage). L'écran-titre NE la fixe plus.

    # Curseur personnalisé (la flèche dessinée), point chaud sur la pointe.
    var fleche := load("res://assets/art/curseur/curseur_base_cursor.png")
    Input.set_custom_mouse_cursor(fleche, Input.CURSOR_ARROW, Vector2(1, 0))

    # Sur l'écran-titre, pas de HUD de jeu (portrait, inventaire...).
    Hud.cacher()

    # Si on revient au titre après un fondu au noir (bouton "Quitter" du
    # menu pause), on s'assure que l'écran est révélé.
    Fondu.fondu_depuis_noir()

    $Boutons/BoutonNouvellePartie.pressed.connect(_sur_nouvelle_partie)
    $Boutons/BoutonOptions.pressed.connect(_sur_options)
    $Boutons/BoutonQuitter.pressed.connect(_sur_quitter)


func _sur_nouvelle_partie() -> void:
    # Une NOUVELLE partie doit repartir d'un état PROPRE.
    _reinitialiser_partie()
    await Fondu.fondu_au_noir()
    get_tree().change_scene_to_file(SCENE_INTRO)


# Ouvre l'écran Options par-dessus le titre (réglages à l'avance).
func _sur_options() -> void:
    EcranOptions.ouvrir()


# Remet le jeu à son état de tout début.
func _reinitialiser_partie() -> void:
    SanteMentale.reinitialiser()
    Vie.reinitialiser()
    Inventaire.reinitialiser()
    Carte.reinitialiser()
    Progression.reinitialiser()
    ObjetEnMain.reposer()
    OfficeRoom.entretien_deja_joue = false
    OfficeRoom.bureau_verrouille = false


func _sur_quitter() -> void:
    get_tree().quit()
