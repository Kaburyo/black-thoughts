// filtre_mental.gdshader
// Le SHADER du filtre mental d'Al'.
//
// Un shader décide de la couleur de chaque pixel de l'écran. Celui-ci
// a un seul but : assombrir l'écran en VIGNETTAGE — clair au centre,
// sombre tout autour, avec les COINS naturellement les plus sombres
// (comme si Al' fermait peu à peu les yeux). Le centre reste lisible.
//
// L'intensité globale est pilotée DE L'EXTÉRIEUR par le script
// filtre_mental.gd (selon la santé mentale d'Al'). Le shader, lui, ne
// connaît pas la santé mentale : il applique juste les réglages reçus.

shader_type canvas_item;

// --- Réglages reçus de l'extérieur ("uniform" = réglage piloté par le script) ---

// Intensité globale du filtre, de 0.0 (rien) à 1.0 (assombrissement max).
// hint_range borne la valeur ; c'est le script qui la fera varier.
uniform float intensite : hint_range(0.0, 1.0) = 0.0;

// Filtre PERMANENT : intensité minimale toujours appliquée, même quand
// la santé mentale est au maximum. Garde un léger voile dans les coins
// en permanence. 0.15 = un soupçon. À régler en test.
uniform float filtre_minimum : hint_range(0.0, 1.0) = 0.15;

// Rayon du coeur CLAIR au centre : en deçà de cette distance au centre,
// l'écran reste totalement intact. Plus c'est grand, plus la zone
// lisible est large. 0.45 laisse un large centre net.
uniform float rayon_clair : hint_range(0.0, 1.0) = 0.45;

// Distance au centre à partir de laquelle l'assombrissement est à fond
// (les coins). Entre rayon_clair et rayon_sombre : le dégradé doux.
uniform float rayon_sombre : hint_range(0.0, 1.5) = 0.95;

// Noirceur maximale dans les coins quand intensite vaut 1.0.
// 0.85 = presque noir, mais jamais 100 % opaque. À régler en test.
uniform float noirceur_max : hint_range(0.0, 1.0) = 0.85;


// La fonction fragment() est exécutée pour CHAQUE pixel de l'écran.
void fragment() {
    // UV est la position du pixel : (0,0) coin haut-gauche,
    // (1,1) coin bas-droit. Le centre de l'écran est donc (0.5, 0.5).

    // Vecteur du centre vers le pixel. On multiplie la composante
    // horizontale par 2 et la verticale par 2 aussi : "distance" vaudra
    // alors 0 au centre et ~1 sur les bords (et plus dans les coins).
    vec2 depuis_centre = (UV - vec2(0.5)) * 2.0;
    float distance = length(depuis_centre);

    // On transforme cette distance en un facteur 0->1 :
    //   - pixel dans le coeur clair (dist <= rayon_clair) -> 0 (intact)
    //   - pixel au-delà de rayon_sombre                   -> 1 (sombre à fond)
    // smoothstep fait une transition DOUCE entre les deux : le dégradé.
    float vignette = smoothstep(rayon_clair, rayon_sombre, distance);

    // Intensité réellement appliquée : jamais en dessous du minimum
    // permanent. max() garde la plus grande des deux valeurs.
    float intensite_reelle = max(intensite, filtre_minimum);

    // Opacité finale de ce pixel de voile noir :
    //   vignette (où on est) x noirceur_max (à fond) x intensite_reelle.
    float alpha = vignette * noirceur_max * intensite_reelle;

    // On peint le pixel en noir, avec l'opacité calculée.
    // Au centre de l'écran alpha vaut 0 -> totalement transparent.
    COLOR = vec4(0.0, 0.0, 0.0, alpha);
}
