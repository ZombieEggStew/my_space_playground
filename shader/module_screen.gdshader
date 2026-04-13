shader_type canvas_item;

// 改用手动传入的纹理，不再使用全局的 SCREEN_TEXTURE
uniform sampler2D ui_viewport_texture : filter_linear;

uniform float bend_amount : hint_range(-2.0, 2.0) = 0.2;


vec2 get_curved_uv(vec2 uv) {
    vec2 centered_uv = (uv - 0.5) * 2.0;
    float dist = length(centered_uv);
    // 这里修改为中心收紧的效果：
    // 使用 (1.0 - dist) 让中心受到的偏移影响比四周更大，
    // 或者直接改变偏移公式的权重方向。
    centered_uv *= 1.0 + ((1.0 - dist) * bend_amount);
    return (centered_uv / 2.0) + 0.5;
}

void fragment() {
    // 使用普通的 UV (ColorRect 自身的 UV)
    vec2 curved_uv = get_curved_uv(UV);
    
    if (curved_uv.x < 0.0 || curved_uv.x > 1.0 || curved_uv.y < 0.0 || curved_uv.y > 1.0) {
        // 超出范围设为全透明，这样就能看到底下的 3D 画面了
        COLOR = vec4(0.0);
    } else {

        COLOR = texture(ui_viewport_texture, curved_uv);
    }
}