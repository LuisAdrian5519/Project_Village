shader_type canvas_item;
render_mode unshaded;

uniform vec2 arena_size;
uniform float spawn_margin;
uniform vec2 player_position;
uniform vec2 plant_position;
uniform float safe_distance;
uniform float relocation_distance;

void fragment() {
	// Las UV del rectángulo se convierten a coordenadas locales de Arena.
	vec2 point = (UV - vec2(0.5)) * arena_size;
	vec2 half_extent = arena_size * 0.5 - vec2(spawn_margin);
	vec2 edge_distance = half_extent - abs(point);
	float player_distance = distance(point, player_position);
	float plant_distance = distance(point, plant_position);
	vec4 tint = vec4(0.0);

	if (edge_distance.x >= 0.0 && edge_distance.y >= 0.0) {
		bool near_player = player_distance < safe_distance;
		bool near_plant = plant_distance < relocation_distance;
		tint = vec4(0.15, 1.0, 0.35, 0.20);
		if (near_player) {
			tint = vec4(1.0, 0.15, 0.2, 0.18);
		}
		if (near_plant) {
			tint = vec4(1.0, 0.55, 0.1, 0.18);
		}
		if (abs(player_distance - safe_distance) < 1.5) {
			tint = vec4(1.0, 0.15, 0.2, 0.85);
		}
		if (abs(plant_distance - relocation_distance) < 1.5) {
			tint = vec4(1.0, 0.55, 0.1, 0.85);
		}
		if (min(edge_distance.x, edge_distance.y) < 2.0) {
			tint = vec4(0.2, 0.85, 1.0, 0.9);
		}
	}
	COLOR = tint;
}
