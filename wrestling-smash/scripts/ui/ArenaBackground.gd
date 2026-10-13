## Animated arena backdrop shared by all menus: dark gradient, three swaying spotlight beams,
## camera flashes in the crowd, apron glow and vignette (one canvas_item shader, no assets).
extends ColorRect

const SHADER := """
shader_type canvas_item;
uniform float aspect = 1.7778;
uniform float beam_strength = 0.24;
uniform vec4 col_top : source_color = vec4(0.06, 0.066, 0.11, 1.0);
uniform vec4 col_bottom : source_color = vec4(0.012, 0.012, 0.022, 1.0);
uniform vec4 beam1 : source_color = vec4(1.0, 0.78, 0.42, 1.0);
uniform vec4 beam2 : source_color = vec4(0.38, 0.62, 1.0, 1.0);
uniform vec4 beam3 : source_color = vec4(1.0, 0.30, 0.34, 1.0);

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }

float cone(vec2 p, vec2 o, float ang, float halfw) {
	vec2 d = p - o;
	if (d.y <= 0.0) return 0.0;
	float a = atan(d.x, d.y);
	float x = abs(a - ang) / halfw;
	float c = 1.0 - smoothstep(0.45, 1.0, x);
	float fade = exp(-length(d) * 0.85);
	return c * (0.30 + 0.70 * fade);
}

void fragment() {
	vec2 uv = UV;
	vec2 p = vec2(uv.x * aspect, uv.y);
	float t = TIME;
	vec3 col = mix(col_top.rgb, col_bottom.rgb, smoothstep(0.0, 1.0, uv.y));
	float b1 = cone(p, vec2(aspect * 0.16, -0.10), 0.38 + 0.20 * sin(t * 0.33), 0.15);
	float b2 = cone(p, vec2(aspect * 0.84, -0.10), -0.38 + 0.20 * sin(t * 0.27 + 1.7), 0.15);
	float b3 = cone(p, vec2(aspect * 0.50, -0.14), 0.25 * sin(t * 0.19 + 0.6), 0.10);
	col += (beam1.rgb * b1 + beam2.rgb * b2 + beam3.rgb * b3 * 0.75) * beam_strength;
	col += vec3(0.025) * (sin(p.x * 3.0 + t * 0.25) * 0.5 + 0.5) * (1.0 - uv.y);
	vec2 g = p * 38.0;
	vec2 cell = floor(g);
	float h = hash(cell);
	float flash = step(0.993, h) * pow(max(0.0, sin(t * (0.7 + h * 2.5) + h * 50.0)), 30.0);
	flash *= smoothstep(0.32, 0.0, length(fract(g) - 0.5));
	col += vec3(1.0, 0.96, 0.9) * flash * smoothstep(0.50, 0.85, uv.y) * 0.9;
	col += vec3(0.95, 0.55, 0.22) * exp(-pow((uv.y - 1.0) * 7.0, 2.0)) * 0.12;
	vec2 v = uv - 0.5;
	col *= 1.0 - dot(v, v) * 1.15;
	COLOR = vec4(col, 1.0);
}
"""

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	color = Color.BLACK
	var sh := Shader.new()
	sh.code = SHADER
	var m := ShaderMaterial.new()
	m.shader = sh
	material = m
	resized.connect(_on_resized)
	_on_resized()

func _on_resized() -> void:
	if size.y > 0.0 and material:
		(material as ShaderMaterial).set_shader_parameter("aspect", size.x / size.y)

func set_strength(v: float) -> void:
	(material as ShaderMaterial).set_shader_parameter("beam_strength", v)
