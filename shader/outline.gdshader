shader_type spatial;
render_mode cull_front, unshaded;

uniform vec4 outline_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float outline_width : hint_range(0.0, 1.0) = 0.05;

void vertex() {
	// 沿着法线方向向外平移顶点，实现描边层的拓宽
	VERTEX += NORMAL * outline_width;
}

void fragment() {
	// 设置描边颜色
	ALBEDO = outline_color.rgb;
	ALPHA = outline_color.a;
}