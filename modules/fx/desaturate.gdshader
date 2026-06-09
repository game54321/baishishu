shader_type canvas_item;

uniform float saturation : hint_range(0.0, 1.0) = 0.2;
uniform vec4 tint_color : source_color = vec4(0.08, 0.07, 0.1, 0.7);

void fragment() {
	vec4 col = texture(TEXTURE, UV);
	float gray = dot(col.rgb, vec3(0.299, 0.587, 0.114));
	col.rgb = mix(vec3(gray), col.rgb, saturation);
	col.rgb = mix(col.rgb, tint_color.rgb, tint_color.a);
	COLOR = col;
}
