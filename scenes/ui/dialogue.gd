# dialogue.gd
# Service autonome du SYSTÈME DE DIALOGUE — autoload "Dialogue".
#
# C'est la boîte de texte des conversations entre personnages
# (Al' et Jenny, plus tard les autres). À ne pas confondre avec la
# VOIX INTÉRIEURE (service "Voix") : ce sont deux services séparés.
#   - Voix     : les pensées d'Al', boîte SOMBRE, disparaît seule.
#   - Dialogue : les conversations, boîte CLAIRE, reste affichée,
#                avance au CLIC du joueur (voir la "bible", section E).
#
# ÉTAT À CETTE ÉTAPE (D7-b-2) : le service joue une conversation, gère
# les choix et leur effet, annonce le début / la fin de la
# conversation, crée les portraits dynamiquement et met en avant le
# parleur par estompage. La réponse choisie est PRONONCÉE dans la
# boîte. Le service GARDE EN MÉMOIRE les lignes réellement prononcées
# (D7-a) et sait afficher un PANNEAU DE RÉCAP qui les réaffiche. Ce
# récap se bascule (ouvrir / fermer) par la touche R, ou par le bouton
# Récap du HUD hors conversation — tous deux appellent basculer_recap().
# PAS ENCORE GÉRÉ : la variation du texte d'Al' selon son palier de
# santé mentale.

extends CanvasLayer


# --- Signaux ---
# Émis quand une conversation COMMENCE et quand elle SE TERMINE.
# Les pièces (room_base.gd) s'y abonnent pour geler / dégeler leur
# point-and-click. Le service annonce ; chacun en tire les
# conséquences chez soi (même patron qu'Inventaire ou les jauges).
signal conversation_demarree
signal conversation_terminee


# --- Références aux nœuds ---
@onready var boite: Panel = $BoiteDialogue
@onready var texte_dialogue: Label = $BoiteDialogue/TexteDialogue
@onready var zone_choix: VBoxContainer = $ZoneChoix
@onready var zone_portraits: Control = $ZonePortraits
# Le panneau de récap et ses deux enfants.
@onready var panneau_recap: Panel = $PanneauRecap
@onready var texte_recap: RichTextLabel = $PanneauRecap/TexteRecap
@onready var bouton_fermer: Button = $PanneauRecap/BoutonFermer


# --- Réglage de l'animation du texte ---
const VITESSE_LETTRE: float = 0.045

# Taille du texte sur les boutons de choix.
const TAILLE_TEXTE_CHOIX: int = 36


# --- Réglages de placement des portraits ---
# La résolution du jeu (voir la "bible", section M : 1920x1080).
const LARGEUR_ECRAN: float = 1920.0
# Dimensions d'un portrait, identiques à gauche comme à droite.
const PORTRAIT_LARGEUR: float = 500.0
const PORTRAIT_HAUTEUR: float = 700.0
# Distance entre le haut de l'écran et le haut du portrait.
const PORTRAIT_MARGE_HAUT: float = 100.0


# --- Réglages de l'estompage ---
# Opacité du portrait du personnage QUI PARLE (pleine visibilité).
const OPACITE_PARLEUR: float = 1.0
# Opacité du portrait d'un personnage qui NE parle pas (estompé).
const OPACITE_ESTOMPE: float = 0.45
# Durée du fondu d'estompage, en secondes.
const DUREE_ESTOMPAGE: float = 0.25


# --- État de l'affichage ---
enum Etat { REPOS, ECRITURE, FINIE, CHOIX }
#   REPOS    : aucune conversation en cours, boîte cachée.
#   ECRITURE : une réplique est en train de s'écrire lettre par lettre.
#   FINIE    : la réplique est entièrement affichée, on attend le clic.
#   CHOIX    : 3 boutons sont affichés, on attend que le joueur choisisse.
var _etat: Etat = Etat.REPOS


# --- Conversation en cours ---
#   _conversation : le .tres en train d'être joué.
#   _index        : le numéro de la réplique actuellement affichée.
#   _choix_courant: le choix en cours d'affichage (null hors d'un choix).
var _conversation: Conversation = null
var _index: int = 0
var _choix_courant: ChoixDialogue = null

# Vrai quand la boîte affiche la réponse que le joueur vient de
# choisir (et non une réplique normale du .tres). Sert à savoir, au
# clic suivant, qu'il faut simplement passer à la réplique suivante
# au lieu de re-proposer le choix.
var _en_reponse_choisie: bool = false

# --- Portraits affichés ---
# La liste des portraits actuellement à l'écran. IMPORTANT : son ordre
# suit exactement la liste `personnages` de la conversation, donc
# _portraits[i] est le portrait de personnages[i]. C'est ce qui permet
# de retrouver le portrait du locuteur, désigné par un numéro.
var _portraits: Array[TextureRect] = []

# --- Historique de la conversation ---
# Le "carnet" du dialogue : la liste des lignes RÉELLEMENT prononcées,
# dans l'ordre. Chaque entrée est une fiche { "nom": ..., "texte": ... }.
# On y range les répliques du .tres ET la réponse que le joueur a
# effectivement choisie ; JAMAIS les options qu'il n'a pas retenues
# (règle actée — bible, section E et L.7).
# Le carnet est vidé au DÉBUT de chaque conversation (dans jouer()),
# et PAS à la fin : le récap doit rester relisable une fois la
# conversation terminée (le bouton du HUD, D7-b, s'utilise hors
# dialogue, quand le HUD est de nouveau visible).
var _historique: Array[Dictionary] = []


# Appelée automatiquement une fois, au lancement.
func _ready() -> void:
    boite.visible = false
    zone_choix.visible = false
    panneau_recap.visible = false
    bouton_fermer.pressed.connect(_fermer_recap)
    boite.gui_input.connect(_sur_clic_boite)
    print("Dialogue prêt.")


# --- DÉMARRER UNE CONVERSATION ---
func jouer(conversation: Conversation) -> void:
    # Sécurité : une conversation vide ou absente ne lance rien.
    if conversation == null or conversation.repliques.is_empty():
        push_warning("Dialogue : conversation vide ou absente.")
        return

    _conversation = conversation
    _index = 0

    # Page blanche : on vide le carnet de la conversation précédente.
    _historique.clear()

    # On fabrique les portraits des personnages de cette conversation.
    _creer_portraits()

    # On annonce le début : le HUD se cache, le décor se gèle.
    Hud.cacher()
    conversation_demarree.emit()

    _afficher_replique_courante()


# --- CRÉER LES PORTRAITS DE LA CONVERSATION ---
# Vide la zone, puis fabrique un TextureRect par personnage de la
# conversation, placé selon son côté. Aucun portrait n'est câblé dans
# la scène : ils naissent ici, à partir des fiches PersonnageDialogue.
func _creer_portraits() -> void:
    # On repart d'une zone propre (sécurité).
    for ancien in zone_portraits.get_children():
        ancien.queue_free()
    _portraits.clear()

    for perso in _conversation.personnages:
        var portrait := TextureRect.new()
        portrait.texture = perso.sprite
        portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        portrait.flip_h = true
        portrait.size = Vector2(PORTRAIT_LARGEUR, PORTRAIT_HAUTEUR)
        portrait.position = _position_portrait(perso.cote)
        # Les portraits sont purement décoratifs : ils laissent les
        # clics traverser (par propreté, comme leur zone parente).
        portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
        # On démarre estompé : le premier parleur sera mis en avant
        # tout de suite par _mettre_en_avant_le_parleur().
        portrait.modulate.a = OPACITE_ESTOMPE

        zone_portraits.add_child(portrait)
        # On garde le portrait dans la liste, dans le MÊME ordre que
        # les personnages : _portraits[i] <-> personnages[i].
        _portraits.append(portrait)


# Renvoie la position (coin haut-gauche) d'un portrait selon son côté.
func _position_portrait(cote: PersonnageDialogue.Cote) -> Vector2:
    if cote == PersonnageDialogue.Cote.GAUCHE:
        return Vector2(0.0, PORTRAIT_MARGE_HAUT)
    # DROITE : collé au bord droit de l'écran.
    return Vector2(LARGEUR_ECRAN - PORTRAIT_LARGEUR, PORTRAIT_MARGE_HAUT)


# --- METTRE EN AVANT LE PARLEUR ---
# Le portrait du personnage `numero_parleur` va en pleine opacité ;
# tous les autres vont vers l'opacité estompée. La transition est
# douce (Tween). On joue UNIQUEMENT sur l'opacité — jamais sur la
# luminosité (réservée au code couleur moral, bible L.2).
func _mettre_en_avant_le_parleur(numero_parleur: int) -> void:
    for i in range(_portraits.size()):
        var portrait: TextureRect = _portraits[i]
        var opacite_visee: float = OPACITE_ESTOMPE
        if i == numero_parleur:
            opacite_visee = OPACITE_PARLEUR

        # Un Tween fait glisser l'opacité en douceur jusqu'à la cible.
        var tween: Tween = create_tween()
        tween.tween_property(portrait, "modulate:a",
                opacite_visee, DUREE_ESTOMPAGE)


# --- AFFICHER UN TEXTE DANS LA BOÎTE ---
# Coeur commun de l'affichage : met en avant le locuteur, range la
# ligne dans l'historique, puis écrit le texte lettre par lettre.
# Sert aussi bien aux répliques normales du .tres qu'à la réponse
# choisie par le joueur — c'est donc le SEUL endroit à observer pour
# capturer tout ce qui est réellement prononcé, et rien d'autre.
func _afficher_texte(texte: String, numero_locuteur: int) -> void:
    _mettre_en_avant_le_parleur(numero_locuteur)

    # On range cette ligne dans le carnet de la conversation.
    _noter_dans_historique(texte, numero_locuteur)

    texte_dialogue.text = texte
    texte_dialogue.visible_ratio = 0.0
    boite.visible = true

    _etat = Etat.ECRITURE
    _ecrire_lettre_par_lettre(texte.length())


# --- NOTER UNE LIGNE DANS L'HISTORIQUE ---
# Range une fiche { "nom": ..., "texte": ... } dans _historique.
# On y stocke le NOM du personnage — résolu ici, tant que la
# conversation est encore vivante — et non son numéro : le panneau de
# récap (D7-b) pourra ainsi réafficher l'échange même APRÈS la fin de
# la conversation, sans avoir à recroiser la liste `personnages`.
func _noter_dans_historique(texte: String, numero_locuteur: int) -> void:
    var nom: String = "?"
    if numero_locuteur >= 0 \
            and numero_locuteur < _conversation.personnages.size():
        nom = _conversation.personnages[numero_locuteur].nom
    else:
        push_warning("Dialogue : locuteur %d hors de la liste des "
                % numero_locuteur + "personnages.")

    _historique.append({ "nom": nom, "texte": texte })


# --- LIRE L'HISTORIQUE ---
# Donne accès, en lecture, aux lignes réellement jouées de la dernière
# conversation (ou de celle en cours). On renvoie une COPIE : personne
# ne peut ainsi modifier le carnet du service depuis l'extérieur.
func historique() -> Array:
    return _historique.duplicate()


# --- OUVRIR LE PANNEAU DE RÉCAP ---
# Reconstruit le texte de l'échange depuis le carnet, le met dans
# TexteRecap, et allume le panneau. Le panneau étant le dernier enfant
# de la scène, il se dessine par-dessus tout — y compris une
# conversation en cours. Fonction interne : on passe toujours par
# basculer_recap() (la seule porte publique).
func _ouvrir_recap() -> void:
    texte_recap.text = _construire_texte_recap()
    # On repart toujours du haut de la liste.
    texte_recap.scroll_to_line(0)
    panneau_recap.visible = true


# --- FERMER LE PANNEAU DE RÉCAP ---
# Branché sur le bouton Fermer du panneau (voir _ready). On se contente
# de cacher le panneau : la conversation, si elle est en cours, a
# continué tranquillement derrière et reprend là où elle en était.
func _fermer_recap() -> void:
    panneau_recap.visible = false


# --- CONSTRUIRE LE TEXTE DU RÉCAP ---
# Transforme le carnet _historique en un seul texte affichable.
# Chaque entrée devient une ligne au format :  Nom : "Texte"
# Le nom est mis en gras (BBCode) ; le texte de la réplique est gardé
# TEL QUEL, retours à la ligne d'origine compris. Une ligne vide
# sépare deux répliques pour aérer la lecture.
func _construire_texte_recap() -> String:
    if _historique.is_empty():
        return "[i]Aucun échange à afficher pour l'instant.[/i]"

    var morceaux: Array[String] = []
    for entree in _historique:
        var nom: String = entree["nom"]
        var texte: String = entree["texte"]
        morceaux.append("[b]%s :[/b] \"%s\"" % [nom, texte])

    # Une ligne vide entre chaque réplique.
    return "\n\n".join(morceaux)


# --- AFFICHER LA RÉPLIQUE COURANTE ---
func _afficher_replique_courante() -> void:
    # On affiche une réplique normale du .tres (pas une réponse choisie).
    _en_reponse_choisie = false

    var replique: RepliqueDialogue = _conversation.repliques[_index]

    # Pour l'instant on affiche toujours le texte de base. La variation
    # selon le palier de santé mentale d'Al' sera branchée plus tard.
    _afficher_texte(replique.texte, replique.locuteur)


# --- L'ÉCRITURE LETTRE PAR LETTRE ---
func _ecrire_lettre_par_lettre(nb_lettres: int) -> void:
    for i in range(nb_lettres):
        if _etat != Etat.ECRITURE:
            return
        texte_dialogue.visible_ratio = float(i + 1) / float(nb_lettres)
        await get_tree().create_timer(VITESSE_LETTRE).timeout

    _etat = Etat.FINIE


# --- CLIC SUR LA BOÎTE ---
func _sur_clic_boite(event: InputEvent) -> void:
    if not (event is InputEventMouseButton):
        return
    if not (event.button_index == MOUSE_BUTTON_LEFT and event.pressed):
        return

    if _etat == Etat.ECRITURE:
        _afficher_tout_de_suite()
    elif _etat == Etat.FINIE:
        _apres_replique()


# --- AFFICHER LA RÉPLIQUE D'UN COUP ---
func _afficher_tout_de_suite() -> void:
    _etat = Etat.FINIE
    texte_dialogue.visible_ratio = 1.0


# --- APRÈS UNE RÉPLIQUE FINIE ---
func _apres_replique() -> void:
    # Cas 1 : on vient d'afficher la réponse choisie par le joueur.
    # La suite, c'est simplement la réplique suivante du .tres.
    if _en_reponse_choisie:
        _replique_suivante()
        return

    # Cas 2 : une réplique normale. Si elle porte un choix, on le
    # présente ; sinon on enchaîne sur la réplique suivante.
    var replique: RepliqueDialogue = _conversation.repliques[_index]
    if replique.choix != null:
        _afficher_choix(replique.choix)
    else:
        _replique_suivante()


# --- AFFICHER UN CHOIX ---
func _afficher_choix(choix: ChoixDialogue) -> void:
    _etat = Etat.CHOIX
    _choix_courant = choix

    for ancien in zone_choix.get_children():
        ancien.queue_free()

    zone_choix.add_child(_creer_bouton_choix(choix.texte_a, 0))
    zone_choix.add_child(_creer_bouton_choix(choix.texte_b, 1))
    zone_choix.add_child(_creer_bouton_choix(choix.texte_c, 2))

    zone_choix.visible = true


# Construit un bouton de choix à partir d'un texte et de son numéro.
# Le bouton garde le texte BRUT, indication de ton comprise : elle
# aide le joueur à choisir. Elle ne sera retirée qu'au moment où la
# réponse est prononcée dans la boîte (voir _texte_parle).
func _creer_bouton_choix(texte: String, numero: int) -> Button:
    var bouton := Button.new()
    bouton.text = texte
    bouton.add_theme_font_size_override("font_size", TAILLE_TEXTE_CHOIX)
    bouton.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    bouton.pressed.connect(_sur_clic_choix.bind(numero))
    return bouton


# --- CLIC SUR UNE OPTION DE CHOIX ---
func _sur_clic_choix(numero: int) -> void:
    if _etat != Etat.CHOIX:
        return

    # 1. L'option choisie influe sur la santé mentale d'Al'.
    var delta: float = _valeur_option(numero)
    SanteMentale.modifier(delta)
    print("Dialogue : option %d choisie -> santé mentale %+.0f"
            % [numero, delta])

    # 2. On retient QUI parle et QUOI, avant de nettoyer le choix.
    var numero_locuteur: int = _choix_courant.locuteur
    var texte: String = _texte_parle(_texte_option(numero))

    # 3. On efface les boutons de choix.
    _cacher_choix()

    # 4. La réponse choisie devient une vraie réplique : elle s'écrit
    #    dans la boîte, le portrait de son locuteur passe en avant.
    #    (C'est _afficher_texte qui la rangera dans l'historique :
    #    seule la réponse RETENUE y entre, jamais les options A/B/C
    #    que le joueur n'a pas choisies.)
    _en_reponse_choisie = true
    _afficher_texte(texte, numero_locuteur)


# --- TEXTE BRUT D'UNE OPTION ---
func _texte_option(numero: int) -> String:
    match numero:
        0:
            return _choix_courant.texte_a
        1:
            return _choix_courant.texte_b
        2:
            return _choix_courant.texte_c
        _:
            return ""


# --- NETTOYER LE TEXTE D'UNE RÉPONSE ---
# Le texte d'une option peut commencer par une indication de ton ou
# de jeu entre parenthèses — ex. « (las) On vous a mal renseignée. »
# Cette indication aide le joueur sur le bouton, mais Al' ne la "dit"
# pas : on la retire avant d'écrire la réponse dans la boîte.
func _texte_parle(texte: String) -> String:
    var propre: String = texte.strip_edges()
    if propre.begins_with("("):
        var fin: int = propre.find(")")
        if fin != -1:
            propre = propre.substr(fin + 1)
    return propre.strip_edges()


# --- VALEUR CACHÉE D'UNE OPTION ---
func _valeur_option(numero: int) -> float:
    match numero:
        0:
            return _choix_courant.valeur_a
        1:
            return _choix_courant.valeur_b
        2:
            return _choix_courant.valeur_c
        _:
            return 0.0


# --- CACHER LES BOUTONS DE CHOIX ---
func _cacher_choix() -> void:
    for bouton in zone_choix.get_children():
        bouton.queue_free()
    zone_choix.visible = false
    _choix_courant = null


# --- PASSER À LA RÉPLIQUE SUIVANTE ---
func _replique_suivante() -> void:
    _index += 1

    if _index >= _conversation.repliques.size():
        _terminer()
        return

    _afficher_replique_courante()


# --- FIN DE LA CONVERSATION ---
func _terminer() -> void:
    boite.visible = false
    zone_choix.visible = false

    # On retire les portraits de l'écran.
    for portrait in _portraits:
        portrait.queue_free()
    _portraits.clear()

    _etat = Etat.REPOS
    _conversation = null
    _index = 0
    _choix_courant = null
    _en_reponse_choisie = false

    # NOTE : on NE vide PAS _historique ici. Le carnet doit survivre à
    # la fin de la conversation pour que le récap (D7-b) reste lisible.
    # Il sera vidé au prochain jouer(), au début de la conversation
    # suivante.

    # On annonce la fin : le décor se dégèle, le HUD revient.
    conversation_terminee.emit()
    Hud.montrer()

    print("Dialogue : conversation terminée.")


# --- BASCULER LE PANNEAU DE RÉCAP ---
# PORTE D'ENTRÉE PUBLIQUE du récapitulatif : ouvre le récap s'il est
# fermé, le ferme s'il est ouvert. Une seule fonction pour les deux
# sens — appelée aussi bien par la touche R que par le bouton Récap
# du HUD (D7-b-2). Tout passe par ici.
func basculer_recap() -> void:
    if panneau_recap.visible:
        _fermer_recap()
    else:
        _ouvrir_recap()


# --- Raccourci clavier : la touche R bascule le récap ---
func _input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo:
        if event.keycode == KEY_R:
            basculer_recap()
