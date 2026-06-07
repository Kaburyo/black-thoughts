# room_base.gd
# LE MOULE des pièces point-and-click (mécanique commune à chaque pièce).
# Voir l'historique : examiner / ramasser / utiliser / montrer / quitter
# (qui ouvre la CARTE) + gel pendant un dialogue. Nouveau : un HALO de
# survol s'affiche sur la zone interactive sous la souris (retour visuel).

class_name RoomBase
extends Node2D


# --- Références aux nœuds ---
@onready var music_player: AudioStreamPlayer = $MusicPlayer
@onready var pickup_sprite: Sprite2D = $PickupSprite


# --- Réglages ---
const DUREE_LECTURE: float = 4.0
const ECHELLE_PICKUP: float = 0.3

const PENSEE_OBJET_INUTILE: String = "Inutile ici."
const PENSEE_RIEN_A_MONTRER: String = "Inutile de lui montrer ça."

# --- Halo de survol ---
const CHEMIN_GLOW: String = "res://assets/art/ui/glow.png"
const GLOW_TAILLE: float = 150.0                       # diamètre du halo à l'écran (px)
const GLOW_COULEUR: Color = Color(1.0, 0.96, 0.85, 0.65)  # blanc chaud, semi-transparent


# --- Verrou des interactions ---
var _interactions_bloquees: bool = false

# Le sprite réutilisable du halo de survol (créé en code, déplacé/redimensionné
# sur la zone survolée).
var _glow: Sprite2D


# --- Les données de la pièce ---
var pensees: Dictionary = {}
var objets_ramassables: Dictionary = {}
var utilisables: Dictionary = {}
var pnj_presents: Dictionary = {}

# Champ hérité, désormais inerte : la carte gère la destination.
var scene_suivante: String = ""


# --- Point d'accroche à remplir par chaque pièce ---
func _definir_contenu() -> void:
    pass


func _ready() -> void:
    # 0. À l'arrivée, on révèle la pièce en fondu (l'écran peut être noir).
    Fondu.fondu_depuis_noir()

    # 1. La pièce déclare son contenu.
    _definir_contenu()

    # 1-bis. Le halo de survol (caché tant qu'on ne survole rien).
    _creer_glow()

    # 2. Objets examinables (+ survol).
    for nom_zone in pensees:
        var zone := get_node(nom_zone) as Area2D
        var texte: String = pensees[nom_zone]
        zone.input_event.connect(_sur_clic.bind(texte))
        zone.mouse_entered.connect(_survol_zone.bind(nom_zone))
        zone.mouse_exited.connect(_fin_survol_zone)

    # 3. Objets ramassables (+ survol).
    for nom_zone in objets_ramassables:
        var zone := get_node(nom_zone) as Area2D
        var donnees: Dictionary = objets_ramassables[nom_zone]
        zone.input_event.connect(_sur_clic_ramassable.bind(nom_zone, donnees))
        zone.mouse_entered.connect(_survol_zone.bind(nom_zone))
        zone.mouse_exited.connect(_fin_survol_zone)

    # 3-bis. Zones utilisables (+ survol).
    for nom_zone in utilisables:
        var zone := get_node(nom_zone) as Area2D
        var donnees: Dictionary = utilisables[nom_zone]
        zone.input_event.connect(_sur_clic_utilisable.bind(donnees))
        zone.mouse_entered.connect(_survol_zone.bind(nom_zone))
        zone.mouse_exited.connect(_fin_survol_zone)

    # 3-ter. PNJ (+ survol).
    for nom_zone in pnj_presents:
        var zone := get_node(nom_zone) as Area2D
        var donnees: Dictionary = pnj_presents[nom_zone]
        zone.input_event.connect(_sur_clic_pnj.bind(donnees))
        zone.mouse_entered.connect(_survol_zone.bind(nom_zone))
        zone.mouse_exited.connect(_fin_survol_zone)

    # 4. Gel du décor pendant un dialogue.
    Dialogue.conversation_demarree.connect(_sur_dialogue_demarre)
    Dialogue.conversation_terminee.connect(_sur_dialogue_termine)

    # 5. Musique d'ambiance.
    music_player.play()


# --- HALO DE SURVOL ---
func _creer_glow() -> void:
    _glow = Sprite2D.new()
    if ResourceLoader.exists(CHEMIN_GLOW):
        _glow.texture = load(CHEMIN_GLOW)
        # Taille FIXE : le halo suit le curseur, il ne dépend plus de la zone.
        _glow.scale = Vector2.ONE * (GLOW_TAILLE / _glow.texture.get_size().x)
    _glow.modulate = GLOW_COULEUR
    _glow.z_index = 1          # au-dessus du décor de fond
    _glow.visible = false
    add_child(_glow)


# Le halo suit le CURSEUR : il s'allume quand la souris entre sur une zone
# interactive, suit la souris tant qu'on y reste, et s'éteint quand on en
# sort. Le nom de zone n'est plus utilisé (le halo ne se cale plus dessus),
# mais on garde le paramètre pour ne pas toucher aux branchements de _ready.
func _survol_zone(_nom_zone: String) -> void:
    if _interactions_bloquees:
        return
    if _glow.texture == null:
        return
    _glow.global_position = get_global_mouse_position()
    _glow.visible = true


func _fin_survol_zone() -> void:
    if _glow != null:
        _glow.visible = false


# Tant que le halo est allumé, il colle à la souris.
func _process(_delta: float) -> void:
    if _glow != null and _glow.visible:
        _glow.global_position = get_global_mouse_position()


# --- GEL DU DÉCOR PENDANT UN DIALOGUE ---
func _sur_dialogue_demarre() -> void:
    _interactions_bloquees = true
    if _glow != null:
        _glow.visible = false


func _sur_dialogue_termine() -> void:
    _interactions_bloquees = false


# --- EXAMINER ---
func _sur_clic(_viewport: Node, event: InputEvent, _shape_idx: int, texte: String) -> void:
    if _interactions_bloquees:
        return
    if not (event is InputEventMouseButton):
        return
    if not (event.button_index == MOUSE_BUTTON_LEFT and event.pressed):
        return

    if ObjetEnMain.a_un_objet():
        Voix.afficher_pensee(PENSEE_OBJET_INUTILE)
        return

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

    if ObjetEnMain.a_un_objet():
        Voix.afficher_pensee(PENSEE_OBJET_INUTILE)
        return

    if Inventaire.possede(donnees["id"]):
        return

    ramasser(nom_zone, donnees)


func ramasser(nom_zone: String, donnees: Dictionary) -> void:
    pickup_sprite.texture = load(donnees["sprite"])
    pickup_sprite.scale = Vector2(ECHELLE_PICKUP, ECHELLE_PICKUP)
    pickup_sprite.visible = true

    await Voix.afficher_pensee_finie(donnees["pensee"])

    pickup_sprite.visible = false
    Inventaire.ajouter(donnees["id"])

    var zone := get_node(nom_zone) as Area2D
    zone.input_pickable = false
    # L'objet a été ramassé : on s'assure que le halo ne reste pas affiché.
    _fin_survol_zone()


# --- UTILISER un objet sur une zone du décor ---
func _sur_clic_utilisable(_viewport: Node, event: InputEvent, _shape_idx: int,
        donnees: Dictionary) -> void:
    if _interactions_bloquees:
        return
    if not (event is InputEventMouseButton):
        return
    if not (event.button_index == MOUSE_BUTTON_LEFT and event.pressed):
        return

    if not ObjetEnMain.a_un_objet():
        var texte: Variant = donnees.get("examiner", "")
        if texte is Callable:
            texte = texte.call()
        if texte != "":
            Voix.afficher_pensee(texte)
        return

    var id_objet: String = ObjetEnMain.id()
    var objets_acceptes: Dictionary = donnees.get("objets", {})

    if not objets_acceptes.has(id_objet):
        Voix.afficher_pensee(PENSEE_OBJET_INUTILE)
        return

    var effet: Dictionary = objets_acceptes[id_objet]

    if effet.get("pensee", "") != "":
        Voix.afficher_pensee(effet["pensee"])

    var action: Variant = effet.get("action", null)
    if action is Callable:
        action.call()

    ObjetEnMain.reposer()


# --- MONTRER un objet à un PNJ, ou lui PARLER ---
func _sur_clic_pnj(_viewport: Node, event: InputEvent, _shape_idx: int,
        donnees: Dictionary) -> void:
    if _interactions_bloquees:
        return
    if not (event is InputEventMouseButton):
        return
    if not (event.button_index == MOUSE_BUTTON_LEFT and event.pressed):
        return

    if not ObjetEnMain.a_un_objet():
        # PARLER : le champ "parler" peut être un simple chemin OU une
        # liste de règles selon les faits déjà survenus (voir
        # _resoudre_parler). On résout d'abord, puis on joue.
        _jouer_conversation(_resoudre_parler(donnees.get("parler", "")))
        return

    var id_objet: String = ObjetEnMain.id()
    var conversations: Dictionary = donnees.get("objets", {})

    if not conversations.has(id_objet):
        Voix.afficher_pensee(PENSEE_RIEN_A_MONTRER)
        return

    _jouer_conversation(conversations[id_objet])


# --- CHOISIR LA BONNE CONVERSATION "PARLER" SELON LES FAITS ---
# Le champ "parler" d'un PNJ peut prendre DEUX formes :
#   - un simple CHEMIN (String) -> on le joue tel quel. C'est le cas par
#     défaut, RÉTRO-COMPATIBLE : les PNJ déjà câblés ainsi ne changent pas.
#   - une LISTE DE RÈGLES (Array) -> on parcourt les règles dans l'ordre
#     et on retient la PREMIÈRE qui s'applique. C'est ce qui rend les
#     RETOURS-CLÉS possibles : selon ce qui s'est déjà passé, le PNJ
#     n'ouvre pas la même conversation.
#
# Une règle est un petit dictionnaire :
#   { "si_vu": "fait_id", "conversation": "res://..." }
#     -> s'applique seulement si ce fait est déjà connu (Progression) ;
#   { "conversation": "res://..." }   (pas de "si_vu")
#     -> s'applique TOUJOURS : c'est la règle PAR DÉFAUT. On la place
#        EN DERNIER, comme un filet : si aucune règle plus spécifique
#        au-dessus n'a mordu, c'est elle qui tombe.
func _resoudre_parler(valeur: Variant) -> String:
    # Forme simple : un chemin direct.
    if valeur is String:
        return valeur

    # Forme à règles : on prend la première qui s'applique.
    if valeur is Array:
        for regle in valeur:
            if not (regle is Dictionary):
                continue
            var fait: String = regle.get("si_vu", "")
            # Règle sans condition (le défaut), OU condition satisfaite.
            if fait == "" or Progression.a_vu(fait):
                return regle.get("conversation", "")

    # Forme inattendue ou aucune règle applicable : rien à jouer.
    return ""


func _jouer_conversation(chemin: String) -> void:
    if chemin == "":
        return
    var conversation := load(chemin) as Conversation
    if conversation != null:
        Dialogue.jouer(conversation)


# --- QUITTER UNE PIÈCE -> OUVRIR LA CARTE ---
func demander_a_quitter(pensee_sortie: String = "") -> void:
    _ouvrir_la_carte(pensee_sortie)


func _ouvrir_la_carte(pensee_sortie: String) -> void:
    _interactions_bloquees = true
    if _glow != null:
        _glow.visible = false
    if pensee_sortie != "":
        await Voix.afficher_pensee_finie(pensee_sortie)
    _interactions_bloquees = false
    EcranCarte.ouvrir()
