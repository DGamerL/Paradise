SUBSYSTEM_DEF(title)
	name = "Title Screen"
	flags = SS_NO_FIRE
	init_order = INIT_ORDER_TITLE

/datum/controller/subsystem/title/Initialize()
	// List of all possible iconstates
	var/list/all_screens = icon_states('config/title_screens/images/screens.dmi')

	var/file_path = 'config/title_screens/images/default.dmi'

	var/final_state = pick(all_screens)
	if(final_state) // Failsave
		file_path = 'config/title_screens/images/screens.dmi'

	var/icon/icon = new(fcopy_rsc(file_path))

	GLOB.title_splash.icon = icon
	GLOB.title_splash.icon_state = final_state
	if(final_state != "default")
		var/list/author = splittext(final_state, "_")
		GLOB.title_splash.name = "Made by: [author[length(author) > 1 ? 2 : 1]]

	// Below operations are needed to centrally place the new splashscreen on the lobby area
	GLOB.title_splash.pixel_x = -((icon.Width() - world.icon_size) / 2)
	GLOB.title_splash.pixel_y = -((icon.Height() - world.icon_size) / 2)
