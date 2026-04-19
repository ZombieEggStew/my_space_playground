shader_type spatial;
render_mode wireframe,unshaded;
varying vec4 color;
varying vec3 normal;
void vertex() { 

	}
	void fragment() {
	if(ALBEDO.r+ALBEDO.g+ALBEDO.b<0.001){
	discard;
	}
	ALBEDO=vec3(VERTEX.y,0.0,0.0);
// Called for every pixel the material is visible on.
}