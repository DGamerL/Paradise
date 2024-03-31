/mob/living/carbon/human/movement_delay()
	. = 0
	. += ..()
	. += GLOB.configuration.movement.human_delay
	. += dna.species.movement_delay(src)

/mob/living/carbon/human/Process_Spacemove(movement_dir = 0)

	if(..())
		return TRUE

	//Do we have a working jetpack?
	var/obj/item/tank/jetpack/thrust
	if(istype(back, /obj/item/tank/jetpack))
		thrust = back
	else if(istype(wear_suit, /obj/item/clothing/suit/space/hardsuit))
		var/obj/item/clothing/suit/space/hardsuit/C = wear_suit
		thrust = C.jetpack
	else if(ismodcontrol(back))
		var/obj/item/mod/control/C = back
		thrust = locate(/obj/item/mod/module/jetpack) in C
	if(thrust)
		if((movement_dir || thrust.stabilizers) && thrust.allow_thrust(0.01, src))
			return TRUE
	if(dna.species.spec_Process_Spacemove(src))
		return TRUE
	return FALSE

/mob/living/carbon/human/mob_has_gravity()
	. = ..()
	if(!.)
		if(mob_negates_gravity())
			. = 1

/mob/living/carbon/human/mob_negates_gravity()
	return HAS_TRAIT(src, TRAIT_MAGPULSE)

/mob/living/carbon/human/Move(NewLoc, direct)
	. = ..()
	if(.) // did we actually move?
		if(!IS_HORIZONTAL(src) && !buckled && !throwing)
			for(var/obj/item/organ/external/splinted in splinted_limbs)
				splinted.update_splints()

	if(!has_gravity(loc))
		return

	var/obj/item/clothing/shoes/S = shoes

	if(S && !IS_HORIZONTAL(src) && loc == NewLoc)
		SEND_SIGNAL(S, COMSIG_SHOES_STEP_ACTION)

	//Bloody footprints
	var/turf/T = get_turf(src)
	var/obj/item/organ/external/l_foot = get_organ("l_foot")
	var/obj/item/organ/external/r_foot = get_organ("r_foot")
	var/hasfeet = TRUE
	if(!l_foot && !r_foot)
		hasfeet = FALSE

	if(shoes)
		if(S.bloody_shoes && S.bloody_shoes[S.blood_state])
			for(var/obj/effect/decal/cleanable/blood/footprints/oldFP in T)
				if(oldFP && oldFP.blood_state == S.blood_state && oldFP.basecolor == S.blood_color)
					return
			//No oldFP or it's a different kind of blood
			S.bloody_shoes[S.blood_state] = max(0, S.bloody_shoes[S.blood_state] - BLOOD_LOSS_PER_STEP)
			if(S.bloody_shoes[S.blood_state] > BLOOD_LOSS_IN_SPREAD)
				createFootprintsFrom(shoes, dir, T)
			update_inv_shoes()
	else if(hasfeet)
		if(bloody_feet && bloody_feet[blood_state])
			for(var/obj/effect/decal/cleanable/blood/footprints/oldFP in T)
				if(oldFP && oldFP.blood_state == blood_state && oldFP.basecolor == feet_blood_color)
					return
			bloody_feet[blood_state] = max(0, bloody_feet[blood_state] - BLOOD_LOSS_PER_STEP)
			if(bloody_feet[blood_state] > BLOOD_LOSS_IN_SPREAD)
				createFootprintsFrom(src, dir, T)
			update_inv_shoes()
	var/obj/item/clothing/shoes/the_shoes = shoes
	if(istype(the_shoes) && the_shoes.laces_tied_together && !IS_HORIZONTAL(src))
		KnockDown(1 SECONDS)
		Stun(1 SECONDS)
		visible_message("<span class='warning'>[src] trips and falls!", "<span class='warning'>You trip and fall! Your shoes are tied together! Alt-Shift-Click [the_shoes] to untie the knot.")
