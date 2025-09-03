#define CLOTHINGFAB_MAIN_MENU		1
#define CLOTHINGFAB_CATEGORY_MENU	2
#define CLOTHINGFAB_SEARCH_MENU		3

/obj/machinery/clothing_fabricator
	name = "clothing fabricator"
	desc = "A complex textile mill contained within the shell of a vendor. Used for creating all types of clothing."
	icon_state = "clothing_fab"
	density = TRUE
	anchored = TRUE
	idle_power_consumption = 10
	active_power_consumption = 100

	var/list/queue = list()
	var/queue_max_len = 12
	var/turf/BuildTurf

	var/hacked = FALSE
	var/disabled = FALSE
	var/shocked = FALSE
	var/hack_wire
	var/disable_wire
	var/shock_wire

	var/busy = FALSE
	var/prod_coeff
	var/datum/wires/clothing_fabricator/wires = null

	var/list/being_built = list()
	var/list/datum/design/matching_designs
	var/temp_search
	var/selected_category
	var/list/recipiecache = list()

	var/list/categories = list("Hats", "Masks", "Neckwear", "Uniforms", "Oversuits", "Gloves", "Shoes", "Accessories")
	var/board_type = /obj/item/circuitboard/clothing_fabricator

/obj/machinery/clothing_fabricator/Initialize(mapload)
	. = ..()
	AddComponent()
	component_parts = list()
	component_parts += new board_type(null)
	component_parts += new /obj/item/stock_parts/matter_bin(null)
	component_parts += new /obj/item/stock_parts/matter_bin(null)
	component_parts += new /obj/item/stock_parts/manipulator(null)
	component_parts += new /obj/item/stock_parts/manipulator(null)
	component_parts += new /obj/item/stack/sheet/glass(null)
	RefreshParts()

/obj/machinery/clothing_fabricator/interact(mob/user)
	if(shocked && !(stat & NOPOWER))
		if(shock(user, 50))
			return

	if(panel_open)
		wires.Interact(user)
	else if(!disabled)
		ui_interact(user)

/obj/machinery/clothing_fabricator/ui_state(mob/user)
	return GLOB.default_state

/obj/machinery/clothing_fabricator/ui_interact(mob/user, datum/tgui/ui = null)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "Clothing Fabricator", name)
		ui.open()


/obj/machinery/clothing_fabricator/ui_static_data(mob/user)
	var/list/data = list()
	data["categories"] = categories
	if(!length(recipiecache))
		var/list/recipes = list()
		for(var/v in files.known_designs)
			var/datum/design/D = files.known_designs[v]
			var/list/cost_list = design_cost_data(D)
			var/list/matreq = list()
			for(var/list/x in cost_list)
				if(!x["amount"])
					continue
				if(x["name"] == "cotton") // Do not use MAT_METAL or MAT_GLASS here.
					matreq["cotton"] = x["amount"]
				if(x["name"] == "durathread")
					matreq["durathread"] = x["amount"]
			var/obj/item/I = D.build_path
			var/maxmult = 1
			if(ispath(D.build_path, /obj/item/stack))
				maxmult = D.maxstack

			var/list/default_categories = D.category
			var/list/categories = istype(default_categories) ? default_categories.Copy() : list()

			recipes.Add(list(list(
				"name" = D.name,
				"category" = categories,
				"uid" = D.UID(),
				"requirements" =  matreq,
				"hacked" = ("hacked" in categories) ? TRUE : FALSE,
				"max_multiplier" = maxmult,
				"image" = "[icon2base64(icon(initial(I.icon), initial(I.icon_state), SOUTH, 1))]"
			)))
		recipiecache = recipes
	data["recipes"] = recipiecache
	return data


