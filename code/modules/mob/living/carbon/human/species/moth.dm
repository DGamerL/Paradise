#define FLYSWATTER_DAMAGE_MULTIPLIER 9

/datum/species/moth
	name = "Nian"
	name_plural = "Nianae"
	language = "Tkachi"
	icobase = 'icons/mob/human_races/r_moth.dmi'
	inherent_factions = list("nian")
	species_traits = list(NO_HAIR)
	inherent_biotypes = MOB_ORGANIC | MOB_HUMANOID | MOB_BUG
	clothing_flags = HAS_UNDERWEAR | HAS_UNDERSHIRT | HAS_SOCKS
	bodyflags = HAS_HEAD_ACCESSORY | HAS_HEAD_MARKINGS | HAS_BODY_MARKINGS | HAS_WING | BALD | SHAVED
	reagent_tag = PROCESS_ORG
	dietflags = DIET_HERB
	tox_mod = 1.5
	blood_color = "#b9ae9c"
	unarmed_type = /datum/unarmed_attack/claws
	scream_verb = "buzzes"
	male_scream_sound = 'sound/voice/scream_moth.ogg'
	female_scream_sound = 'sound/voice/scream_moth.ogg'
	default_headacc = "Plain Antennae"
	default_bodyacc = "Plain Wings"
	wing = "plain"
	eyes = "moth_eyes_s"
	butt_sprite = "nian"
	siemens_coeff = 1.5
	blurb = "Nians are large bipedal invertebrates that come from an unknown homeworld. \
	Known for spendthrift behavior, the Nian civilization has been pressed to the fore of developed space in an effort to resolve material shortages in homeworld sectors.<br/><br/> \
	Unlike most species in the galactic fold, Nian do not recognize the authority of the Trans-Solar Federation: \
	having instead established close diplomatic relationships with their splinter faction, the USSP."

	has_organ = list(
		"heart" =    /obj/item/organ/internal/heart/nian,
		"lungs" =    /obj/item/organ/internal/lungs/nian,
		"liver" =    /obj/item/organ/internal/liver/nian,
		"kidneys" =  /obj/item/organ/internal/kidneys/nian,
		"brain" =    /obj/item/organ/internal/brain/nian,
		"eyes" =     /obj/item/organ/internal/eyes/nian
	)

	optional_body_accessory = FALSE

	suicide_messages = list(
		"is attempting to nibble their antenna off!",
		"is twisting their own abdomen!",
		"is cracking their exoskeleton!",
		"is ripping their wings off!",
		"is holding their breath!"
	)


/datum/species/moth/on_species_gain(mob/living/carbon/human/H)
	..()
	var/datum/action/innate/cocoon/cocoon = new()
	cocoon.Grant(H)
	RegisterSignal(H, COMSIG_LIVING_FIRE_TICK, PROC_REF(check_burn_wings))
	RegisterSignal(H, COMSIG_LIVING_AHEAL, PROC_REF(on_aheal))
	RegisterSignal(H, COMSIG_HUMAN_CHANGE_BODY_ACCESSORY, PROC_REF(on_change_body_accessory))
	RegisterSignal(H, COMSIG_HUMAN_CHANGE_HEAD_ACCESSORY, PROC_REF(on_change_head_accessory))

/datum/species/moth/on_species_loss(mob/living/carbon/human/H)
	..()
	for(var/datum/action/innate/cocoon/cocoon in H.actions)
		cocoon.Remove(H)
	UnregisterSignal(H, COMSIG_LIVING_FIRE_TICK)
	UnregisterSignal(H, COMSIG_LIVING_AHEAL)
	UnregisterSignal(H, COMSIG_HUMAN_CHANGE_BODY_ACCESSORY)
	UnregisterSignal(H, COMSIG_HUMAN_CHANGE_HEAD_ACCESSORY)
	H.remove_status_effect(STATUS_EFFECT_BURNT_WINGS)

/datum/species/moth/handle_reagents(mob/living/carbon/human/H, datum/reagent/R)
	if(R.id == "pestkiller")
		H.adjustToxLoss(3)
		H.reagents.remove_reagent(R.id, REAGENTS_METABOLISM)
		return TRUE

	return ..()

/datum/species/moth/get_species_runechat_color(mob/living/carbon/human/H)
	return H.m_colours["body"]

/datum/species/moth/spec_attacked_by(obj/item/I, mob/living/user, obj/item/organ/external/affecting, intent, mob/living/carbon/human/H)
	if(istype(I, /obj/item/melee/flyswatter) && I.force)
		apply_damage(I.force * FLYSWATTER_DAMAGE_MULTIPLIER, I.damtype, affecting, FALSE, H) //making flyswatters do 10x damage to moff

/datum/species/moth/spec_Process_Spacemove(mob/living/carbon/human/H)
	var/turf/A = get_turf(H)
	if(isspaceturf(A))
		return FALSE
	if(H.has_status_effect(STATUS_EFFECT_BURNT_WINGS))
		return FALSE
	var/datum/gas_mixture/current = A.return_air()
	if(current && (current.return_pressure() >= ONE_ATMOSPHERE*0.85)) //as long as there's reasonable pressure and no gravity, flight is possible
		return TRUE

/datum/species/moth/spec_thunk(mob/living/carbon/human/H)
	if(!H.has_status_effect(STATUS_EFFECT_BURNT_WINGS))
		return TRUE

/datum/species/moth/spec_movement_delay()
	return FALSE

/datum/species/moth/spec_WakeUp(mob/living/carbon/human/H)
	if(H.has_status_effect(STATUS_EFFECT_COCOONED))
		return TRUE //Cocooned mobs dont get to wake up

/datum/species/moth/proc/check_burn_wings(mob/living/carbon/human/H) //do not go into the extremely hot light. you will not survive
	SIGNAL_HANDLER
	if(H.on_fire && !H.has_status_effect(STATUS_EFFECT_BURNT_WINGS) && H.bodytemperature >= 400 && H.fire_stacks > 0)
		to_chat(H, "<span class='warning'>Your precious wings burn to a crisp!</span>")
		H.apply_status_effect(STATUS_EFFECT_BURNT_WINGS)

/datum/species/moth/proc/on_aheal(mob/living/carbon/human/H)
	SIGNAL_HANDLER
	H.remove_status_effect(STATUS_EFFECT_BURNT_WINGS)

/datum/species/moth/proc/on_change_body_accessory(mob/living/carbon/human/H)
	SIGNAL_HANDLER
	if(H.has_status_effect(STATUS_EFFECT_BURNT_WINGS))
		return COMSIG_HUMAN_NO_CHANGE_APPEARANCE

/datum/species/moth/proc/on_change_head_accessory(mob/living/carbon/human/H)
	SIGNAL_HANDLER
	if(H.has_status_effect(STATUS_EFFECT_BURNT_WINGS))
		return COMSIG_HUMAN_NO_CHANGE_APPEARANCE

/datum/status_effect/burnt_wings
	id = "burnt_wings"
	alert_type = null

/datum/status_effect/burnt_wings/on_creation(mob/living/new_owner, ...)
	var/mob/living/carbon/human/H = new_owner
	if(istype(H))
		H.change_body_accessory("Burnt Off Wings")
		H.change_head_accessory("Burnt Off Antennae")
	return ..()

/datum/status_effect/burnt_wings/on_remove()
	owner.UpdateAppearance()
	return ..()

/datum/status_effect/cocooned
	id = "cocooned"
	alert_type = null

#undef FLYSWATTER_DAMAGE_MULTIPLIER
