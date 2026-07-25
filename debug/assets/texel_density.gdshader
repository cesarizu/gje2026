shader_type spatial;

uniform sampler2D original_texture;

void fragment() {
	ivec2 texture_size = textureSize(original_texture, 0);

	ivec2 p = ivec2(UV * vec2(texture_size));
	ivec2 p4 = p / 4;
	ivec2 p16 = p / 16;

	bool odd = (p.x + p.y) % 2 == 0;
	bool odd4 = (p4.x + p4.y) % 2 == 0;
	bool odd16 = (p16.x + p16.y) % 2 == 0;

	ALBEDO = vec3(odd ? 1.0 : 0.0, odd4 ? 1.0 : 0.0, odd16 ? 1.0 : 0.0);
}