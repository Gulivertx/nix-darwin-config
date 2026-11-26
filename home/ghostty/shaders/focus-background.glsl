// Fond différent selon que la surface (fenêtre/split) est active ou non.
// Couleurs inspirées du thème sombre de macOS 27 :
//   active   = textBackgroundColor   (#1E1E1E) -> défini par `background` dans la config
//   inactive = underPageBackgroundColor (#282828)
const vec3 INACTIVE_BG = vec3(0x28, 0x28, 0x28) / 255.0;

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord / iResolution.xy;
    vec4 c = texture(iChannel0, uv);

    if (float(iFocus) < 0.5) {
        // Remplace les pixels proches du fond (avec un léger fondu pour
        // les bords anti-aliasés du texte).
        float d = distance(c.rgb, iBackgroundColor);
        float w = 1.0 - smoothstep(0.0, 0.06, d);
        c.rgb = mix(c.rgb, c.rgb + (INACTIVE_BG - iBackgroundColor), w);
    }

    fragColor = c;
}
