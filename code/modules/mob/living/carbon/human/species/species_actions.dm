/*
 * Unathi match ignite ability
 */

/datum/action/innate/unathi_ignite
	name = "Ignite"
	desc = "A fire forms in your mouth, fierce enough to... light a cigarette. Requires you to drink welding fuel beforehand."
	icon_icon = 'icons/obj/cigarettes.dmi'
	button_icon_state = "match_unathi"
	var/cooldown = 0
	var/cooldown_duration = 20 SECONDS
	var/welding_fuel_used = 3 //one sip, with less strict timing
	check_flags = AB_CHECK_HANDS_BLOCKED

/datum/action/innate/unathi_ignite/Activate()
	var/mob/living/carbon/human/user = owner
	if(world.time <= cooldown)
		to_chat(user, "<span class='warning'>Your throat hurts too much to do it right now. Wait [round((cooldown - world.time) / 10)] seconds and try again.</span>")
		return
	if(!welding_fuel_used || user.reagents.has_reagent("fuel", welding_fuel_used))
		if((user.head?.flags_cover & HEADCOVERSMOUTH) || (user.wear_mask?.flags_cover & MASKCOVERSMOUTH) && !user.wear_mask?.up)
			to_chat(user, "<span class='warning'>Your mouth is covered.</span>")
			return
		var/obj/item/match/unathi/fire = new(user.loc, src)
		if(user.put_in_hands(fire))
			to_chat(user, "<span class='notice'>You ignite a small flame in your mouth.</span>")
			user.reagents.remove_reagent("fuel", 50) //slightly high, but I'd rather avoid it being TOO spammable.
			cooldown = world.time + cooldown_duration
		else
			qdel(fire)
			to_chat(user, "<span class='warning'>You don't have any free hands.</span>")
	else
		to_chat(user, "<span class='warning'>You need to drink welding fuel first.</span>")

/*
 * Hiding your tail/wings ability
 */

/datum/action/innate/hide_accessory
	name = "Hide tail"
	desc = "Hide your tail under your clothing."
	var/accessory_tag_to_hide = "tail"
	COOLDOWN_DECLARE(time_till_tail)

/datum/action/innate/hide_accessory/Activate()
	var/mob/living/carbon/human/user = owner
	if(!istype(user))
		return
	if(!COOLDOWN_FINISHED(src, time_till_tail))
		// TODO: add message
		return
	if(user.hidden_accessory)
		unhide_accessory(user)
		COOLDOWN_START(src, time_till_tail, 3 MINUTES)
		return

/datum/action/innate/hide_accessory/proc/unhide_accessory(mob/living/carbon/human/user)
	if(!user.hidden_accessory)
		return
	user.tail = user.hidden_accessory
	user.hidden_accessory = null

/datum/action/innate/hide_accessory/tail

/datum/action/innate/hide_accessory/tail/Activate()
	. = ..()
	var/mob/living/carbon/human/user = owner
	if(!user.tail || !.)
		return

	user.hidden_accessory = accessory_tag_to_hide
	user.tail = null
	user.update_tail_layer()

/datum/action/innate/hide_accessory/wing

/datum/action/innate/hide_accessory/wing/Activate()
	. = ..()
	var/mob/living/carbon/human/user = owner
	if(!. || !user.wing)
		return

/datum/action/innate/hide_accessory/wing/unhide_accessory()
	return

/*
 * Nian cocoon ability & cocoon
 */

#define COCOON_WEAVE_DELAY 5 SECONDS
#define COCOON_EMERGE_DELAY 15 SECONDS
#define COCOON_HARM_AMOUNT 50
#define COCOON_NUTRITION_AMOUNT -200

/datum/action/innate/cocoon
	name = "Cocoon"
	desc = "Restore your wings and antennae, and heal some damage. If your cocoon is broken externally you will take heavy damage!"
	check_flags = AB_CHECK_RESTRAINED|AB_CHECK_STUNNED|AB_CHECK_CONSCIOUS|AB_CHECK_TURF
	icon_icon = 'icons/effects/effects.dmi'
	button_icon_state = "cocoon1"

/datum/action/innate/cocoon/Activate()
	var/mob/living/carbon/human/moth/H = owner
	if(H.nutrition < COCOON_NUTRITION_AMOUNT)
		to_chat(H, "<span class='warning'>You are too hungry to cocoon!</span>")
		return
	H.visible_message("<span class='notice'>[H] begins to hold still and concentrate on weaving a cocoon...</span>", "<span class='notice'>You begin to focus on weaving a cocoon... (This will take [COCOON_WEAVE_DELAY / 10] seconds, and you must hold still.)</span>")
	if(do_after(H, COCOON_WEAVE_DELAY, FALSE, H))
		if(H.incapacitated())
			to_chat(H, "<span class='warning'>You cannot weave a cocoon in your current state.</span>")
			return
		H.visible_message("<span class='notice'>[H] finishes weaving a cocoon!</span>", "<span class='notice'>You finish weaving your cocoon.</span>")
		var/obj/structure/moth/cocoon/C = new(get_turf(H))
		H.forceMove(C)
		C.preparing_to_emerge = TRUE
		H.apply_status_effect(STATUS_EFFECT_COCOONED)
		H.KnockOut()
		H.create_log(MISC_LOG, "has woven a cocoon")
		addtimer(CALLBACK(src, PROC_REF(emerge), C), COCOON_EMERGE_DELAY, TIMER_UNIQUE)
	else
		to_chat(H, "<span class='warning'>You need to hold still in order to weave a cocoon!</span>")

/**
 * Removes moth from cocoon, restores burnt wings
 */
/datum/action/innate/cocoon/proc/emerge(obj/structure/moth/cocoon/C)
	for(var/mob/living/carbon/human/H in C.contents)
		H.remove_status_effect(STATUS_EFFECT_COCOONED)
		H.remove_status_effect(STATUS_EFFECT_BURNT_WINGS)
	C.preparing_to_emerge = FALSE
	qdel(C)

/obj/structure/moth/cocoon
	name = "\improper Nian cocoon"
	desc = "Someone wrapped in a Nian cocoon."
	icon = 'icons/effects/effects.dmi'
	icon_state = "cocoon1"
	color = COLOR_PALE_YELLOW //So tiders (hopefully) don't decide to immediately bust them open
	max_integrity = 60
	var/preparing_to_emerge

/obj/structure/moth/cocoon/Initialize(mapload)
	. = ..()
	icon_state = pick("cocoon1", "cocoon2", "cocoon3")

/obj/structure/moth/cocoon/Destroy()
	if(!preparing_to_emerge)
		visible_message("<span class='danger'>[src] splits open from within!</span>")
	else
		visible_message("<span class='danger'>[src] is smashed open, harming the Nian within!</span>")
		for(var/mob/living/carbon/human/H in contents)
			H.adjustBruteLoss(COCOON_HARM_AMOUNT)
			H.adjustFireLoss(COCOON_HARM_AMOUNT)
			H.AdjustWeakened(10 SECONDS)

	for(var/mob/living/carbon/human/H in contents)
		H.remove_status_effect(STATUS_EFFECT_COCOONED)
		H.adjust_nutrition(COCOON_NUTRITION_AMOUNT)
		H.WakeUp()
		H.forceMove(loc)
		H.create_log(MISC_LOG, "has emerged from their cocoon with the nutrition level of [H.nutrition][H.nutrition <= NUTRITION_LEVEL_STARVING ? ", now starving" : ""]")
	return ..()

#undef COCOON_WEAVE_DELAY
#undef COCOON_EMERGE_DELAY
#undef COCOON_HARM_AMOUNT
#undef COCOON_NUTRITION_AMOUNT
