shader_type canvas_item;
render_mode blend_mix;

void fragment() {
	// Called for every pixel the material is visible on.
	COLOR = texture(TEXTURE, UV) * COLOR; // Multiplies instance by texture colour
}

