shader_type canvas_item;
uniform bool attack_pose = false;
uniform float breath = 0.0;
void vertex() {
	float upper_body = 1.0 - smoothstep(-75.0, 70.0, VERTEX.y);
	VERTEX.y -= upper_body * breath;
}
void fragment() {
	vec4 ink = texture(TEXTURE, UV);
	if (attack_pose) {
		// Suppress the baked glow crossing cell edges. Draw the new trail in code.
		float light = max(ink.r, max(ink.g, ink.b));
		float cold = smoothstep(0.015, 0.12, ink.b - ink.r);
		float glow = max(smoothstep(0.36, 0.60, light) * cold,
			smoothstep(0.58, 0.82, min(ink.r, min(ink.g, ink.b))));
		ink.a *= 1.0 - glow;
		float cell_x = fract(UV.x * 8.0);
		float edge = min(min(cell_x, 1.0 - cell_x), min(UV.y, 1.0 - UV.y));
		ink.a *= smoothstep(0.0, 0.035, edge);
	}
	COLOR = ink;
}
