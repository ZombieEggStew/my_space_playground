shader_type sky;



uniform float seed = 0.0;
uniform float star_scale = 60.0;
uniform float star_density = 1.0; // multiplier for number/brightness

uniform float star_size = 0.01;
uniform float star_size_var = 0.04;

// Pseudo-random 2D vector from 2D input.
vec2 hash22(vec2 p) {
	p = vec2(dot(p, vec2(127.1, 311.7)), dot(p, vec2(269.5, 183.3)));
	return fract(sin(p) * 43758.5453123);
}

void sky() {
	vec3 dir = normalize(EYEDIR);
	vec2 uv = vec2(atan(dir.x, dir.z) / (2.0 * PI) + 0.5, asin(clamp(dir.y, -1.0, 1.0)) / PI + 0.5);

	// Scale UV into a grid where each integer cell may contain one star (pseudo-random)
	vec2 p = uv * star_scale;
	vec2 n = floor(p);
	vec2 f = fract(p);

	float brightness = 0.0;

	// iterate nearby cells to accumulate star contribution
	for (int j = -2; j <= 2; j++) {
		for (int i = -2; i <= 2; i++) {
			vec2 cell = n + vec2(float(i), float(j));

			// get a deterministic random offset inside the cell
			vec2 rnd = hash22(cell + vec2(seed, seed * 1.37));

			// optionally animate via TIME (uncomment to enable motion)
			// rnd += vec2(TIME * 0.01, TIME * 0.013);

			vec2 starPos = vec2(float(i), float(j)) + rnd - f;
			float d = length(starPos);

			// star radius / size (random per cell)
			float r = star_size + rnd.x * star_size_var;

			// brightness falloff: smooth center, sharper tail
			float t = clamp(1.0 - d / r, 0.0, 1.0);
			float contrib = t * t; // quadratic falloff

			// star intensity factor from hash
			float inten = 0.5 + rnd.y * 1.5;

			brightness += contrib * inten * star_density;
		}
	}

	// tone-map and clamp
	brightness = clamp(brightness, 0.0, 1.0);

	// small tweak to give stars a bluish-white tint
	vec3 starColor = mix(vec3(1.0, 0.95, 0.9), vec3(0.8, 0.9, 1.0), seed * 0.01);

	COLOR = vec3(brightness) * starColor;
}
