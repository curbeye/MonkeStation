/turf
	var/obj/effect/abstract/liquid_turf/liquids
	var/liquid_height = 0
	var/turf_height = 0

/turf/proc/reasses_liquids()
	if(!liquids)
		return
	if(!liquids.liquid_group)
		liquids.liquid_group = new(1, liquids)
	SSliquids.add_active_turf(src)

/turf/proc/liquid_update_turf()
	if(!liquids)
		return
	//Check atmos adjacency to cut off any disconnected groups
	if(liquids.liquid_group)
		var/assoc_atmos_turfs = list()
		for(var/tur in GetAtmosAdjacentTurfs())
			assoc_atmos_turfs[tur] = TRUE
		//Check any cardinals that may have a matching group
		for(var/direction in GLOB.cardinals)
			var/turf/T = get_step(src, direction)
			if(!T.liquids)
				return

	SSliquids.add_active_turf(src)

/turf/proc/add_liquid_from_reagents(datum/reagents/giver, no_react = FALSE)
	var/list/compiled_list = list()
	for(var/r in giver.reagent_list)
		var/datum/reagent/R = r
		if(!(R.type in GLOB.liquid_blacklist))
			compiled_list[R.type] = R.volume
	if(!compiled_list.len) //No reagents to add, don't bother going further
		return
	if(!liquids)
		liquids = new(src)
	liquids.liquid_group.add_reagents(liquids, compiled_list)

//More efficient than add_liquid for multiples
/turf/proc/add_liquid_list(reagent_list, no_react = FALSE, chem_temp)
	if(!liquids)
		liquids = new(src)
	liquids.liquid_group.add_reagents(liquids, reagent_list, chem_temp)
	//Expose turf
	liquids.liquid_group.expose_members_turf(liquids)

/turf/proc/add_liquid(reagent, amount, no_react = FALSE, chem_temp = 300)
	if(reagent in GLOB.liquid_blacklist)
		return
	if(!liquids)
		liquids = new(src)

	liquids.liquid_group.add_reagent(liquids, reagent, amount)
	//Expose turf
	liquids.liquid_group.expose_members_turf(liquids)

/turf/proc/process_liquid_cell()

	if(liquids)
		var/turf/open/temp_turf = get_turf(src)
		var/datum/gas_mixture/gas = temp_turf.air
		if(gas)
			if(gas.return_temperature() > liquids.liquid_group.group_temperature)
				var/increaser =((gas.return_temperature() * gas.total_moles()) + (liquids.liquid_group.group_temperature * liquids.liquid_group.total_reagent_volume)) / (2 + liquids.liquid_group.total_reagent_volume + gas.total_moles())
				if(increaser > liquids.liquid_group.group_temperature + 3)
					gas.set_temperature(increaser)
					liquids.liquid_group.group_temperature = increaser
					gas.react()
			else if(liquids.liquid_group.group_temperature > gas.return_temperature())
				var/increaser =((gas.return_temperature() * gas.total_moles()) + (liquids.liquid_group.group_temperature * liquids.liquid_group.total_reagent_volume)) / (2 + liquids.liquid_group.total_reagent_volume + gas.total_moles())
				if(increaser > gas.return_temperature() + 3)
					liquids.liquid_group.group_temperature = increaser
					gas.set_temperature(increaser)
					gas.react()

	if(!liquids)
		SSliquids.remove_active_turf(src)
		return
	if(QDELETED(liquids)) //Liquids may be deleted in process cell
		SSliquids.remove_active_turf(src)
		return
