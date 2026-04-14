shader_type canvas_item;

uniform vec4 line_color : source_color = vec4(1.0, 1.0, 1.0, 0.5);
uniform float line_count : hint_range(0.0, 200.0) = 100.0;
uniform float line_density : hint_range(0.0, 1.0) = 0.5;
uniform float line_faloff : hint_range(0.0, 1.0) = 0.25; // 中心透明区域大小
uniform float speed : hint_range(0.0, 20.0) = 10.0;
uniform float noise_scale : hint_range(0.0, 1.0) = 0.1;

// 简单的随机函数
float random(vec2 st) {
    return fract(sin(dot(st.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

void fragment() {
    vec2 uv = UV - 0.5;
    float angle = atan(uv.y, uv.x);
    float radius = length(uv);

    // 基于角度生成随机线条
    float line_value = random(vec2(floor(angle * line_count), 0.0));
    
    // 增加随时间变化的动态效果
    float time_offset = TIME * speed;
    float noise = random(vec2(floor(angle * line_count), floor(time_offset)));
    
    // 只有随机值大于密度阈值的才显示线条
    float mask = step(1.0 - line_density, noise);
    
    // 让线条从外向内淡化，保持中心视野清晰
    float fade = smoothstep(line_faloff, 0.5, radius);
    
    vec4 final_color = line_color;
    final_color.a *= mask * fade;
    
    COLOR = final_color;
}