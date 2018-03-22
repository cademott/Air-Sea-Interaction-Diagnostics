;************************************************************
;
; air-sea interaction diagnostics pre-conditioning step:
;
;	- Define the latitude band identifier string
;	- Diagnose surface flux sign convention 
;
;************************************************************

load "./Resources/contrib_AirSea.ncl"
  
;******************** MAIN **********************************
begin
                           
	print(" ")
	print("=============== in make_L0.2_FluxSignFix.ncl =================")

	;------------- get variable names
	twStrt		= getenv("YMDSTRT")
	twLast		= getenv("YMDLAST")
	dateStr		= getenv("FILESUFFSTR")
	lhName		= getenv("LHVARNAME")
	shName		= getenv("SHVARNAME")
	swName		= getenv("SWVARNAME")
	lwName		= getenv("LWVARNAME")

	diri		= getenv("FILEDIR") + "/"
	caseName	= getenv("caseName")
	timeName	= getenv("TIMEVAR")
	latName		= getenv("LATNAME")
	lonName		= getenv("LONNAME")
	latSstr		= getenv("latSouth")
	latNstr		= getenv("latNorth")
	
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

	;------------- define flux test region (south Central Pacific; relatively cloud-free)
	IOlatS		= -15.
	IOlatN		=  -5.
	IOlonW		= 230.
	IOlonE		= 240.

	;------------- check sign of net surface SW data  
	print(" ")
	inFile1		= diri + caseName + "." + swName + "."+ dateStr + "." + latbandStr + ".day.mean.nc"
	origFile	= diri + caseName + "." + swName + "."+ dateStr + "." + latbandStr + ".original.day.mean.nc"
	f			= addfile(inFile1,"w")
	if (getfilevartypes(f,swName) .eq. "short") then
	  flux		= short2flt( f->$swName$($timeName$|:,$latName$|:,$lonName$|:)) 
	else
	  flux	= f->$swName$($timeName$|:,$latName$|:,$lonName$|:)
	end if
	fluxbar	= avg(flux(:,{IOlatS:IOlatN},{IOlonW:IOlonE}))
	if (fluxbar.gt.0) then
		print("-------> net surface SW is positive to the ocean.  NO CHANGE IN SIGN")
		flux@sign_convention	= "positive into the ocean"
		print("adding 'sign_convention' attribute to input file...")
		f->$swName$		= flux
	else
		print("-------> net surface SW is positive to the atmosphere.  CHANGING SIGN IN INPUT FILE")
		print("-------> original data will be copied to "+origFile)
		system("cp " + inFile1 + " " + origFile)
		flux@sign_convention	= "positive into the ocean"
		f->$swName$		= -1.*flux
	end if
	delete(f)
	delete(fluxbar)
	delete(flux)
	
	;------------- check sign of net surface LW data  
	print(" ")
	inFile1		= diri + caseName + "." + lwName + "."+ dateStr + "." + latbandStr + ".day.mean.nc"
	origFile	= diri + caseName + "." + lwName + "."+ dateStr + "." + latbandStr + ".original.day.mean.nc"
	f			= addfile(inFile1,"w")
	if (getfilevartypes(f,lwName) .eq. "short") then
	  flux		= short2flt( f->$lwName$($timeName$|:,$latName$|:,$lonName$|:)) 
	else
	  flux	= f->$lwName$($timeName$|:,$latName$|:,$lonName$|:)
	end if
	fluxbar	= avg(flux(:,{IOlatS:IOlatN},{IOlonW:IOlonE}))
	if (fluxbar.gt.0) then
		print("-------> net surface LW is positive to the atmosphere.  NO CHANGE IN SIGN")
		flux@sign_convention	= "positive out of the ocean"
		print("adding 'sign_convention' attribute to input file...")
		flux@sign_convention	= "positive out of the ocean"
		f->$lwName$		= flux
	else
		print("-------> net surface LW is positive to the ocean.  CHANGING SIGN IN INPUT FILE")
		print("-------> original data will be copied to "+origFile)
		system("cp " + inFile1 + " " + origFile)
		flux@sign_convention	= "positive out of the ocean"
		f->$lwName$		= -1.*flux
	end if
	delete(f)
	delete(fluxbar)
	delete(flux)

	;------------- read in LHFLX data  
	print(" ")
	inFile1		= diri + caseName + "." + lhName + "."+ dateStr + "." + latbandStr + ".day.mean.nc"
	origFile	= diri + caseName + "." + lhName + "."+ dateStr + "." + latbandStr + ".original.day.mean.nc"
	f			= addfile(inFile1,"w")
	if (getfilevartypes(f,lhName) .eq. "short") then
	  flux		= short2flt( f->$lhName$($timeName$|:,$latName$|:,$lonName$|:)) 
	else
	  flux	= f->$lhName$($timeName$|:,$latName$|:,$lonName$|:)
	end if
	fluxbar	= avg(flux(:,{IOlatS:IOlatN},{IOlonW:IOlonE}))
	if (fluxbar.gt.0) then
		print("-------> LHFLX is positive to the atmosphere.  NO CHANGE IN SIGN")
		flux@sign_convention	= "positive out of the ocean"
		print("adding 'sign_convention' attribute to input file...")
		f->$lhName$		= flux
	else
		print("-------> LHFLX is positive to the ocean.  CHANGING SIGN IN INPUT FILE")
		print("-------> original data will be copied to "+origFile)
		system("cp " + inFile1 + " " + origFile)
		flux@sign_convention	= "positive out of the ocean"
		f->$lhName$		= -1.*flux
	end if
	delete(f)
	delete(fluxbar)
	delete(flux)
	
	;------------- read in SHFLX data  
	print(" ")
	inFile1		= diri + caseName + "." + shName + "."+ dateStr + "." + latbandStr + ".day.mean.nc"
	origFile	= diri + caseName + "." + shName + "."+ dateStr + "." + latbandStr + ".original.day.mean.nc"
	f			= addfile(inFile1,"w")
	if (getfilevartypes(f,shName) .eq. "short") then
	  flux		= short2flt( f->$shName$($timeName$|:,$latName$|:,$lonName$|:)) 
	else
	  flux	= f->$shName$($timeName$|:,$latName$|:,$lonName$|:)
	end if
	fluxbar	= avg(flux(:,{IOlatS:IOlatN},{IOlonW:IOlonE}))
	if (fluxbar.gt.0) then
		print("-------> SHFLX is positive to the atmosphere.  NO CHANGE IN SIGN")
		flux@sign_convention	= "positive out of the ocean"
		print("adding 'sign_convention' attribute to input file...")
		f->$shName$		= flux
	else
		print("-------> SHFLX is positive to the ocean.  CHANGING SIGN IN INPUT FILE")
		print("-------> original data will be copied to "+origFile)
		system("cp " + inFile1 + " " + origFile)
		flux@sign_convention	= "positive out of the ocean"
		f->$shName$		= -1.*flux
	end if
	delete(f)
	delete(fluxbar)
	delete(flux)
	
end