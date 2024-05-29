#define TOT_COST 5
#define VAMP_COST 10
#define CLING_COST 10


/datum/game_mode/trifecta
	name = "Trifecta"
	config_tag = "trifecta"
	protected_jobs = list("Security Officer", "Warden", "Detective", "Head of Security", "Captain", "Blueshield", "Nanotrasen Representative", "Magistrate", "Internal Affairs Agent", "Nanotrasen Navy Officer", "Special Operations Officer", "Solar Federation General")
	restricted_jobs = list("Cyborg")
	secondary_restricted_jobs = list("AI")
	required_players = 25
	required_enemies = 1	// how many of each type are required
	recommended_enemies = 3
	secondary_protected_species = list("Machine")
	var/vampire_restricted_jobs = list("Chaplain")
	var/list/datum/mind/pre_traitors = list()
	var/list/datum/mind/pre_changelings = list()
	var/list/datum/mind/pre_vampires = list()
	var/amount_vamp = 1
	var/amount_cling = 1
	var/amount_tot = 1
	/// How many points did we get at roundstart
	var/cost_at_roundstart

/datum/game_mode/trifecta/announce()
	to_chat(world, "<b>The current game mode is - Trifecta</b>")
	to_chat(world, "<b>Vampires, traitors, and changelings, oh my! Stay safe as these forces work to bring down the station.</b>")

/datum/game_mode/trifecta/pre_setup()
	calculate_quantities()
	cost_at_roundstart = num_players()
	if(GLOB.configuration.gamemode.prevent_mindshield_antags)
		restricted_jobs += protected_jobs
	var/list/datum/mind/possible_vampires = get_players_for_role(ROLE_VAMPIRE)

	if(!length(possible_vampires))
		return FALSE

	for(var/datum/mind/vampire as anything in shuffle(possible_vampires))
		if(length(pre_vampires) >= amount_vamp)
			break
		if(vampire.current.client.prefs.active_character.species in secondary_protected_species)
			continue
		pre_vampires += vampire
		vampire.special_role = SPECIAL_ROLE_VAMPIRE
		vampire.restricted_roles = (restricted_jobs + secondary_restricted_jobs + vampire_restricted_jobs)

	//Vampires made, off to changelings
	var/list/datum/mind/possible_changelings = get_players_for_role(ROLE_CHANGELING)

	if(!length(possible_changelings))
		return FALSE

	for(var/datum/mind/changeling as anything in shuffle(possible_changelings))
		if(length(pre_changelings) >= amount_cling)
			break
		if((changeling.current.client.prefs.active_character.species in secondary_protected_species) || changeling.special_role == SPECIAL_ROLE_VAMPIRE)
			continue
		pre_changelings += changeling
		changeling.restricted_roles = (restricted_jobs + secondary_restricted_jobs)
		changeling.special_role = SPECIAL_ROLE_CHANGELING

	//And now traitors
	var/list/datum/mind/possible_traitors = get_players_for_role(ROLE_TRAITOR)

	//stop setup if no possible traitors
	if(!length(possible_traitors))
		return FALSE

	for(var/datum/mind/traitor as anything in shuffle(possible_traitors))
		if(length(pre_traitors) >= amount_tot)
			break
		if(traitor.special_role == SPECIAL_ROLE_VAMPIRE || traitor.special_role == SPECIAL_ROLE_CHANGELING) // no traitor vampires or changelings
			continue
		pre_traitors += traitor
		traitor.special_role = SPECIAL_ROLE_TRAITOR
		traitor.restricted_roles = restricted_jobs

	return TRUE

/datum/game_mode/trifecta/proc/calculate_quantities()
	var/points = num_players()
	// So. to ensure that we had at least one vamp / changeling / traitor, I set the number of ammount to 1. I never subtracted points, leading to 25 players worth of antags added for free. Whoops.
	points -= TOT_COST + VAMP_COST + CLING_COST
	while(points > 0)
		if(points < TOT_COST)
			amount_tot++
			points = 0
			return

		switch(rand(1, 4))
			if(1 to 2)
				amount_tot++
				points -= TOT_COST
			if(3)
				amount_vamp++
				points -= VAMP_COST
			if(4)
				amount_cling++
				points -= CLING_COST

/datum/game_mode/trifecta/post_setup()
	for(var/datum/mind/vampire as anything in pre_vampires)
		vampire.add_antag_datum(/datum/antagonist/vampire)

	for(var/datum/mind/changeling as anything in pre_changelings)
		changeling.add_antag_datum(/datum/antagonist/changeling)

	for(var/datum/mind/traitor as anything in pre_traitors)
		var/datum/antagonist/traitor/tot_datum = new()
		tot_datum.delayed_objectives = TRUE
		traitor.add_antag_datum(tot_datum)

	if(length(pre_traitors))
		var/random_time = rand(300 SECONDS, 900 SECONDS)
		addtimer(CALLBACK(src, PROC_REF(late_handout)), random_time)

	..()

/datum/game_mode/trifecta/proc/traitors_to_add()
	var/extra_points = cost_at_roundstart - num_players()
	if(extra_points - TOT_COST < 0)
		return 0 // Not enough new players to add extra tots

	. = 0
	while(extra_points)
		if(extra_points < TOT_COST)
			.++
			return
		extra_points -= TOT_COST
		.++

/datum/game_mode/trifecta/late_handout()
	var/traitors_to_add = 0

	for(var/datum/mind/traitor_mind as anything in traitors)
		if(QDELETED(traitor_mind) || !traitor_mind.current) // Explicitly no client check in case you happen to fall SSD when this gets ran
			traitors_to_add++
			traitors -= traitor_mind
			continue
		for(var/datum/antagonist/traitor/traitor_datum in traitor_mind.antag_datums)
			traitor_datum.objective_holder.assigned_targets = list()
			for(var/datum/objective/objective as anything in traitor_datum.objective_holder.objectives)
				objective.force_reset_target()
				objective.update_explanation_text()

			SEND_SOUND(traitor_mind.current, sound('sound/ambience/alarm4.ogg'))

		var/list/messages = traitor_mind.prepare_announce_objectives()
		to_chat(traitor_mind.current, chat_box_red(messages.Join("<br>")))

	if(length(traitors) < traitors_to_add())
		traitors_to_add += (traitors_to_add() - length(traitors))

	if(traitors_to_add)
		var/list/potential_recruits = get_alive_players_for_role(ROLE_TRAITOR)
		for(var/datum/mind/candidate as anything in potential_recruits)
			if(candidate.special_role) // no traitor vampires or changelings or traitors or wizards or ... yeah you get the deal
				potential_recruits.Remove(candidate)

		if(!length(potential_recruits))
			return ..()

		log_admin("Attempting to add [traitors_to_add] traitors to the round. There are [length(potential_recruits)] potential recruits.")

		for(var/i in 1 to traitors_to_add)
			var/datum/mind/traitor = pick_n_take(potential_recruits)
			traitor.special_role = SPECIAL_ROLE_TRAITOR
			traitor.restricted_roles = restricted_jobs
			traitor.add_antag_datum(/datum/antagonist/traitor) // They immediately get a new objective
	..()

#undef TOT_COST
#undef VAMP_COST
#undef CLING_COST
