GLOBAL_LIST_EMPTY(flame_effects)
#define MAX_FIRE_EXIST_TIME 10 MINUTES // That's a lot of fuel, but you are not gonna make it last for longer

/obj/effect/fire
	name = "\improper Fire"
	desc = "You don't think you should touch this."
	icon = 'icons/effects/chemical_fire.dmi'
	icon_state = "fire1"

	/// How hot is our fire?
	var/temperature
	/// How long will our fire last
	var/duration = 10 SECONDS
	/// How many firestacks does the fire give to mobs
	var/application_stacks = 1

/obj/effect/fire/Initialize(mapload, reagent_temperature, reagent_duration, fire_applications)
	. = ..()

	if(!reagent_duration || !reagent_temperature) // There is no reason for this thing to exist
		qdel(src)
		return

	duration = reagent_duration
	temperature = reagent_temperature
	application_stacks = max(application_stacks, fire_applications)

	for(var/obj/effect/fire/flame as anything in GLOB.flame_effects)
		if(flame == src)
			continue
		if(get_dist(src, flame) < 1) // It's on the same turf
			merge_flames(flame)

	for(var/atom/movable/thing_to_burn in get_turf(src))
		if(isliving(thing_to_burn))
			var/mob/living/mob_to_burn = thing_to_burn
			mob_to_burn.adjustFireLoss(temperature / 100)
			mob_to_burn.adjust_fire_stacks(application_stacks)
			mob_to_burn.IgniteMob()
			continue

		if(isobj(thing_to_burn))
			var/obj/obj_to_burn = thing_to_burn
			obj_to_burn.fire_act(null, temperature)
			continue

	GLOB.flame_effects += src
	START_PROCESSING(SSprocessing, src)

/obj/effect/fire/Destroy()
	. = ..()
	GLOB.flame_effects -= src
	STOP_PROCESSING(SSprocessing, src)

/obj/effect/fire/process()
	if(duration <= 0)
		fizzle()
		return

	duration -= 2 SECONDS

/obj/effect/fire/water_act(volume, temperature, source, method)
	. = ..()
	duration -= 10 SECONDS
	if(duration <= 0)
		fizzle()

/obj/effect/fire/Crossed(atom/movable/AM, oldloc)
	. = ..()
	if(isliving(AM)) // TODO: add checks to see if they're protected here first
		var/mob/living/mob_to_burn = AM
		mob_to_burn.adjustFireLoss(temperature / 100)
		mob_to_burn.adjust_fire_stacks(application_stacks)
		mob_to_burn.IgniteMob()
		to_chat(mob_to_burn, "<span class='warning'>[src] burns you!</span>")
		return

	if(isitem(AM))
		var/obj/item/item_to_burn = AM
		item_to_burn.fire_act(null, temperature)

/obj/effect/fire/proc/fizzle()
	playsound(src, 'sound/effects/fire_sizzle.ogg', 50, TRUE)
	qdel(src)

/obj/effect/fire/proc/merge_flames(obj/effect/fire/merging_flame)
	duration = min((duration + (merging_flame.duration / 4)), MAX_FIRE_EXIST_TIME)
	temperature = ((merging_flame.temperature + temperature) / 2) // No making a sun by just clicking 10 times on a turf
	merging_flame.fizzle()

#undef MAX_FIRE_EXIST_TIME
