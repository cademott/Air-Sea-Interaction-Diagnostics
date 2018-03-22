load "./Resources/contrib_AirSea.ncl"
  
;============================================================
; 
; Variable naming conventions:
;	LH			= latent heat flux
;	SH			= sensible heat flux
;	SPD			= wind speed (SQRT(u^2.+v^2.)
;	delQ		= delta-Q [q*(SST) - q(air)]
;	delQ_smSST	= delta-Q [q*(61-day smoothed SST) - q(air)]
;	delT		= delta-T [SST - T(air)]
;	delT_smSST	= delta-T [61-day smoothed SST - T(air)]
;	wdLH		= wind-driven LH (|V|-prime * 61-day smoothed delQ)
;	tdLH		= thermodynamic LH (61-day smoothed |V| * delQ-prime)
;	ecLH		= second order LH (|V|-prime * delQ-prime)
;	wdLH_smSST	= as above, but with delQ_smSST
;	tdLH_smSST	= as above, but with delQ_smSST
;	ecLH_smSST	= as above, but with delQ_smSST
;   LH components shown above are also calculated for SH and delT
;
;============================================================

begin
                           
	print(" ")
	print("============= in program make_L1.3_flux_components.nc =============")

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
	lhName		= getenv("LHVARNAME")
	fillh		= getenv("LHFILENAME")
	shName		= getenv("SHVARNAME")
	filsh		= getenv("SHFILENAME")
	qName		= getenv("QVARNAME")
	filq		= getenv("QFILENAME")
	tName		= getenv("TKVARNAME")
	filt		= getenv("TKFILENAME")
	diri		= getenv("FILEDIR") + "/"
	caseName	= getenv("caseName")
	timeName	= getenv("TIMEVAR")
	levName		= getenv("LEVNAME")
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
	;----------- LHFLX calculations:
	print("reading LHFLX...")
	fillh		= diri + caseName + "." + lhName + "."+ dateStr + "." + latbandStr + ".day.background.anom.nc"
	f			= addfile(fillh, "r")
	tempName	= lhName + "_anom_sm"
	date 		= cd_calendar(f->$timeName$, -2)   ; entire file
	iStrt		= 0      			; desired dates
	iLast		= dimsizes(date)-1
	delete(date)
	LH_anom		= f->$tempName$($timeName$|iStrt:iLast,{$latName$|latS_globe:latN_globe},$lonName$|:)

	;----------- SPD:
	print("reading SPD...")
	filspd		= diri + caseName + ".SPD."+ dateStr + "." + latbandStr + ".day.background.anom.nc"
	f			= addfile(filspd, "r")
	tempName	= "SPD_bg"
	date 		= cd_calendar(f->$timeName$, -2)   ; entire file
	iStrt		= 0      			; desired dates
	iLast		= dimsizes(date)-1
	delete(date)
	SPD_bg 		= f->$tempName$($timeName$|iStrt:iLast,{$latName$|latS_globe:latN_globe},$lonName$|:) 

	tempName	= "SPD_anom_sm"
	SPD_anom	= f->$tempName$($timeName$|iStrt:iLast,{$latName$|latS_globe:latN_globe},$lonName$|:)

	;----------- delQ (full SST):
	print("reading delQ...")
	fildq		= diri + caseName + ".delQ."+ dateStr + "." + latbandStr + ".day.background.anom.nc"
	f			= addfile(fildq, "r")
	tempName	= "delQ_bg"
	date 		= cd_calendar(f->$timeName$, -2)   ; entire file
	iStrt		= 0      			; desired dates
	iLast		= dimsizes(date)-1
	delete(date)
	delQ_bg		= f->$tempName$($timeName$|iStrt:iLast,{$latName$|latS_globe:latN_globe},$lonName$|:)

	tempName	= "delQ_anom_sm"
	delQ_anom	= f->$tempName$($timeName$|iStrt:iLast,{$latName$|latS_globe:latN_globe},$lonName$|:)

	;-------- compute wind-driven, thermodynamic, and second order latent heat flux
	print("computing LHFLX terms (full SST)...")
	wdLH		= SPD_anom * delQ_bg
	tdLH		= SPD_bg * delQ_anom
	ecLH		= SPD_anom * delQ_anom
	;----- added on 6 Feb 2018.  Needed because products involving anomalies (espeically x'*y')
	;		tend to have non-zero means.  This has almost no effect on wdLH and tdLH,
	;		but reduces mean ecLH from ~-2 W m**-2 to ~0 W m**-2.  The overall result for
	;		assessing the SST effect is nearly negligible.  
	;
	;		This correction computes the low-frequency background state with a 101-pt Lanczos filter
	;		with a 100-day cutoff (see appendix of Adames and Wallace, JAS Oct 2015).
	;wgthp		= filwgts_lanczos(101,1,1./100.,-999.,0) ; high-pass filter
	wgt		= filwgts_lanczos(101,0,1./100.,-999.,0) ; low-pass
	wdLH		= wdLH - wgt_runave_n_Wrap( wdLH, wgt, 1, 0 )
	tdLH		= tdLH - wgt_runave_n_Wrap( tdLH, wgt, 1, 0 )
	ecLH		= ecLH - wgt_runave_n_Wrap( ecLH, wgt, 1, 0 )
	copy_VarMeta(LH_anom,wdLH)
	copy_VarMeta(LH_anom,tdLH)
	copy_VarMeta(LH_anom,ecLH)
	wdLH@long_name = "wind-driven latent heat flux"
	tdLH@long_name = "thermodynamic latent heat flux"
	ecLH@long_name = "second order latent heat flux"

	;-------- compute approximate coefficient by regression onto actual flux anomaly
	Lq_factor	= regCoef(wdLH($latName$|:,$lonName$|:,$timeName$|:)+tdLH($latName$|:,$lonName$|:,$timeName$|:)+ecLH($latName$|:,$lonName$|:,$timeName$|:) , LH_anom($latName$|:,$lonName$|:,$timeName$|:))
	wdLH		= wdLH * conform_dims(dimsizes(wdLH),Lq_factor,(/1,2/)) ; wind-driven
	tdLH		= tdLH * conform_dims(dimsizes(wdLH),Lq_factor,(/1,2/)) ; thermodynamic
	ecLH		= ecLH * conform_dims(dimsizes(wdLH),Lq_factor,(/1,2/)) ; 2nd order 
	comptotLH	= wdLH + tdLH + ecLH
	copy_VarMeta(wdLH,comptotLH)
	comptotLH@long_name	= "component total latent heat flux"
;	printMinMax(wdLH,True)
;	printMinMax(tdLH,True)
;	printMinMax(ecLH,True)
;	printMinMax(comptotLH,True)
;	printMinMax(LH_anom,True)

	;-------- write component flux terms to output
	filo	= diri + caseName + ".wdLH." + dateStr + "." + latbandStr + ".day.background.anom.nc"
	system("/bin/rm -f "+filo)      ; rm any pre-exist file, if any
	ncdf	= addfile(filo,"c")
	xName	= "wdLH_anom_sm"
	ncdf->$xName$	= wdLH

	filo	= diri + caseName + ".tdLH." + dateStr + "." + latbandStr + ".day.background.anom.nc"
	system("/bin/rm -f "+filo)      ; rm any pre-exist file, if any
	ncdf	= addfile(filo,"c")
	xName	= "tdLH_anom_sm"
	ncdf->$xName$	= tdLH

	filo	= diri + caseName + ".ecLH." + dateStr + "." + latbandStr + ".day.background.anom.nc"
	system("/bin/rm -f "+filo)      ; rm any pre-exist file, if any
	ncdf	= addfile(filo,"c")
	xName	= "ecLH_anom_sm"
	ncdf->$xName$	= ecLH

	filo	= diri + caseName + ".comptotLH." + dateStr + "." + latbandStr + ".day.background.anom.nc"
	system("/bin/rm -f "+filo)      ; rm any pre-exist file, if any
	ncdf	= addfile(filo,"c")
	xName	= "comptotLH_anom_sm"
	ncdf->$xName$	= comptotLH

	;-------- free up memory
	delete(delQ_bg)
	delete(delQ_anom)
	delete(wdLH)
	delete(tdLH)
	delete(ecLH)
	;delete(comptotLH)

	;-------- delQ_smSST (smoothed SST):
	print("reading delQ_smSST...")
	fildq		= diri + caseName + ".delQ_smSST."+ dateStr + "." + latbandStr + ".day.background.anom.nc"
	f			= addfile(fildq, "r")
	tempName= "delQ_smSST_bg"
	date 		= cd_calendar(f->$timeName$, -2)   ; entire file
	iStrt		= 0      			; desired dates
	iLast		= dimsizes(date)-1
	delete(date)
	delQ_smSST_bg  = f->$tempName$($timeName$|iStrt:iLast,{$latName$|latS_globe:latN_globe},$lonName$|:) 

	tempName	= "delQ_smSST_anom_sm"
	delQ_smSST_anom  = f->$tempName$($timeName$|iStrt:iLast,{$latName$|latS_globe:latN_globe},$lonName$|:) 

	;-------- compute wind-driven, thermodynamic, and 2nd order latent heat flux for smoothed SST
	print("computing LHFLX terms (smoothed SST)...")
	wdLH_smSST		= SPD_anom * delQ_smSST_bg
	tdLH_smSST		= SPD_bg * delQ_smSST_anom
	ecLH_smSST		= SPD_anom * delQ_smSST_anom
	wdLH_smSST		= wdLH_smSST - wgt_runave_n_Wrap( wdLH_smSST, wgt, 1, 0 )
	tdLH_smSST		= tdLH_smSST - wgt_runave_n_Wrap( tdLH_smSST, wgt, 1, 0 )
	ecLH_smSST		= ecLH_smSST - wgt_runave_n_Wrap( ecLH_smSST, wgt, 1, 0 )
	copy_VarMeta(LH_anom,wdLH_smSST)
	copy_VarMeta(LH_anom,tdLH_smSST)
	copy_VarMeta(LH_anom,ecLH_smSST)
	wdLH_smSST@long_name = "wind-driven latent heat flux"
	tdLH_smSST@long_name = "thermodynamic latent heat flux"
	ecLH_smSST@long_name = "second order latent heat flux"

	;-------- use same L*Ceoff multiplier to from full SST fluxes
	wdLH_smSST		= wdLH_smSST * conform_dims(dimsizes(wdLH_smSST),Lq_factor,(/1,2/)) ; wind-driven
	tdLH_smSST		= tdLH_smSST * conform_dims(dimsizes(wdLH_smSST),Lq_factor,(/1,2/)) ; thermodynamic
	ecLH_smSST		= ecLH_smSST * conform_dims(dimsizes(wdLH_smSST),Lq_factor,(/1,2/)) ; 2nd order 
	comptotLH_smSST	= wdLH_smSST + tdLH_smSST + ecLH_smSST
	copy_VarMeta(wdLH_smSST,comptotLH_smSST)
	comptotLH_smSST@long_name = "component total latent heat flux"

	;-------- compute the "SST effect" time seires for LH
	SSTeffect_LH	= comptotLH - comptotLH_smSST
	copy_VarMeta(comptotLH,SSTeffect_LH)
	SSTeffect_LH@long_name	= "LHFLX from SST perturbations"

	;-------- write component flux terms to output
	filo	= diri + caseName + ".wdLH_smSST." + dateStr + "." + latbandStr + ".day.background.anom.nc"
	system("/bin/rm -f "+filo)      ; rm any pre-exist file, if any
	ncdf	= addfile(filo,"c")
	xName	= "wdLH_smSST_anom_sm"
	ncdf->$xName$	= wdLH_smSST

	filo	= diri + caseName + ".tdLH_smSST." + dateStr + "." + latbandStr + ".day.background.anom.nc"
	system("/bin/rm -f "+filo)      ; rm any pre-exist file, if any
	ncdf	= addfile(filo,"c")
	xName	= "tdLH_smSST_anom_sm"
	ncdf->$xName$	= tdLH_smSST

	filo	= diri + caseName + ".ecLH_smSST." + dateStr + "." + latbandStr + ".day.background.anom.nc"
	system("/bin/rm -f "+filo)      ; rm any pre-exist file, if any
	ncdf	= addfile(filo,"c")
	xName	= "ecLH_smSST_anom_sm"
	ncdf->$xName$	= ecLH_smSST

	filo	= diri + caseName + ".comptotLH_smSST." + dateStr + "." + latbandStr + ".day.background.anom.nc"
	system("/bin/rm -f "+filo)      ; rm any pre-exist file, if any
	ncdf	= addfile(filo,"c")
	xName	= "comptotLH_smSST_anom_sm"
	ncdf->$xName$	= comptotLH_smSST

	;-------- free up memory
	delete(comptotLH)
	delete(wdLH_smSST)
	delete(tdLH_smSST)
	delete(ecLH_smSST)
	delete(comptotLH_smSST)
	delete(LH_anom)
	delete(delQ_smSST_bg)
	delete(delQ_smSST_anom)

	;============================================
	;----------- SHFLX calculations:
	print("reading SHFLX...")
	filsh		= diri + caseName + "." + shName + "."+ dateStr + "." + latbandStr + ".day.background.anom.nc"
	f			= addfile(filsh,"r")
	tempName	= shName + "_anom_sm"
	date 		= cd_calendar(f->$timeName$, -2)   ; entire file
	iStrt		= 0      			; desired dates
	iLast		= dimsizes(date)-1
	delete(date)
	SH_anom		= f->$tempName$($timeName$|iStrt:iLast,{$latName$|latS_globe:latN_globe},$lonName$|:)

	;--------  delT (full SST):
	print("reading delT...")
	fildt		= diri + caseName + ".delT."+ dateStr + "." + latbandStr + ".day.background.anom.nc"
	f			= addfile(fildt, "r")
	tempName	= "delT_bg"
	date 		= cd_calendar(f->$timeName$, -2)   ; entire file
	iStrt		= 0      			; desired dates
	iLast		= dimsizes(date)-1
	delete(date)
	delT_bg		= f->$tempName$($timeName$|iStrt:iLast,{$latName$|latS_globe:latN_globe},$lonName$|:) 

	tempName	= "delT_anom_sm"
	delT_anom	= f->$tempName$($timeName$|iStrt:iLast,{$latName$|latS_globe:latN_globe},$lonName$|:)

	;-------- compute wind-driven, thermodynamic, and 2nd order latent heat flux
	print("computing SHFLX terms (full SST)...")
	wdSH		= SPD_anom * delT_bg
	tdSH		= SPD_bg * delT_anom
	ecSH		= SPD_anom * delT_anom
	wdSH		= wdSH - wgt_runave_n_Wrap( wdSH, wgt, 1, 0 )
	tdSH		= tdSH - wgt_runave_n_Wrap( tdSH, wgt, 1, 0 )
	ecSH		= ecSH - wgt_runave_n_Wrap( ecSH, wgt, 1, 0 )
	copy_VarMeta(SH_anom,wdSH)
	copy_VarMeta(SH_anom,tdSH)
	copy_VarMeta(SH_anom,ecSH)
	wdSH@long_name = "wind-driven sensible heat flux"
	tdSH@long_name = "thermodynamic sensible heat flux"
	ecSH@long_name = "second order sensible heat flux"
	
	;-------- compute L*Ceoff multiplier to get flux units
	Cp_factor	= regCoef(wdSH($latName$|:,$lonName$|:,$timeName$|:)+tdSH($latName$|:,$lonName$|:,$timeName$|:)+ecSH($latName$|:,$lonName$|:,$timeName$|:) , SH_anom($latName$|:,$lonName$|:,$timeName$|:))
	wdSH		= wdSH * conform_dims(dimsizes(wdSH),Cp_factor,(/1,2/)) ; wind-driven
	tdSH		= tdSH * conform_dims(dimsizes(wdSH),Cp_factor,(/1,2/)) ; thermodynamic
	ecSH		= ecSH * conform_dims(dimsizes(wdSH),Cp_factor,(/1,2/)) ; 2nd order
	comptotSH	= wdSH + tdSH + ecSH
	copy_VarMeta(wdSH,comptotSH)
	comptotSH@long_name	= "component total sensible heat flux"

	;-------- write component flux terms to output
	filo	= diri + caseName + ".wdSH." + dateStr + "." + latbandStr + ".day.background.anom.nc"
	system("/bin/rm -f "+filo)      ; rm any pre-exist file, if any
	ncdf	= addfile(filo,"c")
	xName	= "wdSH_anom_sm"
	ncdf->$xName$	= wdSH

	filo	= diri + caseName + ".tdSH." + dateStr + "." + latbandStr + ".day.background.anom.nc"
	system("/bin/rm -f "+filo)      ; rm any pre-exist file, if any
	ncdf	= addfile(filo,"c")
	xName	= "tdSH_anom_sm"
	ncdf->$xName$	= tdSH

	filo	= diri + caseName + ".ecSH." + dateStr + "." + latbandStr + ".day.background.anom.nc"
	system("/bin/rm -f "+filo)      ; rm any pre-exist file, if any
	ncdf	= addfile(filo,"c")
	xName	= "ecSH_anom_sm"
	ncdf->$xName$	= ecSH

	filo	= diri + caseName + ".comptotSH." + dateStr + "." + latbandStr + ".day.background.anom.nc"
	system("/bin/rm -f "+filo)      ; rm any pre-exist file, if any
	ncdf	= addfile(filo,"c")
	xName	= "comptotSH_anom_sm"
	ncdf->$xName$	= comptotSH

	;-------- free up memory
	delete(wdSH)
	delete(tdSH)
	delete(ecSH)
	delete(delT_bg)
	delete(delT_anom)

	;-------- delT_smSST (smoothed SST):
	print("reading delT_smSST...")
	fildt		= diri + caseName + ".delT_smSST."+ dateStr + "." + latbandStr + ".day.background.anom.nc"
	f			= addfile(fildt, "r")
	tempName= "delT_smSST_bg"
	date 		= cd_calendar(f->$timeName$, -2)   ; entire file
	iStrt		= 0      			; desired dates
	iLast		= dimsizes(date)-1
	delete(date)
	delT_smSST_bg  = f->$tempName$($timeName$|iStrt:iLast,{$latName$|latS_globe:latN_globe},$lonName$|:) 

	tempName= "delT_smSST_anom_sm"
	delT_smSST_anom	= f->$tempName$($timeName$|iStrt:iLast,{$latName$|latS_globe:latN_globe},$lonName$|:)

	;-------- compute wind-driven, thermodynamic, and 2nd order latent heat flux for smoothed SST
	print("computing SHFLX terms (smoothed SST)...")
	wdSH_smSST		= SPD_anom * delT_smSST_bg
	tdSH_smSST		= SPD_bg * delT_smSST_anom
	ecSH_smSST		= SPD_anom * delT_smSST_anom
	wdSH_smSST		= wdSH_smSST - wgt_runave_n_Wrap( wdSH_smSST, wgt, 1, 0 )
	tdSH_smSST		= tdSH_smSST - wgt_runave_n_Wrap( tdSH_smSST, wgt, 1, 0 )
	ecSH_smSST		= ecSH_smSST - wgt_runave_n_Wrap( ecSH_smSST, wgt, 1, 0 )
	copy_VarMeta(SH_anom,wdSH_smSST)
	copy_VarMeta(SH_anom,tdSH_smSST)
	copy_VarMeta(SH_anom,ecSH_smSST)
	wdSH_smSST@long_name = "wind-driven sensible heat flux"
	tdSH_smSST@long_name = "thermodynamic sensible heat flux"
	ecSH_smSST@long_name = "second order sensible heat flux"

	;-------- use same L*Ceoff multiplier from full SST flux
	wdSH_smSST		= wdSH_smSST * conform_dims(dimsizes(wdSH_smSST),Cp_factor,(/1,2/)) ; wind-driven
	tdSH_smSST		= tdSH_smSST * conform_dims(dimsizes(wdSH_smSST),Cp_factor,(/1,2/)) ; thermodynamic
	ecSH_smSST		= ecSH_smSST * conform_dims(dimsizes(wdSH_smSST),Cp_factor,(/1,2/)) ; 2nd order
	comptotSH_smSST	= wdSH_smSST + tdSH_smSST + ecSH_smSST
	copy_VarMeta(wdSH_smSST,comptotSH_smSST)
	comptotSH_smSST@long_name	= "component total sensible heat flux"

	;-------- compute the "SST effect" time seires for SH
	SSTeffect_SH	= comptotSH - comptotSH_smSST
	copy_VarMeta(comptotSH,SSTeffect_SH)
	SSTeffect_SH@long_name	= "SHFLX from SST perturbations"

	;-------- write component flux terms to output
	filo	= diri + caseName + ".wdSH_smSST." + dateStr + "." + latbandStr + ".day.background.anom.nc"
	system("/bin/rm -f "+filo)      ; rm any pre-exist file, if any
	ncdf	= addfile(filo,"c")
	xName	= "wdSH_smSST_anom_sm"
	ncdf->$xName$	= wdSH_smSST

	filo	= diri + caseName + ".tdSH_smSST." + dateStr + "." + latbandStr + ".day.background.anom.nc"
	system("/bin/rm -f "+filo)      ; rm any pre-exist file, if any
	ncdf	= addfile(filo,"c")
	xName	= "tdSH_smSST_anom_sm"
	ncdf->$xName$	= tdSH_smSST

	filo	= diri + caseName + ".ecSH_smSST." + dateStr + "." + latbandStr + ".day.background.anom.nc"
	system("/bin/rm -f "+filo)      ; rm any pre-exist file, if any
	ncdf	= addfile(filo,"c")
	xName	= "ecSH_smSST_anom_sm"
	ncdf->$xName$	= ecSH_smSST

	filo	= diri + caseName + ".comptotSH_smSST." + dateStr + "." + latbandStr + ".day.background.anom.nc"
	system("/bin/rm -f "+filo)      ; rm any pre-exist file, if any
	ncdf	= addfile(filo,"c")
	xName	= "comptotSH_smSST_anom_sm"
	ncdf->$xName$	= comptotSH_smSST

	;-------- free up memory
	delete(comptotSH)
	delete(wdSH_smSST)
	delete(tdSH_smSST)
	delete(ecSH_smSST)
	delete(comptotSH_smSST)
	delete(delT_smSST_bg)
	delete(delT_smSST_anom)
	delete(SH_anom)
	
	;-------- write out SSTeffect time series
	print("writing SST effect time series...")
	filo	= diri + caseName + ".SSTeffect_LH." + dateStr + "." + latbandStr + ".day.background.anom.nc"
	system("/bin/rm -f "+filo)      ; rm any pre-exist file, if any
	ncdf	= addfile(filo,"c")
	xName	= "SSTeffect_LH_anom_sm"
	SSTeffect_LH@units			= "W/m**2"
	SSTeffect_LH@calculation	= "comptotLH - comptotLH_smSST"
	ncdf->$xName$	= SSTeffect_LH
	
	filo	= diri + caseName + ".SSTeffect_SH." + dateStr + "." + latbandStr + ".day.background.anom.nc"
	system("/bin/rm -f "+filo)      ; rm any pre-exist file, if any
	ncdf	= addfile(filo,"c")
	xName	= "SSTeffect_SH_anom_sm"
	SSTeffect_SH@units	= "W/m**2"
	SSTeffect_SH@calculation	= "comptotSH - comptotSH_smSST"
	ncdf->$xName$	= SSTeffect_SH
	
	delete(SSTeffect_LH)
	delete(SSTeffect_SH)

end
	





