# BlenderNoiseNode.gd
@tool
extends VisualShaderNodeCustom
class_name VisualShaderNodeBlenderNoise

func _get_name():
	return "BlenderNoise"

func _get_category():
	return "CustomNodes"

func _get_description():
	return "类似 Blender 的 3D 噪波纹理，无缝且无极点拉伸。"

func _get_return_icon_type():
	return VisualShaderNode.PORT_TYPE_SCALAR

func _get_input_port_count():
	return 5

func _get_input_port_name(port):
	match port:
		0: return "pos"
		1: return "scale"
		2: return "detail"
		3: return "roughness"
		4: return "seed"

func _get_input_port_type(port):
	match port:
		0: return VisualShaderNode.PORT_TYPE_VECTOR_3D
		1: return VisualShaderNode.PORT_TYPE_SCALAR
		2: return VisualShaderNode.PORT_TYPE_SCALAR
		3: return VisualShaderNode.PORT_TYPE_SCALAR
		4: return VisualShaderNode.PORT_TYPE_SCALAR

func _get_output_port_count():
	return 1

func _get_output_port_name(port):
	return "value"

func _get_output_port_type(port):
	return VisualShaderNode.PORT_TYPE_SCALAR

# 这里是核心逻辑的 GLSL 实现
func _get_code(input_vars, output_vars, mode, type):
	var pos = input_vars[0]
	var scale = input_vars[1]
	var detail = input_vars[2]
	var roughness = input_vars[3]
	var seed_val = input_vars[4]
	
	return """
		vec3 p_calc = (%s * %s) + vec3(%s * 13.45, %s * 7.89, %s * 11.23);
		float total_n = 0.0;
		float amp = 1.0;
		float max_amp = 0.0;

		for (int k = 0; k < 6; k++) {
			if (float(k) >= %s) break;

			vec3 i = floor(p_calc);
			vec3 f = fract(p_calc);
			vec3 u = f * f * (3.0 - 2.0 * f);

			float n_raw[8];
			for (int j = 0; j < 8; j++) {
				vec3 corner = i + vec3(float(j %% 2), float((j / 2) %% 2), float(j / 4));
				vec3 p3 = fract(corner * vec3(0.1031, 0.1030, 0.0973));
				p3 += dot(p3, p3.yzx + 19.19);
				n_raw[j] = fract((p3.x + p3.y) * p3.z) * 2.0 - 1.0;
			}

			float res = mix(
				mix(mix(n_raw[0], n_raw[1], u.x), mix(n_raw[2], n_raw[3], u.x), u.y),
				mix(mix(n_raw[4], n_raw[5], u.x), mix(n_raw[6], n_raw[7], u.x), u.y), 
				u.z
			);

			total_n += res * amp;
			max_amp += amp;
			amp *= %s;
			p_calc *= 2.0;
		}
		%s = (total_n / max_amp) * 0.5 + 0.5;
	""" % [pos, scale, seed_val, seed_val, seed_val, detail, roughness, output_vars[0]]