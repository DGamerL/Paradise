/obj/effect/decal/puddle
	/// Do we have any initial reagents? Is setup as an alist. Example: `"water" = 10'
	var/alist/initial_reagents = alist()
	/// Do we evaporate? False by default
	var/evaporation = FALSE


/obj/effect/decal/puddle/Initialize(mapload, list/chemical_list = list())
	. = ..()
	for(var/chem_id, amount in initial_reagents)
		reagents.add_reagent(chem_id, amount)
	if(!length(chemical_list))
		return INITIALIZE_HINT_QDEL
	setup_chemicals()
	if(evaporation)
		START_PROCESSING(SSprocessing, src)

/obj/effect/decal/puddle/proc/setup_chemicals()
	for(var/datum/reagent/chem as anything in reagents.reagent_list)
		// TODO
		return

/obj/effect/decal/puddle/process()
	var/reagent_count = length(reagents.reagent_list)
	var/amount_to_remove = max(round(reagents.get_reagent_amount() * 0.1 / reagent_count), 1)
	for(var/i in 1 to reagent_count)
		var/datum/reagent/chem = reagents.reagent_list[i]
		reagents.remove_reagent(chem.id, amount_to_remove)
