shader_type canvas_item;

uniform sampler2D screen_texture: hint_screen_texture;
uniform sampler2D mask_texture;
uniform bool white_reveals = true; // Black hides. When false, black reveals and white hides.
uniform bool clip_blending = false;

// 0: MIX, 1: ADD, 2: SUB, 3: MULTIPLY, 4: SCREEN
uniform int blend_mode : hint_range(0, 4);

void fragment() {
	// COLORING
	switch (blend_mode) {
		case 1:
			COLOR.rgb += vec3(texture(screen_texture, SCREEN_UV).rgb);
			break;
		case 2:
			COLOR.rgb -= vec3(texture(screen_texture, SCREEN_UV).rgb);
			break;
		case 3:
			vec3 screen_tex = vec3(texture(screen_texture, SCREEN_UV).rgb);
			if (screen_tex.rgb != vec3(0.0, 0.0, 0.0)) {
				COLOR.rgb *= screen_tex;
			} else if (clip_blending) {
				COLOR.a = 0.0;
			}
			break;
		case 4:
			vec3 screen_tex = vec3(texture(screen_texture, SCREEN_UV).rgb);
			if (screen_tex.rgb != vec3(0.0, 0.0, 0.0)) {
				COLOR.rgb = 1.0 - (vec3(1.0, 1.0, 1.0) - vec3(texture(screen_texture, SCREEN_UV).rgb)) * (vec3(1.0, 1.0, 1.0) - COLOR.rgb);
			} else if (clip_blending) {
				COLOR.a = 0.0;
			}
			break;
	}

	// ALPHA MASKING
	if (white_reveals) {
		COLOR.a *= (
		texture(mask_texture, SCREEN_UV).r
		+ texture(mask_texture, SCREEN_UV).g
		+ texture(mask_texture, SCREEN_UV).b
		) /3.0;
	} else {
		COLOR.a *= 1.0 - (
		texture(mask_texture, SCREEN_UV).r
		+ texture(mask_texture, SCREEN_UV).g
		+ texture(mask_texture, SCREEN_UV).b
		) /3.0;
	}
}