shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

uniform sampler2D albedo_texture;

void fragment() {
    vec4 tex_color = texture(albedo_texture, UV);
    ALBEDO = tex_color.rgb;
	ALPHA = tex_color.a;


	//ALBEDO = vec3(0.0); // Black surface that fully blocks light

}

/*
	// Make fully transparent pixels not cast shadows
    if (ALPHA < 0.1) {
        discard;
    }
*/