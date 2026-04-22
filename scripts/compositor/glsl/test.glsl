#[compute]
#version 450

layout(local_size_x = 1, local_size_y = 1, local_size_z = 1) in;

layout(rgba16f , set = 0, binding = 0) uniform image2D color_image;

void main() {
    ivec2 size = imageSize(color_image);
    int pixel_size = 4; // 像素化尺寸，可以根据需要调整

    ivec2 uv = ivec2(gl_GlobalInvocationID.xy);
    if (uv.x >= size.x || uv.y >= size.y) {
        return;
    }

    // 计算像素块的起始坐标
    ivec2 pixelated_uv = (uv / pixel_size) * pixel_size;
    
    // 获取在该块起始位置的颜色
    vec4 color = imageLoad(color_image, pixelated_uv);

    imageStore(color_image, uv, color);
} 