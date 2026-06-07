extends Control

# ============================================================
#  ÉCRAN-TITRE — Menu principal (version sommaire)
#
#  Le point d'entrée du jeu. Deux choix pour l'instant :
#    - "Nouvelle partie" -> remet le jeu à zéro, puis lance la
#                           cinématique d'intro.
#    - "Quitter"         -> ferme le jeu.
# ============================================================

const SCENE_INTRO: String = "res://scenes/ui/intro_cinematique.tscn"


func _ready() -> void:
    
    # Rythme de base du jeu. 1.0 = normal, 2.0 = deux fois plus rapide.
    # Un seul réglage global : texte, fondus, minuteries, tweens... tout suit.
    Engine.time_scale = 1.8
    
    # Curseur personnalisé (la flèche dessinée), point chaud sur la pointe.
    # set_custom_mouse_cursor est GLOBAL : posé ici au lancement, il vaut
    # pour tout le jeu. (Quand un objet est en main, le HUD masque la souris
    # au profit du faux curseur-objet : les deux systèmes cohabitent.)
    var fleche := load("res://assets/art/curseur/curseur_base_cursor.png")
    Input.set_custom_mouse_cursor(fleche, Input.CURSOR_ARROW, Vector2(1, 0))
        
    # Sur l'écran-titre, pas de HUD de jeu (portrait, inventaire...).
    Hud.cacher()

    # Si on revient au titre après un fondu au noir (bouton "Quitter" du
    # menu pause), on s'assure que l'écran est révélé.
    Fondu.fondu_depuis_noir()

    $Boutons/BoutonNouvellePartie.pressed.connect(_sur_nouvelle_partie)
    $Boutons/BoutonQuitter.pressed.connect(_sur_quitter)


func _sur_nouvelle_partie() -> void:
    # Une NOUVELLE partie doit repartir d'un état PROPRE. On remet à zéro
    # tout ce qui a pu changer pendant un run précédent : sinon, sans
    # fermer le jeu, on garderait objets, zones débloquées et santé
    # mentale — et surtout l'entretien d'ouverture ne se rejouerait pas,
    # laissant le HUD caché (c'était la cause du blocage dans le bureau).
    _reinitialiser_partie()

    # Petit fondu au noir avant d'entrer dans la cinématique.
    await Fondu.fondu_au_noir()
    get_tree().change_scene_to_file(SCENE_INTRO)


# Remet le jeu à son état de tout début. (Plus tard, avec une vraie
# sauvegarde — L.6 —, cette logique pourra déménager dans un service
# dédié ; pour l'instant, l'écran-titre orchestre, c'est très bien.)
func _reinitialiser_partie() -> void:
    SanteMentale.reinitialiser()
    Vie.reinitialiser()
    Inventaire.reinitialiser()
    Carte.reinitialiser()
    Progression.reinitialiser()
    ObjetEnMain.reposer()
    OfficeRoom.entretien_deja_joue = false


func _sur_quitter() -> void:
    get_tree().quit()
