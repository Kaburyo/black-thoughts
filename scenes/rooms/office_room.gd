# office_room.gd
# Pièce "Bureau d'Al'".
#
# Toute la MÉCANIQUE vit dans le moule room_base.gd. Ici, on ne déclare
# que ce qui est PROPRE au bureau : pensées, objets, la porte, la photo
# de Luna, et le DÉCLENCHEMENT de l'entretien d'ouverture (une seule fois).

class_name OfficeRoom
extends RoomBase


# Drapeau "entretien d'ouverture déjà joué ?". C'est un "static" PUBLIC :
#   - static = sa valeur appartient au SCRIPT (pas à l'instance), donc
#     elle survit aux changements de pièce -> l'entretien ne se rejoue
#     pas quand on REVIENT au bureau via la carte ;
#   - public (sans "_") = l'écran-titre peut le remettre à false pour
#     qu'une NOUVELLE partie rejoue bien l'entretien (et ramène le HUD).
static var entretien_deja_joue: bool = false


# --- Textes de la porte ---
const PORTE_SANS_CLES: String = "Je ferais mieux de prendre mon manteau et\n mes clés du bureau avant de partir."
const PORTE_AVEC_CLES: String = "Je ferais mieux de fermer avant de partir.\n Et d'être sur de n'avoir rien oublié."
const PORTE_OUVERTE: String = "Bon, il est temps d'y aller.\n Cette enquête n'avancera pas toute seule..."


# --- Contenu propre au bureau ---
func _definir_contenu() -> void:
    # (Champ hérité, désormais inerte : la carte gère la destination.)
    scene_suivante = "res://scenes/rooms/chambre_luna_room.tscn"

    pensees = {
        "LampArea": "Cette lampe a vu plus de nuits blanches que moi.",
        "WindowArea": "Temps de merde, pour une ville de merde...",
        "AlcoolArea": "Ce n'est pas raisonnable durant une enquête...",
        "PaintingArea": "Je me souviens même pas avoir acheté ce truc.",
        "FilesArea": "Si il y a bien quelque chose que je déteste,\n c'est la PAPERASSE !",
        "ChairArea": "J'ai plus dormi sur cette chaise\n que dans mon lit ces derniers temps...",
    }

    objets_ramassables = {
        "JacketArea": {
            "pensee": "Les clés du bureau sont\n toujours dans la poche.",
            "id": "cles",
            "sprite": "res://assets/art/ui/item_keys.png",
        },
        "AshtrayArea": {
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

    # --- LA PHOTO DE LUNA (étape L.24, option A) ---
    _montrer_photo(false)
    Dialogue.conversation_terminee.connect(_sur_entretien_termine)
    Inventaire.inventaire_modifie.connect(_sur_inventaire_modifie)

    # --- ENTRETIEN D'OUVERTURE (une seule fois) ---
    # Lancé en call_deferred (après le _ready du moule) pour que le gel
    # du décor pendant la conversation soit bien branché.
    if not entretien_deja_joue:
        entretien_deja_joue = true
        _lancer_entretien.call_deferred()


func _lancer_entretien() -> void:
    var entretien: Conversation = load("res://resources/entretien_bureau.tres")
    Dialogue.jouer(entretien)


# --- LA PORTE : texte quand on la clique MAINS VIDES ---
func _texte_porte_fermee() -> String:
    if Inventaire.possede("cles"):
        return PORTE_AVEC_CLES
    return PORTE_SANS_CLES


# --- LA PHOTO DE LUNA : apparition / disparition ---
func _montrer_photo(est_visible: bool) -> void:
    $PhotoArea.visible = est_visible
    $PhotoArea.input_pickable = est_visible


func _sur_entretien_termine() -> void:
    # L'entretien est fini : Jenny a confié l'affaire. Al' sait désormais
    # où aller -> on débloque la chambre de Luna sur la carte.
    Carte.debloquer("chambre_luna")

    if Inventaire.possede("picture_luna"):
        return
    _montrer_photo(true)


func _sur_inventaire_modifie() -> void:
    if Inventaire.possede("picture_luna"):
        _montrer_photo(false)
