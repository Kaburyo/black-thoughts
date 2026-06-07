# office_room.gd — Pièce "Bureau d'Al'".
class_name OfficeRoom
extends RoomBase


static var entretien_deja_joue: bool = false


const PORTE_SANS_CLES: String = "Je ferais mieux de prendre mon manteau et\n mes clés du bureau avant de partir."
const PORTE_AVEC_CLES: String = "Je ferais mieux de fermer avant de partir.\n Et d'être sur de n'avoir rien oublié."
const PORTE_OUVERTE: String = "Bon, il est temps d'y aller.\n Cette enquête n'avancera pas toute seule..."


func _definir_contenu() -> void:
    scene_suivante = "res://scenes/rooms/chambre_luna_room.tscn"

    pensees = {
        "LampArea": "Cette lampe a vu plus de nuits blanches que moi.",
        "WindowArea": "Temps de merde, pour une ville de merde...",
        "AlcoolArea": "Ce n'est pas raisonnable durant une enquête...",
        "PaintingArea": "Je me souviens même pas avoir acheté ce truc.",
        "FilesArea": "Si il y a bien quelque chose que je déteste,\n c'est la PAPERASSE !",
        "ChairArea": "J'ai plus dormi sur cette chaise\n que dans mon lit ces derniers temps...",
        "AshtrayArea": "Un cendrier qui déborde.\n Autant de petites heures parties en fumée.",
    }

    objets_ramassables = {
        "JacketArea": {
            "pensee": "Les clés du bureau sont\n toujours dans la poche.",
            "id": "cles",
            "sprite": "res://assets/art/ui/item_keys.png",
        },
        "CigarettesArea": {
            "pensee": "Pas maintenant...\n Je peux les prendre au cas ou,\n pour plus tard.",
            "id": "cigarettes",
            "sprite": "res://assets/art/ui/item_cigarettes.png",
        },
        "PhotoArea": {
            "pensee": "La photo de Luna.\n Autant la garder sur moi —\n c'est tout ce que j'ai pour l'instant.",
            "id": "picture_luna",
            "sprite": "res://assets/art/characters/picture/picture_luna.png",
        },
    }

    utilisables = {
        "DoorArea": {
            "examiner": _texte_porte_fermee,
            "objets": {
                "cles": {
                    "action": demander_a_quitter.bind(PORTE_OUVERTE),
                },
            },
        },
    }

    # --- PHOTO DE LUNA (apparaît après l'entretien) ---
    _montrer_photo(false)
    Dialogue.conversation_terminee.connect(_sur_entretien_termine)
    Inventaire.inventaire_modifie.connect(_sur_inventaire_modifie)

    # --- CIGARETTES : visibles dès le départ, mais cachées si déjà prises
    #     (cas d'un RETOUR au bureau via la carte). Même logique que la photo.
    if Inventaire.possede("cigarettes"):
        _montrer_cigarettes(false)

    # --- ENTRETIEN D'OUVERTURE (une seule fois) ---
    if not entretien_deja_joue:
        entretien_deja_joue = true
        _lancer_entretien.call_deferred()


func _lancer_entretien() -> void:
    var entretien: Conversation = load("res://resources/entretien_bureau.tres")
    Dialogue.jouer(entretien)


func _texte_porte_fermee() -> String:
    if Inventaire.possede("cles"):
        return PORTE_AVEC_CLES
    return PORTE_SANS_CLES


func _montrer_photo(est_visible: bool) -> void:
    $PhotoArea.visible = est_visible
    $PhotoArea.input_pickable = est_visible


func _montrer_cigarettes(est_visible: bool) -> void:
    $CigarettesArea.visible = est_visible
    $CigarettesArea.input_pickable = est_visible


func _sur_entretien_termine() -> void:
    Carte.debloquer("chambre_luna")
    if Inventaire.possede("picture_luna"):
        return
    _montrer_photo(true)


func _sur_inventaire_modifie() -> void:
    if Inventaire.possede("picture_luna"):
        _montrer_photo(false)
    if Inventaire.possede("cigarettes"):
        _montrer_cigarettes(false)
