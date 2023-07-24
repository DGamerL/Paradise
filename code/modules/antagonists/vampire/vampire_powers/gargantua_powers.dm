#define ARENA_SIZE 3

/obj/effect/proc_holder/spell/vampire/self/blood_swell
	name = "Blood Swell (30)"
	desc = "You infuse your body with blood, making you highly resistant to stuns and physical damage. However, this makes you unable to fire ranged weapons while it is active."
	gain_desc = "You have gained the ability to temporarly resist large amounts of stuns and physical damage."
	base_cooldown = 40 SECONDS
	required_blood = 30
	action_icon_state = "blood_swell"

/obj/effect/proc_holder/spell/vampire/self/blood_swell/cast(list/targets, mob/user)
	var/mob/living/target = targets[1]
	if(ishuman(target))
		var/mob/living/carbon/human/H = target
		H.apply_status_effect(STATUS_EFFECT_BLOOD_SWELL)

/obj/effect/proc_holder/spell/vampire/self/stomp
	name = "Seismic Stomp (30)"
	desc = "You slam your foot into the ground sending a powerful shockwave through the station's hull, sending people flying away. Cannot be cast if you legs are impared by a bola or similar."
	gain_desc = "You have gained the ability to knock people back using a powerful stomp."
	action_icon_state = "seismic_stomp"
	base_cooldown = 60 SECONDS
	required_blood = 30
	var/max_range = 4

/obj/effect/proc_holder/spell/vampire/self/stomp/can_cast(mob/living/carbon/user, charge_check, show_message)
	if(user.legcuffed)
		return FALSE
	return ..()

/obj/effect/proc_holder/spell/vampire/self/stomp/cast(list/targets, mob/user)
	var/turf/T = get_turf(user)
	playsound(T, 'sound/effects/meteorimpact.ogg', 100, TRUE)
	addtimer(CALLBACK(src, PROC_REF(hit_check), 1, T, user), 0.2 SECONDS)
	new /obj/effect/temp_visual/stomp(T)

/obj/effect/proc_holder/spell/vampire/self/stomp/proc/hit_check(range, turf/start_turf, mob/user, safe_targets = list())
	// gets the two outermost turfs in a ring, we get two so people cannot "walk over" the shockwave
	var/list/targets = view(range, start_turf) - view(range - 2, start_turf)
	for(var/turf/simulated/floor/flooring in targets)
		if(prob(100 - (range * 20)))
			flooring.ex_act(EXPLODE_LIGHT)

	for(var/mob/living/L in targets)
		if(L in safe_targets)
			continue
		if(L.throwing) // no double hits
			continue
		if(!L.affects_vampire(user))
			continue
		if(L.move_resist > MOVE_FORCE_VERY_STRONG)
			continue
		var/throw_target = get_edge_target_turf(L, get_dir(start_turf, L))
		INVOKE_ASYNC(L, TYPE_PROC_REF(/atom/movable, throw_at), throw_target, 3, 4)
		L.KnockDown(1 SECONDS)
		safe_targets += L
	var/new_range = range + 1
	if(new_range <= max_range)
		addtimer(CALLBACK(src, PROC_REF(hit_check), new_range, start_turf, user, safe_targets), 0.2 SECONDS)

/obj/effect/temp_visual/stomp
	icon = 'icons/effects/seismic_stomp_effect.dmi'
	icon_state = "stomp_effect"
	duration = 0.8 SECONDS
	pixel_y = -16
	pixel_x = -16

/obj/effect/temp_visual/stomp/Initialize(mapload)
	. = ..()
	var/matrix/M = matrix() * 0.5
	transform = M
	animate(src, transform = M * 8, time = duration, alpha = 0)

/datum/vampire_passive/blood_swell_upgrade
	gain_desc = "While blood swell is active all of your melee attacks deal increased damage."

/obj/effect/proc_holder/spell/vampire/self/overwhelming_force
	name = "Overwhelming Force"
	desc = "When toggled you will automatically pry open doors that you bump into if you do not have access."
	gain_desc = "You have gained the ability to force open doors at a small blood cost."
	base_cooldown = 2 SECONDS
	action_icon_state = "OH_YEAAAAH"

/obj/effect/proc_holder/spell/vampire/self/overwhelming_force/cast(list/targets, mob/user)
	if(!HAS_TRAIT_FROM(user, TRAIT_FORCE_DOORS, VAMPIRE_TRAIT))
		to_chat(user, "<span class='warning'>You feel MIGHTY!</span>")
		ADD_TRAIT(user, TRAIT_FORCE_DOORS, VAMPIRE_TRAIT)
		user.status_flags &= ~CANPUSH
		user.move_resist = MOVE_FORCE_STRONG
	else
		REMOVE_TRAIT(user, TRAIT_FORCE_DOORS, VAMPIRE_TRAIT)
		user.move_resist = MOVE_FORCE_DEFAULT
		user.status_flags |= CANPUSH

/obj/effect/proc_holder/spell/vampire/self/blood_rush
	name = "Blood Rush (30)"
	desc = "Infuse yourself with blood magic to boost your movement speed."
	gain_desc = "You have gained the ability to temporarily move at high speeds."
	base_cooldown = 30 SECONDS
	required_blood = 30
	action_icon_state = "blood_rush"

/obj/effect/proc_holder/spell/vampire/self/blood_rush/cast(list/targets, mob/user)
	var/mob/living/target = targets[1]
	if(ishuman(target))
		var/mob/living/carbon/human/H = target
		to_chat(H, "<span class='notice'>You feel a rush of energy!</span>")
		H.apply_status_effect(STATUS_EFFECT_BLOOD_RUSH)

/obj/effect/proc_holder/spell/fireball/demonic_grasp
	name = "Demonic Grasp (20)"
	desc = "Fire a hand of demonic energy, snaring and throwing its target around, based on your intent. Disarm pushes, grab pulls."
	gain_desc = "You have gained the ability to snare and disrupt people with demonic apendages."
	base_cooldown = 30 SECONDS
	fireball_type = /obj/item/projectile/magic/demonic_grasp

	selection_activated_message		= "<span class='notice'>You raise your hand, full of demonic energy! <B>Left-click to cast at a target!</B></span>"
	selection_deactivated_message	= "<span class='notice'>You re-absorb the energy...for now.</span>"

	action_icon_state = "demonic_grasp"

	panel = "Vampire"
	school = "vampire"
	action_background_icon_state = "bg_vampire"
	sound = null
	invocation_type = "none"
	invocation = null

/obj/effect/proc_holder/spell/fireball/demonic_grasp/update_icon_state()
	return

/obj/effect/proc_holder/spell/fireball/demonic_grasp/create_new_handler()
	var/datum/spell_handler/vampire/V = new()
	V.required_blood = 20
	return V

/obj/item/projectile/magic/demonic_grasp
	name = "demonic grasp"
	// parry this you filthy casual
	reflectability = REFLECTABILITY_NEVER
	icon_state = null

/obj/item/projectile/magic/demonic_grasp/pixel_move(trajectory_multiplier)
	. = ..()
	new /obj/effect/temp_visual/demonic_grasp(loc)

/obj/item/projectile/magic/demonic_grasp/on_hit(atom/target, blocked, hit_zone)
	. = ..()
	if(!isliving(target))
		return
	var/mob/living/L = target
	L.Immobilize(1 SECONDS)
	var/throw_target
	if(!firer)
		return

	if(!L.affects_vampire(firer))
		return

	new /obj/effect/temp_visual/demonic_grasp(loc)

	switch(firer.a_intent)
		if(INTENT_DISARM)
			throw_target = get_edge_target_turf(L, get_dir(firer, L))
			L.throw_at(throw_target, 2, 5, spin = FALSE, callback = CALLBACK(src, PROC_REF(create_snare), L)) // shove away
		if(INTENT_GRAB)
			throw_target = get_step(firer, get_dir(firer, L))
			L.throw_at(throw_target, 2, 5, spin = FALSE, diagonals_first = TRUE, callback = CALLBACK(src, PROC_REF(create_snare), L)) // pull towards

/obj/item/projectile/magic/demonic_grasp/proc/create_snare(mob/target)
	new /obj/effect/temp_visual/demonic_snare(target.loc)

/obj/effect/temp_visual/demonic_grasp
	icon = 'icons/effects/vampire_effects.dmi'
	icon_state = "demonic_grasp"
	duration = 3.5 SECONDS

/obj/effect/temp_visual/demonic_snare
	icon = 'icons/effects/vampire_effects.dmi'
	icon_state = "immobilized"
	duration = 1 SECONDS

/obj/effect/proc_holder/spell/vampire/self/arena
	name = "Challenging Arena"
	desc = "You charge at wherever you click on screen, dealing large amounts of damage, stunning and destroying walls and other objects."
	gain_desc = "You can now charge at a target on screen, dealing massive damage and destroying structures."
	required_blood = 30
	base_cooldown = 30 SECONDS
	action_icon_state = "vampire_charge"
	/// The garg vampire
	var/mob/mychild
	/// List of people who tried to interfere in the glorious fight
	var/list/invaders = list()
	/// List of the people who have to fight in the arena
	var/list/enemy_targets = list()
	/// Is our spell active?
	var/spell_active
	/// What turf will be the middle of our arena?
	var/turf/the_middle_ground

/obj/effect/proc_holder/spell/vampire/self/arena/cast(list/targets, mob/user)
	if(!targets)
		return
	enemy_targets = targets // In case we need to use it in another proc
	the_middle_ground = get_turf(user) // I am so deeply sorry to get a hard ref to a turf
	mychild = user
	make_activator(targets)
	spell_active = TRUE
	arena_checks()

/obj/effect/proc_holder/spell/vampire/self/arena/proc/arena_checks()
	if(spell_active == FALSE || QDELETED(src))
		return
	INVOKE_ASYNC(src, PROC_REF(fighters_check))  //Checks to see if our fighters died.
	INVOKE_ASYNC(src, PROC_REF(arena_trap))  //Gets another arena trap queued up for when this one runs out.
	INVOKE_ASYNC(src, PROC_REF(border_check))  //Checks to see if our fighters got out of the arena somehow.
	addtimer(CALLBACK(src, PROC_REF(arena_checks)), 5 SECONDS)

/obj/effect/proc_holder/spell/vampire/self/arena/proc/make_activator(list/targets)
	if(!targets)
		return // Sanity check
	var/list/temporary_list = targets
	for(var/i in 1 to length(targets))
		var/mob/apply_challenger = temporary_list[1]
		ADD_TRAIT(apply_challenger, TRAIT_ELITE_CHALLENGER, "activation")
		temporary_list.Cut(1,2)
	RegisterSignal(mychild, COMSIG_PARENT_QDELETING, PROC_REF(clear_activator))

/obj/effect/proc_holder/spell/vampire/self/arena/proc/arena_trap()
	for(var/tumor_range_turfs in RANGE_EDGE_TURFS(ARENA_SIZE, the_middle_ground))
		new /obj/effect/temp_visual/elite_tumor_wall(tumor_range_turfs, src)

/obj/effect/proc_holder/spell/vampire/self/arena/proc/border_check()
	var/list/temporary_targets = enemy_targets
	var/how_many_targets = length(enemy_targets) // We gotta get this in a var first because otherwise it'll stop working halfway through
	for(var/j in 1 to how_many_targets)
		var/mob/activator = temporary_targets[1]
		if(activator != null && get_dist(src, activator) >= ARENA_SIZE)
			activator.forceMove(loc)
			visible_message("<span class='warning'>[activator] suddenly reappears above [src]!</span>")
			playsound(loc,'sound/effects/phasein.ogg', 200, 0, 50, TRUE, TRUE)
		if(mychild != null && get_dist(src, mychild) >= ARENA_SIZE)
			mychild.forceMove(loc)
			visible_message("<span class='warning'>[mychild] suddenly reappears above [src]!</span>")
			playsound(loc,'sound/effects/phasein.ogg', 200, 0, 50, TRUE, TRUE)
		temporary_targets.Cut(1,2)

/obj/effect/proc_holder/spell/vampire/self/arena/HasProximity(atom/movable/AM)
	if(!ishuman(AM) && !isrobot(AM))
		return
	var/mob/living/M = AM
	if(M in enemy_targets)
		return
	if(M in invaders)
		to_chat(M, "<span class='colossus'><b>You dare to try to break the sanctity of our arena? SUFFER...</b></span>")
		for(var/i in 1 to 4)
			M.apply_status_effect(STATUS_EFFECT_VOID_PRICE) /// Hey kids, want 60 brute damage, increased by 40 each time you do it? Well, here you go!
	else
		to_chat(M, "<span class='userdanger'>Only spectators are allowed, while the arena is in combat...</span>")
		invaders += M
	var/list/valid_turfs = RANGE_EDGE_TURFS(ARENA_SIZE + 2, src) // extra safety
	M.forceMove(pick(valid_turfs)) //Doesn't check for lava. Don't cheese it.
	playsound(M, 'sound/effects/phasein.ogg', 200, 0, 50, TRUE, TRUE)

/obj/effect/proc_holder/spell/vampire/self/arena/proc/fighters_check()
	if(QDELETED(mychild) || mychild.stat == DEAD)
		onEliteLoss()
		return

/obj/effect/proc_holder/spell/vampire/self/arena/proc/clear_activator(mob/source)
	SIGNAL_HANDLER
	REMOVE_TRAIT(source, TRAIT_ELITE_CHALLENGER, "clear activation")
	UnregisterSignal(source, COMSIG_PARENT_QDELETING)

/obj/effect/proc_holder/spell/vampire/self/arena/proc/onEliteLoss()
	spell_active = FALSE
	visible_message("<span class='warning'>[src] begins to convulse violently before falling lifeless to the ground.</span>")
	visible_message("<span class='warning'>The arena begins to slowly dissipate.</span>")
