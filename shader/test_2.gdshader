shader_type spatial;
render_mode unshaded;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
uniform sampler2D depth_texture : hint_depth_texture, repeat_disable, filter_nearest;
uniform sampler2D normal_roughness_texture : hint_normal_roughness_texture, repeat_disable, filter_nearest;

uniform float outline_thickness = 1.0;
uniform float depth_threshold = 0.01;
uniform float normal_threshold = 0.5;
uniform vec4 outline_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);

void vertex() {
    POSITION = vec4(VERTEX.xy, 1.0, 1.0);
}

void fragment() {
    vec2 uv = SCREEN_UV;
    
    // 采样中心点的深度和法线
    float depth = texture(depth_texture, uv).r;
    vec3 normal = texture(normal_roughness_texture, uv).rgb;
    
    // 基础边缘检测逻辑
    float edge = 0.0;
    
    // 上下左右采样对比
    vec2 offsets[4] = vec2[](
        vec2(0.0, 1.0), vec2(0.0, -1.0), 
        vec2(1.0, 0.0), vec2(-1.0, 0.0)
    );
    
    vec2 screen_pixel_size = 1.0 / VIEWPORT_SIZE;
    
    for (int i = 0; i < 4; i++) {
        vec2 neighbor_uv = uv + offsets[i] * screen_pixel_size * outline_thickness;
        
        float neighbor_depth = texture(depth_texture, neighbor_uv).r;
        vec3 neighbor_normal = texture(normal_roughness_texture, neighbor_uv).rgb;
        
        // // 深度差异检测
        // if (abs(depth - neighbor_depth) > depth_threshold) {
        //     edge = 1.0;
        // }
        // 法线差异检测
        if (distance(normal, neighbor_normal) > normal_threshold) {
            edge = 1.0;
        }
    }
    
    vec4 screen_color = texture(screen_texture, uv);
    ALBEDO = mix(screen_color.rgb, outline_color.rgb, edge);
}