shader_type spatial;
render_mode unshaded, cull_disabled; // 禁用剔除，保证正反都能看到描边

uniform vec4 outline_color : source_color = vec4(0.5, 0.5, 0.5, 1.0); // 描边颜色
uniform float outline_width : hint_range(0, 10) = 1.0; // 描边宽度（像素单位）

void vertex() {
    // 将顶点变换到裁剪空间
    vec4 clip_pos = PROJECTION_MATRIX * (MODELVIEW_MATRIX * vec4(VERTEX, 1.0));
    // 获取法线在裁剪空间的映射（用于偏移）
    vec3 clip_normal = mat3(PROJECTION_MATRIX) * (mat3(MODELVIEW_MATRIX) * NORMAL);
    
    // 在屏幕空间进行像素级偏移
    vec2 offset = normalize(clip_normal.xy) / VIEWPORT_SIZE * clip_pos.w * outline_width * 2.0;
    clip_pos.xy += offset;
    
    POSITION = clip_pos;
}

void fragment() {
    ALBEDO = outline_color.rgb;
    ALPHA = outline_color.a;
}