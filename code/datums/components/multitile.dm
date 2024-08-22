///Lets multitile objects have dense walls around them based on the coordinate map
/datum/component/multitile
	///Reference to all fillers
	var/list/all_fillers = list()

/*
  * These should all be done in this style. It represents a coordinate map of the grid around `src`.
  * The src itself should always have no density, as the density should be set on the atom and not with a filler
  * list(
		list(0, 0, 0,		   0, 0),
		list(0, 0, 0,		   0, 0),
		list(0, 0, MACH_CENTER, 0, 0),
		list(0, 0, 0,		   0, 0),
		list(0, 0, 0,		   0, 0)
	)
 */

//distance_from_center does not include src itself
/datum/component/multitile/Initialize(distance_from_center, new_filler_map)
	if(!distance_from_center || !length(new_filler_map))
		return COMPONENT_INCOMPATIBLE

	if(!isatom(parent))
		return COMPONENT_INCOMPATIBLE
	var/atom/parent_atom = parent

	var/max_height = length(new_filler_map)
	var/max_width = length(new_filler_map[1]) //it should have the same length on every row

	var/current_height = 0
	var/current_width = 0

	for(var/turf/filler_turf as anything in RANGE_TURFS(distance_from_center, parent_atom))
		if(new_filler_map[max_height - current_height][max_width - current_width]) // Because the `block()` proc always works from the bottom left to the top right, we have to loop through our nested lists in reverse
			var/obj/structure/filler/new_filler = new(filler_turf)
			all_fillers += new_filler
		current_width += 1
		if(current_width == max_width)
			current_height += 1
			current_width = 0

/datum/component/multitile/Destroy(force, silent)
	QDEL_LIST_CONTENTS(all_fillers)
	. = ..()
