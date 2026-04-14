shader_type canvas_item;

uniform float radius : hint_range(0.0, 1.0) = 0.5; // 圆环半径
uniform float thickness : hint_range(0.0, 1.0) = 0.1; // 圆环粗细
uniform float start_angle : hint_range(0.0, 360.0) = 0.0; // 起始角度（度）
uniform float end_angle : hint_range(0.0, 360.0) = 180.0; // 结束角度（度）

void fragment() {
    // 将 UV 居中并调整范围到 [-0.5, 0.5]
    vec2 center_uv = UV - vec2(0.5, 0.5);
    
    // 计算极坐标
    float dist = length(center_uv);
    float angle = degrees(atan(center_uv.y, center_uv.x));
    
    // 将 atan 的输出从 [-180, 180] 映射到 [0, 360]
    if (angle < 0.0) {
        angle += 360.0;
    }

    // 检查像素是否在下半圆的半径范围内
    bool in_radius = dist >= (radius - thickness * 0.5) && dist <= (radius + thickness * 0.5);
    
    // 检查像素是否在下半圆的角度范围内 (180度到360度通常是下半部分)
    // 这里的 start_angle 和 end_angle 对应 ProgressBar 的完成百分比
    // 假设 ProgressBar 的 value 映射到 UV.x
    // 我们需要把 UV.x 映射到实际的裁剪范围
    
    // 默认下半圆是 0 到 180 (在 atan 坐标系中 y > 0 是下半部分)
    // 注意：CanvasItem 的 Y 轴向下，所以 y > 0 是屏幕下方
    bool in_angle = angle >= 0.0 && angle <= 180.0;

    // 经典的进度条处理：根据原始 UV.x (进度值) 来决定是否填色
    // 在弯曲后，UV.x 实际上对应角进度
    float progress = UV.x; 
    float current_angle = mix(0.0, 180.0, progress);
    
    // 最终裁剪
    if (in_radius && angle <= current_angle) {
        COLOR = texture(TEXTURE, UV); // 保留原有纹理（ProgressBar 的颜色/样式）
    } else {
        COLOR = vec4(0.0); // 透明
    }
}
