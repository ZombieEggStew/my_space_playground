// hud_parallax.gdshader
shader_type spatial;
render_mode unshaded, blend_add, cull_disabled;

uniform sampler2D hud_texture : source_color, filter_linear;
uniform float fov_degrees = 20.0; // HUD 准直透镜的视场角范围

void fragment() {
    // 1. 获取相机在模型空间（或世界空间）相对于物体的视线向量
    // VIEW 向量是相机指向像素点的方向（在观察空间中是 -Z）
    // 我们需要将其转到物体的局部空间
    vec3 view_dir_local = (inverse(MODEL_MATRIX) * vec4(INV_VIEW_MATRIX[3].xyz - NODE_POSITION_WORLD, 1.0)).xyz;
    view_dir_local = normalize(view_dir_local);

    // 2. 核心数学：根据视线方向计算 UV 偏移
    // 假设 HUD 图像的正中心对应物体的局部 Z 轴负方向 (0, 0, -1)
    // 我们利用视线的 X 和 Y 分量来偏移 UV
    float sensitivity = 1.0 / tan(radians(fov_degrees));
    vec2 offset = vec2(view_dir_local.x, view_dir_local.y) * sensitivity;

    // 3. 采样纹理（中心对齐）
    vec2 final_uv = vec2(0.5, 0.5) + offset;
    
    // 4. 边缘裁剪（如果 UV 超过 [0,1] 范围则不显示，模拟玻璃框限制）
    if (final_uv.x < 0.0 || final_uv.x > 1.0 || final_uv.y < 0.0 || final_uv.y > 1.0) {
        discard;
    }

    vec4 tex = texture(hud_texture, final_uv);
    ALBEDO = tex.rgb;
    ALPHA = tex.a;
}