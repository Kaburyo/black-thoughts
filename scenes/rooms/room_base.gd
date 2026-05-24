# room_base.gd
# LE MOULE des pièces point-and-click.
# Contient toute la mécanique COMMUNE à chaque pièce :
#   - EXAMINER (un clic = une pensée)
#   - RAMASSER (un clic = pensée + sprite + rangement en inventaire)
#   - le verrou des interactions
#   - la sortie de pièce (fondu au noir + fondu musique)
#
# La voix intérieure d'Al' (la boîte de texte) NE vit plus ici :
# c'est le service autonome "Voix" (autoload).
# Le fondu au noir de l'écran NON plus : c'est le service "Fondu".
# Les pièces les appellent simplement par Voix.afficher_pensee("...")
# et Fondu.fondu_au_noir().
#
# Une pièce concrète (office_room.gd, plus tard luna_room.gd...) fait
# "extends RoomBase" et hérite GRATUITEMENT de tout ça.
# Elle n'a plus qu'à remplir _definir_contenu() avec SES propres données.

class_name RoomBase
extends Node2D


# --- Références aux nœuds ---
# Ces nœuds doivent exister, avec ces noms exacts, dans CHAQUE pièce.
@onready var music_player: AudioStreamPlayer = $MusicPlayer
@onready var pickup_sprite: Sprite2D = $PickupSprite


# --- Réglages ---
# Durée d'affichage d'une pensée (sert ici à attendre avant de quitter
# la pièce). Doit rester cohérent avec le DUREE_LECTURE du service Voix.
const DUREE_LECTURE: float = 4.0

# Durée du fondu de la musique en sortie de pièce.
const DUREE_FONDU: float = 0.7

# Échelle d'affichage du sprite d'objet ramassé (image 1024px -> ~300px).
const ECHELLE_PICKUP: float = 0.3


# --- Verrou des interactions ---
# Quand true, tous les clics sont ignorés (utilisé pendant une
# transition comme la sortie de pièce).
var _interactions_bloquees: bool = false


# --- Les données de la pièce ---
# Vides ici : c'est la PIÈCE concrète qui les remplit dans _definir_contenu().
#   pensees            : { "NomZone": "pensée à afficher", ... }
#   objets_ramassables : { "NomZone": { "pensee":..., "id":..., "sprite":... }, ... }
var pensees: Dictionary = {}
var objets_ramassables: Dictionary = {}


# --- Point d'accroche à remplir par chaque pièce ---
# Le moule appelle cette fonction au tout début de _ready().
# Chaque pièce la redéfinit pour : remplir pensees, remplir
# objets_ramassables, et brancher ses objets à comportement (ex. la porte).
# Ici, dans le moule, elle est volontairement vide.
func _definir_contenu() -> void:
    pass


# Appelée automatiquement une fois, au lancement de la scène.
func _ready() -> void:
    # 1. La pièce déclare son contenu (pensées, objets, porte...).
    _definir_contenu()

    # 2. Branchement des objets examinables.
    for nom_zone in pensees:
        var zone := get_node(nom_zone) as Area2D
        var texte: String = pensees[nom_zone]
        zone.input_event.connect(_sur_clic.bind(texte))

    # 3. Branchement des objets ramassables.
    for nom_zone in objets_ramassables:
        var zone := get_node(nom_zone) as Area2D
        var donnees: Dictionary = objets_ramassables[nom_zone]
        zone.input_event.connect(_sur_clic_ramassable.bind(nom_zone, donnees))

    # 4. Lancement de la musique d'ambiance.
    music_player.play()



# --- EXAMINER ---
# Appelée quand une zone de "pensees" reçoit un événement souris.
func _sur_clic(_viewport: Node, event: InputEvent, _shape_idx: int, texte: String) -> void:
    if _interactions_bloquees:
        return
    if event is InputEventMouseButton:
        if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
            Voix.afficher_pensee(texte)


# --- RAMASSER ---
# Appelée quand on clique un objet ramassable.
func _sur_clic_ramassable(_viewport: Node, event: InputEvent, _shape_idx: int,
        nom_zone: String, donnees: Dictionary) -> void:
    if _interactions_bloquees:
        return
    if not (event is InputEventMouseButton):
        return
    if not (event.button_index == MOUSE_BUTTON_LEFT and event.pressed):
        return

    # Déjà ramassé ? On ne fait rien.
    if Inventaire.possede(donnees["id"]):
        return

    ramasser(nom_zone, donnees)


# Séquence de ramassage : pensée + sprite affiché, puis rangement.
func ramasser(nom_zone: String, donnees: Dictionary) -> void:
    # 1. On affiche le sprite de l'objet au centre.
    pickup_sprite.texture = load(donnees["sprite"])
    pickup_sprite.scale = Vector2(ECHELLE_PICKUP, ECHELLE_PICKUP)
    pickup_sprite.visible = true

    # 2. On affiche la pensée et on attend la fin complète de l'animation.
    await Voix.afficher_pensee_finie(donnees["pensee"])

    # 3. Le texte est fini : on range l'objet et on cache le sprite.
    pickup_sprite.visible = false
    Inventaire.ajouter(donnees["id"])

    # 4. La zone a fait son travail : on la désactive pour de bon.
    var zone := get_node(nom_zone) as Area2D
    zone.input_pickable = false


# --- SORTIE DE PIÈCE ---
# Fondu au noir (service Fondu) + fondu de la musique, en parallèle,
# puis changement de pièce.
func _quitter_la_piece() -> void:
    # On verrouille les interactions : plus aucun clic ne sera pris en compte.
    _interactions_bloquees = true

    # On attend : le temps qu'Al' "dise" sa phrase de départ.
    await get_tree().create_timer(DUREE_LECTURE).timeout

    # Fondu de la musique : on le lance SANS l'attendre, pour qu'il
    # joue EN MÊME TEMPS que le fondu de l'écran juste après.
    var tween_musique := create_tween()
    tween_musique.tween_property(music_player, "volume_db", -60.0, DUREE_FONDU + 5)

    # Fondu de l'écran au noir : géré par le service global Fondu.
    # On l'attend : à la fin, l'écran est entièrement noir.
    await Fondu.fondu_au_noir()

    # La musique est inaudible : on l'arrête vraiment.
    music_player.stop()

    # Point de rendez-vous : ici viendra le vrai changement de Room.
    print("-> Changement de Room (a venir)")
