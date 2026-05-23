# office_room.gd
# Pièce "Bureau d'Al'" — gère les interactions de type EXAMINER.
# Chaque objet cliquable affiche une pensée d'Al'.

extends Node2D


# --- Référence à la boîte de texte ---
@onready var thought_label: Label = $ThoughtLabel
# Jeton de l'animation en cours. Chaque nouvel affichage en crée un neuf ;
# une animation qui voit que le jeton a changé comprend qu'elle est périmée.
var _animation_active: int = 0

@onready var music_player: AudioStreamPlayer = $MusicPlayer

@onready var fade_overlay: ColorRect = $FadeOverlay

# Passe a true quand Al' a examine son manteau.
var _manteau_vu: bool = false

# --- Les objets examinables de la pièce ---
# Clé    = nom exact du nœud Area2D dans la scène.
# Valeur = pensée d'Al' affichée quand on clique cet objet.
# Pour ajouter un objet examinable : UNE SEULE ligne à ajouter ici.
const PENSEES: Dictionary = {
    "LampArea": "Cette lampe a vu plus de nuits blanches que moi.",
    "WindowArea": "Temps de merde, pour une ville de merde...",
    "JacketArea" : "Je devrais vraiment penser \n à me racheter un nouveau imper'.",
    "AlcoolArea" : "Ce n'est pas raisonnable durant une enquête...",
    "PaintingArea" : "Je me souviens même pas avoir acheter ce truc.",
    "CigaretteArea" : "Pas maintenent, mais on sait jamais pour plus tard.",
    "FilesArea" : "Encore tellement de PAPRASSES à règler.\n Si il y a bien quelque chose que je déteste,\n C'est ça !",
}
#Constante pour dévérouiller la porte
const PORTE_VERROUILLEE: String = "Je ferais mieux de prendre mon MANTEAU et mes CLES \n avant de partir."
const PORTE_OUVERTE: String = "Bon, il est temps d'y aller.\n Cette enquete n'avancera pas toute seule."

# Appelée automatiquement une fois, au lancement de la scène.
func _ready() -> void:
    # On parcourt chaque objet examinable déclaré dans PENSEES.
    for nom_zone in PENSEES:
        var zone := get_node(nom_zone) as Area2D
        var texte: String = PENSEES[nom_zone]
        # .bind(texte) attache le texte au branchement du signal.
        # Résultat : quand cette zone est cliquée, _sur_clic reçoit
        # directement la bonne pensée, sans avoir à la chercher.
        zone.input_event.connect(_sur_clic.bind(texte))

# Lancement de la musique d'ambiance de la pièce.
    music_player.play()
    
    # La porte a son propre branchement (objet a comportement).
    $DoorArea.input_event.connect(_sur_clic_porte)
    
# Appelée quand une zone examinable reçoit un événement souris.
# Les 3 premiers paramètres viennent du signal ; "texte" vient du .bind().
# Appelee quand une zone de PENSEES recoit un evenement souris.
func _sur_clic(_viewport: Node, event: InputEvent, _shape_idx: int, texte: String) -> void:
    if event is InputEventMouseButton:
        if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
            # Cas particulier : examiner le manteau remplit la condition.
            if texte == PENSEES["JacketArea"]:
                _manteau_vu = true
            afficher_pensee(texte)
            
            # --- Réglages de l'animation du texte ---
            # Regroupés ici en constantes : faciles à ajuster sans fouiller le code.
const VITESSE_LETTRE: float = 0.03   # secondes entre deux lettres
const DUREE_LECTURE: float = 4.0     # secondes d'affichage une fois écrit
const DUREE_FONDU: float = 0.7       # secondes que dure la disparition


# Affiche une pensée d'Al' : écriture lettre par lettre, pause, puis fondu.
# Affiche une pensée d'Al' : écriture lettre par lettre, pause, puis fondu.
# Un nouvel appel rend tout appel précédent "périmé" : il s'arrêtera de lui-même.
func afficher_pensee(texte: String) -> void:
    # On crée un jeton unique pour CETTE animation.
    _animation_active += 1
    var mon_jeton: int = _animation_active

    # Préparation : Label vide, visible et opaque.
    thought_label.text = texte
    thought_label.visible_ratio = 0.0
    thought_label.modulate.a = 1.0
    thought_label.visible = true

    # Écriture lettre par lettre.
    var nb_lettres: int = texte.length()
    for i in range(nb_lettres):
        thought_label.visible_ratio = float(i + 1) / float(nb_lettres)
        await get_tree().create_timer(VITESSE_LETTRE).timeout
        # Après chaque attente : un clic plus récent a-t-il pris la main ?
        if mon_jeton != _animation_active:
            return  # Oui -> cette animation est périmée, on l'abandonne.

    # Pause de lecture.
    await get_tree().create_timer(DUREE_LECTURE).timeout
    if mon_jeton != _animation_active:
        return

    # Fondu de disparition.
    var tween := create_tween()
    tween.tween_property(thought_label, "modulate:a", 0.0, DUREE_FONDU)
    await tween.finished
    if mon_jeton != _animation_active:
        return

    # Nettoyage final.
    thought_label.visible = false

# Appelee quand on clique la porte.
func _sur_clic_porte(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
    if event is InputEventMouseButton:
        if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
            if _manteau_vu:
                afficher_pensee(PORTE_OUVERTE)
                _quitter_la_piece()
            else:
                afficher_pensee(PORTE_VERROUILLEE)

# Fondu au noir + fondu de la musique, en parallele, puis changement de piece.
func _quitter_la_piece() -> void:
    # On attend un peu : le temps qu'Al' "dise" sa phrase de depart.
    await get_tree().create_timer(DUREE_LECTURE).timeout

    # Un seul Tween, regle en parallele : ses deux animations
    # se jouent EN MEME TEMPS au lieu de l'une apres l'autre.
    var tween := create_tween()
    tween.set_parallel(true)

    # Animation 1 : l'overlay noir passe de transparent a opaque.
    tween.tween_property(fade_overlay, "modulate:a", 1.0, DUREE_FONDU)
    # Animation 2 : le volume de la musique descend jusqu'au silence.
    tween.tween_property(music_player, "volume_db", -60.0, DUREE_FONDU)

    # On attend que les DEUX animations soient terminees.
    await tween.finished

    # La musique est inaudible : on l'arrete vraiment.
    music_player.stop()

    # Point de rendez-vous : ici viendra le vrai changement de Room.
    print("-> Changement de Room (a venir)")
