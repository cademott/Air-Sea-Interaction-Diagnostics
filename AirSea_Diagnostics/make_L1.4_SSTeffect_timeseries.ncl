load "./Resources/contrib_AirSea.ncl"
  
;============================================================
; computes ctLH - ctLH_smSST and
;		   ctSH - ctSH_smSST
; and write data to file to simplify additional processing
;============================================================

begin
                           
	print(" ")
	print("============= in program make_L1.4_SSTeffect_timeseries.nc =============")

	;----------- suppress warnings?
	debug		= getenv("DEBUG")
	if (debug.eq."false") then
		err = NhlGetErrorObjectId()
		setvalues err
			"errLevel" : "Fatal"          ; only report Fatal errors
		end setvalues
	end if

	twStrt		= getenv("YMDSTRT")
	twLast		= getenv("YMDLAST")
	dateStr		= getenv("FILESUFFSTR")
	diri		= getenv("FILEDIR") + "/"
	caseName	= getenv("caseName")
	timeName	= getenv("TIMEVAR")
	latName		= getenv("LATNAME")
	lonName		= getenv("LONNAME")
	latSstr		= getenv("latSouth")
	latNstr		= getenv("latNorth")

	print("case = "+caseName)

	latS_globe	= stringtofloat(latSstr)
	latN_globe	= stringtofloat(latNstr)
	
	;----------- define latitude output string
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

	;============================================
	;----------- LHFLX SST effect calculations:
	print("reading comptotLH...")
	fillh			= diri + caseName + ".comptotLH."+ dateStr + "." + latbandStr + ".day.background.anom.nc"
	f				= addfile(fillh, "r")
	tempName		= "comptotLH_anom_sm"
	date 			= cd_calendar(f->$timeName$, -2)   ; entire file
	iStrt			= 0      			; desired dates
	iLast			= dimsizes(date)-1
	delete(date)
	comptotLH		= f->$tempName$($timeName$|iStrt:iLast,{$latName$|latS_globe:latN_globe},$lonName$|:)

	print("reading comptotLH_smSST...")
	fillh			= diri + caseName + ".comptotLH_smSST."+ dateStr + "." + latbandStr + ".day.background.anom.nc"
	f				= addfile(fillh, "r")
	tempName		= "comptotLH_anom_sm"
	date 			= cd_calendar(f->$timeName$, -2)   ; entire file
	iStrt			= 0      			; desired dates
	iLast			= dimsizes(date)-1
	delete(date)
	comptotLH_smSST	= f->$tempName$($timeName$|iStrt:iLast,{$latName$|latS_globe:latN_globe},$lonName$|:)

	SSTeffect_LH	= comptotLH - comptotLH_smSST
	copy_VarMeta(comptotLH,SSTeffect_LH)
	SSTeffect_LH@long_name		= "LHFLX from SST perturbations"
	SSTeffect_LH@units			= "W/m**2"
	SSTeffect_LH@calculation	= "comptotLH - comptotLH_smSST"

	filo	= diri + caseName + ".SSTeffect_LH." + dateStr + "." + latbandStr + ".day.background.anom.nc"
	system("/bin/rm -f "+filo)      ; rm any pre-exist file, if any
	ncdf	= addfile(filo,"c")
	xName	= "SSTeffect_LH_anom_sm"
	ncdf->$xName$	= SSTeffect_LH
	print("output written to " + filo)

	;============================================
	;----------- SHFLX SST effect calculations:
	print("reading comptotSH...")
	fillh			= diri + caseName + ".comptotSH."+ dateStr + "." + latbandStr + ".day.background.anom.nc"
	f				= addfile(fillh, "r")
	tempName		= "comptotSH_anom_sm"
	date 			= cd_calendar(f->$timeName$, -2)   ; entire file
	iStrt			= 0      			; desired dates
	iLast			= dimsizes(date)-1
	delete(date)
	comptotSH		= f->$tempName$($timeName$|iStrt:iLast,{$latName$|latS_globe:latN_globe},$lonName$|:)

	print("reading comptotSH_smSST...")
	fillh			= diri + caseName + ".comptotSH_smSST."+ dateStr + "." + latbandStr + ".day.background.anom.nc"
	f				= addfile(fillh, "r")
	tempName		= "comptotSH_anom_sm"
	date 			= cd_calendar(f->$timeName$, -2)   ; entire file
	iStrt			= 0      			; desired dates
	iLast			= dimsizes(date)-1
	delete(date)
	comptotSH_smSST	= f->$tempName$($timeName$|iStrt:iLast,{$latName$|latS_globe:latN_globe},$lonName$|:)

	SSTeffect_SH	= comptotSH - comptotSH_smSST
	copy_VarMeta(comptotSH,SSTeffect_SH)
	SSTeffect_SH@long_name		= "SHFLX from SST perturbations"
	SSTeffect_SH@units			= "W/m**2"
	SSTeffect_SH@calculation	= "comptotSH - comptotSH_smSST"

	filo	= diri + caseName + ".SSTeffect_SH." + dateStr + "." + latbandStr + ".day.background.anom.nc"
	system("/bin/rm -f "+filo)      ; rm any pre-exist file, if any
	ncdf	= addfile(filo,"c")
	xName	= "SSTeffect_SH_anom_sm"
	ncdf->$xName$	= SSTeffect_SH
	print("output written to " + filo)


end
	


