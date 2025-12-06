/obj/effect/decal/puddle
	icon_state = "shadowcocoon"
	/// Do we have any initial reagents? Is setup as an alist. Example: `"water" = 10'
	var/alist/initial_reagents = alist()
	/// Do we evaporate? Only used for pre-mapped puddles
	var/evaporation = FALSE
	/// The spillover/temporary holder of reagents. ALWAYS clear this out when you're done with it
	var/datum/reagents/spillover_holder

/obj/effect/decal/puddle/Initialize(mapload, datum/reagents/temp_holder)
	. = ..()
	reagents = new (50)
	spillover_holder = new (1000) // If they manage to overflow this, chapeau
	for(var/chem_id, amount in initial_reagents)
		reagents.add_reagent(chem_id, amount)
	if(!length(reagents.reagent_list) && !temp_holder)
		return INITIALIZE_HINT_QDEL

	if(temp_holder)
		var/difference = temp_holder.total_volume - reagents.maximum_volume
		if(difference)
			temp_holder.trans_to(spillover_holder, difference)
			splash(spillover_holder)
			spillover_holder.clear_reagents()
		temp_holder.trans_to(reagents, 50)

	RegisterSignal(get_turf(src), COMSIG_ATOM_ENTERED, PROC_REF(run_crossed))
	setup_chemicals()
	if(evaporation)
		START_PROCESSING(SSprocessing, src)

/obj/effect/decal/puddle/process()
	var/reagent_count = length(reagents.reagent_list)
	var/amount_to_remove = max(round(reagents.get_reagent_amount() * 0.1 / reagent_count), 1)
	for(var/i in 1 to reagent_count)
		var/datum/reagent/chem = reagents.reagent_list[i]
		if(chem.volume <= amount_to_remove)
			chem.on_puddle_removed()
		reagents.remove_reagent(chem.id, amount_to_remove)
	if(!length(reagents.reagent_list))
		qdel(src)

/obj/effect/decal/puddle/update_icon_state()
	switch(reagents.total_volume)
		if(1 to 10)
			icon_state = "small_puddle"
		if(10 to 25)
			icon_state = "medium_puddle"
		if(25 to 50)
			icon_state = "large_puddle"
			for(var/turf/T as anything in get_adjacent_turfs(src))
				if(!(locate(/obj/effect/decal/puddle) in T))
					continue
				icon_state += "_[get_dir(src, T)]"

	color = mix_color_from_reagents(reagents.reagent_list)

/obj/effect/decal/puddle/proc/setup_chemicals()
	for(var/datum/reagent/chem as anything in reagents.reagent_list)
		chem.on_puddle_enter(src)

/obj/effect/decal/puddle/proc/run_crossed(datum/source, mob/living/victim)
	if(!istype(victim)) // We only care about mobs
		return
	for(var/datum/reagent/chem as anything in reagents.reagent_list)
		chem.on_puddle_crossed(src, victim)

/// Adds reagents to the puddle. Expects only transfers of already existing reagents
/obj/effect/decal/puddle/proc/add_reagent(datum/reagents/temp_holder)
	for(var/datum/reagent/chem as anything in temp_holder.reagent_list)
		var/free_space = reagents.get_free_space()
		if(chem.volume > free_space)
			temp_holder.trans_id_to(spillover_holder, chem.id, (chem.volume - free_space))
		if(!chem?.volume)
			continue
		chem.on_puddle_enter(src)
		temp_holder.trans_id_to(reagents, chem.id, chem.volume)

	splash(spillover_holder)
	spillover_holder.clear_reagents()
	update_icon(UPDATE_ICON_STATE)

/obj/effect/decal/puddle/proc/splash(datum/reagents/temp_holder)
	var/list/possible_turfs = list()
	for(var/turf/target as anything in get_adjacent_open_turfs(src))
		if(locate(/obj/effect/decal/puddle) in target)
			continue // No doublestacking puddles
		possible_turfs += target

	if(!length(possible_turfs))
		spillover_holder.clear_reagents()
		return // Maybe think of something here? This is safe though

	var/puddle_amount = ROUND_UP(spillover_holder.total_volume / 50) // Puddles have a capacity of 50u
	for(var/i in 1 to puddle_amount)
		if(!length(possible_turfs))
			spillover_holder.clear_reagents()
			return
		var/turf/target_turf = pick_n_take(possible_turfs)
		var/datum/reagents/temp = new (50)
		spillover_holder.trans_to(temp, 50)
		new /obj/effect/decal/puddle(target_turf, temp)
		qdel(temp)
		if(!length(spillover_holder.reagent_list))
			// No need to clear, already empty
			return

/datum/reagent/proc/on_puddle_enter(obj/effect/decal/puddle/puddle)
	return

/datum/reagent/water/on_puddle_enter(obj/effect/decal/puddle/puddle)
	puddle.AddComponent(/datum/component/slippery, puddle, 4 SECONDS)
	START_PROCESSING(SSprocessing, puddle)

/datum/reagent/proc/on_puddle_crossed(obj/effect/decal/puddle/puddle, mob/living/victim)
	return

/datum/reagent/proc/puddle_fire_act(obj/effect/decal/puddle/puddle)
	return

/datum/reagent/proc/on_puddle_removed(obj/effect/decal/puddle/puddle)
	return
