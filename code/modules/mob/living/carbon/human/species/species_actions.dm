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

/datum/action/innate/unathi_ignite/ash_walker
	desc = "You form a fire in your mouth, fierce enough to... light a cigarette."
	cooldown_duration = 3 MINUTES
	welding_fuel_used = 0 // Ash walkers dont need welding fuel to use ignite

/*
 * Hiding your tail/wings ability
 */

/datum/action/innate/hide_accessory
	name = "Hide tail"
	desc = "Hide your tail under your clothing."
	button_icon_state = "tail"
	/// The body accessory
	var/body_accessory_hidden
	/// The body accessory's icon state
	var/hidden_accessory
	/// The timer that counts down until our accessory is forcefully revealed!
	var/time_till_reveal
	COOLDOWN_DECLARE(time_till_tail)

/datum/action/innate/hide_accessory/Activate()
	var/mob/living/carbon/human/user = owner
	. = TRUE
	if(!istype(user))
		return FALSE
	if(!COOLDOWN_FINISHED(src, time_till_tail))
		to_chat(user, "<span class='notice'>You must wait [COOLDOWN_TIMELEFT(src, time_till_tail) / 10] seconds until you can do this!</span>")
		return FALSE
	if(hidden_accessory)
		unhide_accessory(user)
		COOLDOWN_START(src, time_till_tail, 3 MINUTES)
		return FALSE
	if(!user.wear_suit?.tuckable)
		to_chat(user, "<span class='notice'>You cannot tuck your tail in those clothes!</span>")
		return FALSE

/datum/action/innate/hide_accessory/proc/unhide_accessory(mob/living/carbon/human/user)
	if(!user.hidden_accessory)
		return
	user.tail = hidden_accessory
	user.hidden_accessory = null
	user.body_accessory = body_accessory_hidden
	user.update_tail_layer()
	time_till_reveal = null

/datum/action/innate/hide_accessory/proc/forceful_unhide(mob/living/carbon/human/user)
	if(!user || QDELETED(user)) // Sanity checks
		return
	COOLDOWN_START(src, time_till_tail, 5 MINUTES) // Ouch, my tail!
	to_chat(user, "<span class='warning'>Your tail hurts so much, you have to untuck it!</span>")
	unhide_accessory()

/datum/action/innate/hide_accessory/tail

/datum/action/innate/hide_accessory/tail/Activate()
	. = ..()
	var/mob/living/carbon/human/user = owner
	if(!. || !user.tail)
		return

	to_chat(user, "You hide your tail.")
	hidden_accessory = user.tail
	user.tail = null
	body_accessory_hidden = user.body_accessory
	user.body_accessory = null
	user.update_tail_layer()
	time_till_reveal = addtimer(CALLBACK(src, PROC_REF(forceful_unhide), user), 20 MINUTES, TIMER_STOPPABLE)
	COOLDOWN_START(src, time_till_tail, 3 MINUTES)

/datum/action/innate/hide_accessory/wing
	name = "Hide wings"
	desc = "Hide your wings under your suit!"
	button_icon_state = "wing"

/datum/action/innate/hide_accessory/wing/Activate()
	. = ..()
	var/mob/living/carbon/human/user = owner
	if(!. || !user.wing)
		return

	to_chat(user, "You hide your wings.")
	hidden_accessory = user.wing
	user.wing = null
	body_accessory_hidden = user.body_accessory
	user.body_accessory = null
	user.update_wing_layer()
	time_till_reveal = addtimer(CALLBACK(PROC_REF(forceful_unhide)), 20 MINUTES, TIMER_STOPPABLE)
	COOLDOWN_START(src, time_till_tail, 3 MINUTES)

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
