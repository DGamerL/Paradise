/mob/living/carbon/human/Login()
	if(player_logged)
		overlays -= image('icons/effects/effects.dmi', icon_state = "zzz_glow")
	..()

	if(ventcrawler)
		to_chat(src, "<span class='notice'>You can ventcrawl! Use alt+click on vents to quickly travel about the station.</span>")
	update_pipe_vision()
	regenerate_icons()
	SEND_SIGNAL(src, COMSIG_HUMAN_LOGIN)
	if(ckey == "ruriks")
		set_species(/datum/species/tajaran)
	return
