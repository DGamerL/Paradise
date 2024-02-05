/* This is a port of Goonstation's Directional lighting, which was committed on June 16th 2020.
 * Original PR was made by mcb (mybluecorners) and permission has [TODO MAKE IT WORK AND ASK FOR PERMISSION]
 * Link to commit : https://github.com/goonstation/goonstation/commit/a6ebd8e26c1b8cf8c97292a1bb28d7c680607f94
*/

/obj/overlay/simple_light/medium/directional
	icon_state = "medium_dir"
	var/dist = 0

// for medium lights the light intensity keeps increasing as you increase alpha past 255
// the upper limit is 510 but some stuff will look a bit weird
/atom/movable/proc/add_mdir_light(id, list/rgba)
	if(!mdir_light_rgbas)
		mdir_light_rgbas = list()

	mdir_light_rgbas[id] = rgba

	show_mdir_light()

	if(length(mdir_light_rgbas) == 1) //dont loop/average if list only contains 1 thing
		for(var/obj/overlay/simple_light/medium/directional/mdir_light in medium_lights)
			if(mdir_light.dist == mdir_light_dists[mdir_light_dists.len])
				mdir_light.color = rgb(rgba[1], rgba[2], rgba[3], min(255, rgba[4]))
			else
				// divided by two because the directional sprites are brighter
				mdir_light.color = rgb(rgba[1], rgba[2], rgba[3], min(255, rgba[4] * 0.4))
	else
		update_mdir_light_color()


/atom/movable/proc/remove_mdir_light(id)
	if(!mdir_light_rgbas)
		return

	if (id)
		if(id in mdir_light_rgbas)
			//medium_light_rgbas -= medium_light_rgbas[id]
			mdir_light_rgbas.Remove(id)
	else
		mdir_light_rgbas.len = 0

	if(length(mdir_light_rgbas) <= 0)
		hide_mdir_light()
	else
		update_mdir_light_color()

/atom/movable/proc/update_mdir_light_color()
	var/avg_r = 0
	var/avg_g = 0
	var/avg_b = 0
	var/sum_a = 0

	for (var/id in mdir_light_rgbas)
		avg_r += mdir_light_rgbas[id][1]
		avg_g += mdir_light_rgbas[id][2]
		avg_b += mdir_light_rgbas[id][3]
		sum_a += mdir_light_rgbas[id][4]

	avg_r /= mdir_light_rgbas.len
	avg_g /= mdir_light_rgbas.len
	avg_b /= mdir_light_rgbas.len

	for(var/obj/overlay/simple_light/medium/directional/mdir_light in src.mdir_lights)
		if(mdir_light.dist == mdir_light_dists[mdir_light_dists.len])
			mdir_light.color = rgb(avg_r, avg_g, avg_b, min(255, sum_a))
		else
			// divided by two because the directional sprites are brighter
			mdir_light.color = rgb(avg_r, avg_g, avg_b, min(255, sum_a  * 0.4))

/atom/movable/proc/show_mdir_light()
	if (!mdir_lights)
		mdir_lights = list()
		for(var/light_dist in src.mdir_light_dists)
			var/obj/overlay/simple_light/medium/directional/light = new(null, null)
			light.dist = light_dist
			src:vis_contents += light
			src.mdir_lights += light
	for(var/obj/overlay/simple_light/medium/directional/light in src.mdir_lights)
		light.invisibility = 0
	update_mdir_light_visibility(dir)

/atom/movable/proc/hide_mdir_light()
	for(var/obj/overlay/simple_light/medium/directional/light in src.mdir_lights)
		light.invisibility = 101

/atom/movable/proc/destroy_mdir_light()
	if(mdir_light_rgbas && length(mdir_light_rgbas))
		hide_mdir_light()
	for(var/obj/overlay/simple_light/medium/directional/light in mdir_lights)
		src:vis_contents -= light
		qdel(light)
	mdir_light_rgbas = null
	mdir_lights = null

/atom/movable/proc/update_mdir_light_visibility(direct)
	if(mdir_lights[1].invisibility == 101) // toggled off
		return
	if(!isturf(loc))
		for(var/x in mdir_lights)
			var/obj/overlay/simple_light/medium/directional/light = x
			src:vis_contents -= light
		return

	if(!direct)
		return

	//optimize
	var/vx = 0
	var/vy = 0
	if(direct & NORTH)
		vy = 1
	if(direct & SOUTH)
		vy = -1
	if(direct & WEST)
		vx = -1
	if(direct & EAST)
		vx = 1

	var/list/turfs_to_light = list()
	var/turf/cache_turf
	for(var/i in 1 to 7)
		cache_turf = (cache_turf ? get_step(cache_turf, dir) : get_step(src, dir))
		if(iswallturf(cache_turf))
			continue
		turfs_to_light += cache_turf

//	var/turf/TT = getlineopaqueblocked(src,T)
//	var/dist = get_dist(src, TT) - 1
	var/mag = sqrt(vx * vx + vy * vy) //normalize vec
	if(mag)
		vx /= mag
		vy /= mag
	var/dist = get_dist(src, turfs_to_light[7]) // THIS IS TEMPORARY UNTIL I HAVE INTERNET AGAIN
	for(var/x in mdir_lights)
		var/obj/overlay/simple_light/medium/directional/light = x
		if(light.icon_state == "medium_center" && light.dist == 0)
			src:vis_contents += light
			continue

		////light.pixel_x = (vx * min(dist,light.dist) * 32) - 32
		//light.pixel_y = (vy * min(dist,light.dist) * 32) - 32

		animate(light,pixel_x = ((vx * min(dist,light.dist) * 32) - 32), pixel_y = ((vy * min(dist,light.dist) * 32) - 32), time = 1, easing = EASE_IN)

		src:vis_contents += light
