# room_base.gd
# LE MOULE des pièces point-and-click.
# Contient toute la mécanique COMMUNE à chaque pièce :
#   - EXAMINER (un clic = une pensée)
#   - RAMASSER (un clic = pensée + sprite + rangement en inventaire)
#   - le verrou des interactions
#   - le gel du décor pendant un dialogue
#   - la sortie de pièce (fondu au noir + fondu musique)
#
# La voix intérieure d'Al' (la boîte de texte) NE vit plus ici :
# c'est le service autonome "Voix" (autoload).
# Le fondu au noir de l'écran NON plus : c'est le service "Fondu".
#
# Une pièce concrète (office_room.gd, chambre_luna_room.gd...) fait
# "extends RoomBase" et hérite GRATUITEMENT de tout ça.
# Elle n'a plus qu'à remplir _definir_contenu() avec SES propres données.

class_name RoomBase
extends Node2D


# --- Références aux nœuds ---
@onready var music_player: AudioStreamPlayer = $MusicPlayer
@onready var pickup_sprite: Sprite2D = $PickupSprite


# --- Réglages ---
const DUREE_LECTURE: float = 4.0
const DUREE_FONDU: float = 0.7
const ECHELLE_PICKUP: float = 0.3


# --- Verrou des interactions ---
# Quand true, tous les clics du décor sont ignorés. Posé pendant une
# transition (sortie de pièce) ET pendant un dialogue.
var _interactions_bloquees: bool = false


# --- Les données de la pièce ---
var pensees: Dictionary = {}
var objets_ramassables: Dictionary = {}


# --- Point d'accroche à remplir par chaque pièce ---
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

    # 4. On s'abonne au service Dialogue : pendant une conversation,
    #    le décor se gèle ; à la fin, il se dégèle. La pièce n'a rien
    #    à savoir du dialogue lui-même : elle réagit juste aux signaux.
    Dialogue.conversation_demarree.connect(_sur_dialogue_demarre)
    Dialogue.conversation_terminee.connect(_sur_dialogue_termine)

    # 5. Lancement de la musique d'ambiance.
    music_player.play()


# --- GEL DU DÉCOR PENDANT UN DIALOGUE ---
# Appelées par les signaux du service Dialogue.
func _sur_dialogue_demarre() -> void:
    _interactions_bloquees = true


func _sur_dialogue_termine() -> void:
    _interactions_bloquees = false


# --- EXAMINER ---
func _sur_clic(_viewport: Node, event: InputEvent, _shape_idx: int, texte: String) -> void:
    if _interactions_bloquees:
        return
    if event is InputEventMouseButton:
        if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
            Voix.afficher_pensee(texte)


# --- RAMASSER ---
func _sur_clic_ramassable(_viewport: Node, event: InputEvent, _shape_idx: int,
        nom_zone: String, donnees: Dictionary) -> void:
    if _interactions_bloquees:
        return
    if not (event is InputEventMouseButton):
        return
    if not (event.button_index == MOUSE_BUTTON_LEFT and event.pressed):
        return

    if Inventaire.possede(donnees["id"]):
        return

    ramasser(nom_zone, donnees)


# Séquence de ramassage : pensée + sprite affiché, puis rangement.
func ramasser(nom_zone: String, donnees: Dictionary) -> void:
    pickup_sprite.texture = load(donnees["sprite"])
    pickup_sprite.scale = Vector2(ECHELLE_PICKUP, ECHELLE_PICKUP)
    pickup_sprite.visible = true

    await Voix.afficher_pensee_finie(donnees["pensee"])

    pickup_sprite.visible = false
    Inventaire.ajouter(donnees["id"])

    var zone := get_node(nom_zone) as Area2D
    zone.input_pickable = false


# --- SORTIE DE PIÈCE ---
func _quitter_la_piece() -> void:
    _interactions_bloquees = true

    await get_tree().create_timer(DUREE_LECTURE).timeout

    var tween_musique := create_tween()
    tween_musique.tween_property(music_player, "volume_db", -60.0, DUREE_FONDU + 5)

    await Fondu.fondu_au_noir()

    music_player.stop()

    print("-> Changement de Room (a venir)")
