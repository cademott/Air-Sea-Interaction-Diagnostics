load "./Resources/contrib_AirSea.ncl"
  
;------------------------------------------------------------------------
begin
                           
	print(" ")
	print("================ in make_L1.5_stdev_map.ncl =================")

	;----------- suppress warnings?
	debug		= getenv("DEBUG")
	if (debug.eq."false") then
		err = NhlGetErrorObjectId()
		setvalues err
			"errLevel" : "Fatal"          ; only report Fatal errors
		end setvalues
	end if

	;------------- set dynamic variable names
	twStrt		= getenv("YMDSTRT")
	twLast		= getenv("YMDLAST")
	dateStr		= getenv("FILESUFFSTR")
	inName		= getenv("inName")
	pName		= getenv("RAINVARNAME")
	lhName		= getenv("LHVARNAME")
	shName		= getenv("SHVARNAME")
	swName		= getenv("SWVARNAME")
	lwName		= getenv("LWVARNAME")
	qName		= getenv("QVARNAME")
	tName		= getenv("TKVARNAME")
	sstName		= getenv("SSTVARNAME")
	sfcpName	= getenv("SFCPVARNAME")

	diri		= getenv("FILEDIR") + "/"
	diro		= diri + "proc/"		
	caseName	= getenv("caseName")
	timeName	= getenv("TIMEVAR")
	latName		= getenv("LATNAME")
	lonName		= getenv("LONNAME")
	rainFstr	= getenv("RAINFACTOR")

	latSstr		= getenv("latSouth")
	latNstr		= getenv("latNorth")
	latS_globe	= stringtofloat(latSstr)
	latN_globe	= stringtofloat(latNstr)

	;----------- define latitude string
	if (latS_globe.lt.0) then
		southStr	= "S"
	else
		southStr	= "N"
	end if
	if (latN_globe.ge.0) then
		northStr	= "N"
	else
		northStr	= "S"
	end if	
	latbandStr	= abs(latS_globe) + southStr + "-" + abs(latN_globe) + northStr

	
	print("inName	= "+inName)

	;------------- define input file and variable names 
	inName1		= inName
	inFile1		= diri + caseName + "." + inName + "."+ dateStr + "." + latbandStr + ".day.background.anom.nc"

	;------------- seasons
	seasonName 	= (/ "Nov-Apr", "May-Oct" /)

	;------------- create Lanczos BandPass Filter
	ihp    = 2                          ; bpf=>band pass filter
	nWgt   = 201
	sigma  = 1.0                        ; Lanczos sigma
	fca    = 1./100.                    ; MJO clivar
	fcb    = 1./20.
	wgt    = filwgts_lanczos (nWgt, ihp, fca, fcb, sigma )

	;------------- set up time variables
	f1		= addfile(inFile1, "r")
	time	= f1->$timeName$
	date	= cd_calendar(f1->$timeName$, -2)   ; entire file
	iStrt 	= ind(date.eq.twStrt)				; desired dates
	iLast 	= ind(date.eq.twLast)
	delete(time)
	time	= f1->$timeName$(iStrt:iLast)	
	TIME    = cd_calendar(time, 0)				; type float 
	year    = floattointeger( TIME(:,0) )
	month   = floattointeger( TIME(:,1) )
	day     = floattointeger( TIME(:,2) ) 
			
	;----------- read in dataj
	tName		= inName1+"_anom_sm"
	data_anom	= f1->$tName$($timeName$|iStrt:iLast,{$latName$|latS_globe:latN_globe},$lonName$|:)		

	;----------- check precipitation units
	if (inName1.eq.pName) then
		rainfact		=stringtofloat(rainFstr)
		print("rain factor = " + rainfact)
		data_anom		= data_anom * rainfact
		data_anom@units = "mm/day"
	end if
	
	

	do s = 0,1 						; do for each season
	
		;----------- define seasons
		if (s.eq.0) then
			season		= ind(month.ge.11.or.month.le.4)	; Nov-Apr
		else
			season		= ind(month.ge.5.and.month.le.10)	; May-Oct
		end if
		
		;----------- compute seasonal mean, 20-100 day stdev, and equivalent sample size
		DATA_ess_nofilt			= equiv_sample_size(data_anom($latName$|:,$lonName$|:,$timeName$|season),0.05,0)
		data_anom				= wgt_runave_leftdim( data_anom, wgt, 0 )	; apply filter
		DATA_season_stdev		= dim_stddev_n_Wrap(data_anom(season,:,:),0)
		DATA_ess_filt			= equiv_sample_size(data_anom($latName$|:,$lonName$|:,$timeName$|season),0.05,0)

		;----------- apply uniform variable naming conventions
		outvarName		= inName1
		if (inName.eq.swName) then
			outvarName	= "SWsfc"
			DATA_season_mean@orig_varName	= inName1
			DATA_season_stdev@orig_varName	= inName1
			DATA_ess_nofilt@orig_varName	= inName1
			DATA_ess_filt@orig_varName		= inName1
		end if
		if (inName.eq.lwName) then
			outvarName	= "LWsfc"
			DATA_season_mean@orig_varName	= inName1
			DATA_season_stdev@orig_varName	= inName1
			DATA_ess_nofilt@orig_varName	= inName1
			DATA_ess_filt@orig_varName		= inName1
		end if	
		if (inName.eq.lhName) then
			outvarName	= "LHFLX"
			DATA_season_mean@orig_varName	= inName1
			DATA_season_stdev@orig_varName	= inName1
			DATA_ess_nofilt@orig_varName	= inName1
			DATA_ess_filt@orig_varName		= inName1
		end if	
		if (inName.eq.shName) then
			outvarName	= "SHFLX"
			DATA_season_mean@orig_varName	= inName1
			DATA_season_stdev@orig_varName	= inName1
			DATA_ess_nofilt@orig_varName	= inName1
			DATA_ess_filt@orig_varName		= inName1
		end if	
		if (inName.eq.pName) then
			outvarName	= "PRECT"
			DATA_season_mean@orig_varName	= inName1
			DATA_season_stdev@orig_varName	= inName1
			DATA_ess_nofilt@orig_varName	= inName1
			DATA_ess_filt@orig_varName		= inName1
		end if	
		if (inName.eq.qName) then
			outvarName	= "Qair"
			DATA_season_mean@orig_varName	= inName1
			DATA_season_stdev@orig_varName	= inName1
			DATA_ess_nofilt@orig_varName	= inName1
			DATA_ess_filt@orig_varName		= inName1
		end if	
		if (inName.eq.tName) then
			outvarName	= "Tair"
			DATA_season_mean@orig_varName	= inName1
			DATA_season_stdev@orig_varName	= inName1
			DATA_ess_nofilt@orig_varName	= inName1
			DATA_ess_filt@orig_varName		= inName1
		end if	
		if (inName.eq.sstName) then
			outvarName	= "SST"
			DATA_season_mean@orig_varName	= inName1
			DATA_season_stdev@orig_varName	= inName1
			DATA_ess_nofilt@orig_varName	= inName1
			DATA_ess_filt@orig_varName		= inName1
		end if	
		if (inName.eq.sstName+"_smSST") then
			outvarName	= "SST_smSST"
			DATA_season_mean@orig_varName	= inName1
			DATA_season_stdev@orig_varName	= inName1
			DATA_ess_nofilt@orig_varName	= inName1
			DATA_ess_filt@orig_varName		= inName1
		end if		
		if (inName.eq.sfcpName) then
			outvarName	= "SFCP"
			DATA_season_mean@orig_varName	= inName1
			DATA_season_stdev@orig_varName	= inName1
			DATA_ess_nofilt@orig_varName	= inName1
			DATA_ess_filt@orig_varName		= inName1
		end if		
		if (s.eq.0) then
			print("outvarName	= "+outvarName)
		end if

		;----------- apply uniform metadata tags
		;			 fixme:  test for latitude direction, longitude bands?
		lon						= data_anom&$lonName$
		lat						= data_anom&$latName$
		DATA_season_stdev!0		= "lat"
		DATA_season_stdev&lat	= lat
		DATA_season_stdev!1		= "lon"
		DATA_season_stdev&lon	= lon
		DATA_season_stdev@filtering	= "20-100 day filtered"
		
		DATA_ess_nofilt!0		= "lat"
		DATA_ess_nofilt&lat		= lat
		DATA_ess_nofilt!1		= "lon"
		DATA_ess_nofilt&lon		= lon
		DATA_ess_nofilt@filtering	= "none"
		DATA_ess_nofilt@long_name	= "equivalent sample size (p=0.05)"
		DATA_ess_nofilt@NCLroutine	= "equiv_sample_size"

		DATA_ess_filt!0			= "lat"
		DATA_ess_filt&lat		= lat
		DATA_ess_filt!1			= "lon"
		DATA_ess_filt&lon		= lon
		DATA_ess_filt@filtering	= "20-100 day filtered"
		DATA_ess_filt@long_name	= "equivalent sample size (p=0.05)"
		DATA_ess_filt@NCLroutine= "equiv_sample_size"

		;----------- write output to /proc directory
		filo		= diro + caseName + ".make_L1.5_stdev_map."+ twStrt + "-" + twLast + "." + outvarName + "." + seasonName(s) + ".nc"
		system("/bin/rm -f "+filo)
		ncdf		= addfile(filo,"c")
		xName			= outvarName+"_stdev"
		ncdf->$xName$	= DATA_season_stdev
		xName			= outvarName+"_ess_nofilt"
		ncdf->$xName$	= DATA_ess_nofilt
		xName			= outvarName+"_ess_filt"
		ncdf->$xName$	= DATA_ess_filt

		delete(season)
		delete(DATA_season_stdev)
		delete(DATA_ess_nofilt)
		delete(DATA_ess_filt)
		delete(filo)

	end	do		; for each season

end


	





