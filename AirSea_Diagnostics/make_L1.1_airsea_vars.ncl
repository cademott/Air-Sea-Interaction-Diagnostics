;************************************************************
;
; air-sea interaction diagnostics pre-conditioning step:
;
;   Compute derived variables:
;		- delta-q, delta-T with full SST
;		- delta-q, delta-T with smoothed SST
;		- relative humidity
;		- wind speed
;		- Qnet
;
;************************************************************

load "./Resources/contrib_AirSea.ncl"
  
;******************** MAIN **********************************
begin
                           
	print(" ")
	print("=============== in make_L1.1_airsea_vars.ncl =================")

	;----------- suppress warnings?
	debug		= getenv("DEBUG")
	if (debug.eq."false") then
		err = NhlGetErrorObjectId()
		setvalues err
			"errLevel" : "Fatal"          ; only report Fatal errors
		end setvalues
	end if

	;------------- change method of setting dynamic variable names
	diri		= getenv("FILEDIR") + "/"
	twStrt		= getenv("YMDSTRT")
	twLast		= getenv("YMDLAST")
	dateStr		= getenv("FILESUFFSTR")
	pName		= getenv("RAINVARNAME")
	uName		= getenv("UVARNAME")
	vName		= getenv("VVARNAME")
	lhName		= getenv("LHVARNAME")
	shName		= getenv("SHVARNAME")
	swName		= getenv("SWVARNAME")
	lwName		= getenv("LWVARNAME")
	qName		= getenv("QVARNAME")
	tName		= getenv("TKVARNAME")
	sstName		= getenv("SSTVARNAME")
	sfcpName	= getenv("SFCPVARNAME")
	u850Name	= getenv("U850VARNAME")
	diro		= getenv("FILEDIR") + "/"
	caseName	= getenv("caseName")
	timeName	= getenv("TIMEVAR")
	levName		= getenv("LEVNAME")
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

	print("diro = " + diro)
	print("case = " + caseName)

;************************************************************
; PROCESS DATA:
;************************************************************

; WIND SPEED:
;------------------------------------------------------------

	print("SPD...")

	;------------- read in U
	filu	= diri + caseName + "." + uName + "."+ dateStr + "." + latbandStr + ".day.mean.nc"
	f      	= addfile(filu, "r")  
	date 	= cd_calendar(f->$timeName$, -2)   ; entire file
	iStrt  = 0      			; desired dates
	iLast  = dimsizes(date)-1
	print("iStrt = "+iStrt+"   iLast = "+iLast)
	delete(date)

	; sometimes U=U(time,lev,lat,lon) where dimsize(lev)=1.
	; what we want is U=U(time,lat,lon)
	if (dimsizes(getfilevardims(f,uName)) .eq. 4) then
	  if (getfilevartypes(f,uName) .eq. "short") then
		  U  = short2flt( f->$uName$($timeName$|iStrt:iLast,$levName$|:,{$latName$|latS_globe:latN_globe},$lonName$|:) ) 
		  Unew  = rm_single_dims(U)
		  delete(U)
		  U	= Unew
		  delete(Unew)
	  else
		  U  = f->$uName$($timeName$|iStrt:iLast,$levName$|:,{$latName$|latS_globe:latN_globe},$lonName$|:)
		  Unew  = rm_single_dims(U)
		  delete(U)
		  U	= Unew
		  delete(Unew)
	  end if
	else
	  if (getfilevartypes(f,uName) .eq. "short") then
		  U  = short2flt( f->$uName$($timeName$|iStrt:iLast,{$latName$|latS_globe:latN_globe},$lonName$|:) ) 
	  else
		  U  = f->$uName$($timeName$|iStrt:iLast,{$latName$|latS_globe:latN_globe},$lonName$|:)
	  end if
	end if

	;------------- read in V
	filv	= diri + caseName + "." + vName + "."+ dateStr + "." + latbandStr + ".day.mean.nc"
	f      	= addfile(filv, "r")  
	date	= cd_calendar(f->$timeName$, -2)   ; entire file
	iStrt  	= 0      			; desired dates
	iLast  	= dimsizes(date)-1
	delete(date)
									  ; P(time,lat,lon)
	if (dimsizes(getfilevardims(f,vName)) .eq. 4) then
	  if (getfilevartypes(f,vName) .eq. "short") then
		  V  = short2flt( f->$vName$($timeName$|iStrt:iLast,$levName$|:,{$latName$|latS_globe:latN_globe},$lonName$|:) ) 
		  Vnew  = rm_single_dims(V)
		  delete(V)
		  V	= Vnew
		  delete(Vnew)
	  else
		  V  = f->$vName$($timeName$|iStrt:iLast,$levName$|:,{$latName$|latS_globe:latN_globe},$lonName$|:)
		  Vnew  = rm_single_dims(V)
		  delete(V)
		  V	= Vnew
		  delete(Vnew)
	  end if
	else
	  if (getfilevartypes(f,vName) .eq. "short") then
		  V  = short2flt( f->$vName$($timeName$|iStrt:iLast,{$latName$|latS_globe:latN_globe},$lonName$|:) ) 
	  else
		  V  = f->$vName$($timeName$|iStrt:iLast,{$latName$|latS_globe:latN_globe},$lonName$|:)
	  end if
	end if

	;------------- compute SPD
	SPD 			= sqrt(U^2.+V^2.)
	copy_VarMeta(U,SPD)
	SPD@units 		= "m/s"
	SPD@long_name 	= "wind speed"
	;printVarSummary(SPD)
	; fixme:  make this generic 
	lon				= SPD&$lonName$
	lon@units		= "degrees_east"
	lat				= SPD&$latName$
	lat@units		= "degrees_north"
	SPD&$lonName$	= lon
	SPD&$latName$	= lat

	delete(U)
	delete(V)

	;----------- write out daily mean 
	filo	= diro + caseName + ".SPD."+ dateStr + "." + latbandStr + ".day.mean.nc"
	system("/bin/rm -f "+filo)
	ncdf	= addfile(filo,"c")
	ncdf->SPD			= SPD
	

;===========================================================================
;================= compute Qnet
	varName	= (/ swName,		lwName,			lhName,			shName /)
	
	print("Qnet...")
	do v = 0,3 

		;------------- set up time variables
		fili	= diri + caseName + "." + varName(v) + "."+ dateStr + "." + latbandStr + ".day.mean.nc"
		f		= addfile(fili, "r")  
		date	= cd_calendar(f->$timeName$, -2)   ; entire file
		printMinMax(date,True)
		iStrt  = 0      			; desired dates
		iLast  = dimsizes(date)-1
		delete(date)
		ndays	= iLast - iStrt + 1
	
		;------------- read flux data
		if (getfilevartypes(f,varName(v)) .eq. "short") then
		  flux	= short2flt( f->$varName(v)$($timeName$|iStrt:iLast,{$latName$|latS_globe:latN_globe},$lonName$|:)) 
		else
		  flux	= f->$varName(v)$($timeName$|iStrt:iLast,{$latName$|latS_globe:latN_globe},$lonName$|:)
		end if
		
		;------------- accumulate flux
		;------------- NOTE: make sure make_L0.2_FluxSignFix.ncl is run before this step!
		if (v.eq.0) then
			Qnet	= flux			; SW is positive to the ocean
		else
			Qnet	= Qnet - flux	; other fluxes are positive to the atmosphere
		end if

		;------------- delete variables
		delete(flux)
	
	end do
	
	;------------- write out Qnet data
	Qnet@long_name	= "net surface energy flux"
	Qnet@units		= "W/m**2"
	Qnet@sign_convention	= "positive into the ocean"
	filo			= diro + caseName + ".Qnet."+ dateStr + "." + latbandStr + ".day.mean.nc"
	system("/bin/rm -f "+filo)
	ncdf			= addfile(filo,"c")
	xName			= "Qnet"
	ncdf->$xName$	= Qnet


; dSST (avg +SST after sunrise value; diurnal SST) and Tprime (daily warming due to dSST)
;------------------------------------------------------------

	print("SST diurnal amplitude...")
	
	;------------- set up time variables
	fili	= diri + caseName + "." + swName + "." + dateStr + "." + latbandStr + ".day.mean.nc"
	f		= addfile(fili, "r")  
	date	= cd_calendar(f->$timeName$, -2)   ; entire file
	printMinMax(date,True)
	iStrt  = 0      			; desired dates
	iLast  = dimsizes(date)-1
	delete(date)
	ndays	= iLast - iStrt + 1

	;------------- read flux data
	if (getfilevartypes(f,swName) .eq. "short") then
	  SW	= short2flt( f->$swName$($timeName$|iStrt:iLast,{$latName$|latS_globe:latN_globe},$lonName$|:)) 
	else
	  SW	= f->$swName$($timeName$|iStrt:iLast,{$latName$|latS_globe:latN_globe},$lonName$|:)
	end if

	;------------ omit land data points
	a			= addfile("$NCARG_ROOT/lib/ncarg/data/cdf/landsea.nc","r")
	lsdata		= a->LSMASK
	lsm			= landsea_mask(lsdata,SW&$latName$,SW&$lonName$)
	SW			= mask(SW,conform(SW,lsm,(/1,2/)).ge.1,False)

	;------------ from Eq. 18 of Matthews et al. 2014 "The surface diurnal warm layer in the Indian Ocean
	;			  during CINDY/DYNAMO" J. Climate, V27, 9101-9122.
	alpha1		= -2.16E-04
	alpha2		=  0.00208
	alpha3		=  0.0152
	alpha4		= -0.182
	
	dSST		= alpha1*SW*SPD + alpha2*SW + alpha3*SPD + alpha4 ; [K]
	copy_VarMeta(SPD,dSST)
	
	;------------- write out dSST data
	dSST@long_name	= "average positive SST after sunrise"
	dSST@units		= "K"
	dSST@calculation= "Eq. 18 from Matthews et al. 2014; J. Climate"
	filo			= diro + caseName + ".diurnalSST."+ dateStr + "." + latbandStr + ".day.mean.nc"
	system("/bin/rm -f "+filo)
	ncdf			= addfile(filo,"c")
	xName			= "diurnalSST"
	ncdf->$xName$	= dSST
	delete(dSST)
	
	;------------ from Eq. 19 of Matthews et al. 2014 "The surface diurnal warm layer in the Indian Ocean
	;			  during CINDY/DYNAMO" J. Climate, V27, 9101-9122.
	beta1		= -0.000208
	beta2		=  0.00130
	beta3		=  0.0159
	beta4		= -0.0556
	
	Tprime		= beta1*SW*SPD + beta2*SW + beta3*SPD + beta4 ; [K]
	copy_VarMeta(SPD,Tprime)
	
	;------------- write out Tprime data
	Tprime@long_name	= "daily warming from diurnal warm layer"
	Tprime@units		= "K"
	Tprime@calculation= "Eq. 19 from Matthews et al. 2014; J. Climate"
	filo			= diro + caseName + ".SSTprime."+ dateStr + "." + latbandStr + ".day.mean.nc"
	system("/bin/rm -f "+filo)
	ncdf			= addfile(filo,"c")
	xName			= "SSTprime"
	ncdf->$xName$	= Tprime
	delete(Tprime)
	delete(SW)
	delete(SPD)
	

; DELTA-Q:
;------------------------------------------------------------

	print("delta-q...")

	;--------------- read in sfc-q
	filq	= diri + caseName + "." + qName + "."+ dateStr + "." + latbandStr + ".day.mean.nc"
	f     	= addfile(filq, "r")  
	date	= cd_calendar(f->$timeName$, -2)   ; entire file
	iStrt  	= 0      			; desired dates
	iLast  	= dimsizes(date)-1
	delete(date)
									  
	if (dimsizes(getfilevardims(f,qName)) .eq. 4) then
	  if (getfilevartypes(f,qName) .eq. "short") then
		  Q  = short2flt( f->$qName$($timeName$|iStrt:iLast,$levName$|:,{$latName$|latS_globe:latN_globe},$lonName$|:) ) 
		  Qnew  = rm_single_dims(Q)
		  delete(Q)
		  Q	= Qnew
		  delete(Qnew)
	  else
		  Q  = f->$qName$($timeName$|iStrt:iLast,$levName$|:,{$latName$|latS_globe:latN_globe},$lonName$|:)
		  Qnew  = rm_single_dims(Q)
		  delete(Q)
		  Q	= Qnew
		  delete(Qnew)
	  end if
	else
	  if (getfilevartypes(f,qName) .eq. "short") then
		  Q  = short2flt( f->$qName$($timeName$|iStrt:iLast,{$latName$|latS_globe:latN_globe},$lonName$|:) ) 
	  else
		  Q  = f->$qName$($timeName$|iStrt:iLast,{$latName$|latS_globe:latN_globe},$lonName$|:)
	  end if
	end if

	;--------------- read in SST
	filsst	= diri + caseName + "." + sstName + "."+ dateStr + "." + latbandStr + ".day.mean.nc"
	f      	= addfile(filsst, "r")  
	date	= cd_calendar(f->$timeName$, -2)   ; entire file
	iStrt  	= 0      			; desired dates
	iLast  	= dimsizes(date)-1
	delete(date)
	
	print("===========================")
	print("SST file = "+filsst)
	print("===========================")
	if (getfilevartypes(f,sstName) .eq. "short") then
	  SST  = short2flt( f->$sstName$($timeName$|iStrt:iLast,{$latName$|latS_globe:latN_globe},$lonName$|:) ) 
	else if (getfilevartypes(f,sstName) .eq. "double") then
	  SST  = dble2flt( f->$sstName$($timeName$|iStrt:iLast,{$latName$|latS_globe:latN_globe},$lonName$|:) ) 
	else
	  SST  = f->$sstName$($timeName$|iStrt:iLast,{$latName$|latS_globe:latN_globe},$lonName$|:) 
	end if
	end if

	; remove any missing data (likely over land)
;	if (any(ismissing(SST))) then 
;		sst1d	= ndtooned(SST)
;		sst1d(ind(ismissing(sst1d))) = -999		; to accomodate older versions of NCL
;												; that do not automatically allow missing
;												; data in ClmDayTLL routine.
;		SST		= onedtond(sst1d, dimsizes(SST))
;		delete(sst1d)
;	end if

	; COMPUTE DELTA-Q
	;------------------------------------------------------------
		;------------ define constants
		TK		= 273.15
		e1		= 1013.250 ; mb

		;----------------- read in surface pressure
		filsfcp	= diri + caseName + "." + sfcpName + "."+ dateStr + "." + latbandStr + ".day.mean.nc"
		f		= addfile(filsfcp, "r")  
		date	= cd_calendar(f->$timeName$, -2)   ; entire file
		iStrt  = 0      			; desired dates
		iLast  = dimsizes(date)-1
		delete(date)

		if (getfilevartypes(f,sfcpName) .eq. "short") then
		  SFCP  = short2flt( f->$sfcpName$($timeName$|iStrt:iLast,{$latName$|latS_globe:latN_globe},$lonName$|:) ) 
		else
		  SFCP  = f->$sfcpName$($timeName$|iStrt:iLast,{$latName$|latS_globe:latN_globe},$lonName$|:) 
		end if
		;----- check to see that PS > 0
		SFCP1d	= ndtooned(SFCP)
		SFCP1d@_FillValue			= SFCP@_FillValue
		bad		= ind(SFCP1d.le.0)
		if (.not.all(ismissing(bad)))
			SFCP1d(bad)	= SFCP@_FillValue
			SFCP	= onedtond(SFCP1d,dimsizes(SFCP))
			SFCP	= linmsg_n(SFCP, (/-1,5/), 0) ; interpolote up to 5 missing days
		end if
		delete(bad)
		printMinMax(SFCP,True)
		;----- finished interpolating missing data

		;------------ force SfcP to mb units
		if (max(SFCP).gt.1200.) then ; calculation below requires pressure in mb.
			SfcPressure_mb	= SFCP*.01
		else
			SfcPressure_mb = SFCP
		end if

		;------------ force Q to kg/kg units
		if (max(Q).gt.0.5) then
			Qtemp	= Q * 0.001
		else
			Qtemp	= Q
		end if

		;============ calculations using full (unsmoothed) SST ================
		;------------ force ocean temperature to deg C units
		if (max(SST).gt.273.) then
			SST_C = SST - TK
		else
			SST_C = SST
		end if

		x			= max(SST_C)
		print(" ")
		print("=================================")
		print("max SST deg C = 		"+x)
		printMinMax(SST_C,True)
		print("=================================")
		print(" ")

		x			= max(SfcPressure_mb)
		print(" ")
		print("=================================")
		print("max SfcPressure_mb =	"+x)
		printMinMax(SfcPressure_mb,True)
		print("=================================")
		print(" ")

		x			= max(Qtemp)
		print(" ")
		print("=================================")
		print("max Qtemp kg/kg = 			"+x)
		printMinMax(Qtemp,True)
		print("=================================")
		print(" ")

		;------------ compute saturation vapor pressure and mixing ratio
		esat	= 6.112*exp(17.67*SST_C/(243.5+SST_C))	; vapor pressure in hPa [Bolton, 1980]
		wsat	= 0.622*esat/(SfcPressure_mb - esat) 	; above equation returns esat in hPa
		copy_VarCoords(Q,wsat)
		delete(esat)

		;------------ compute saturation specific humidity and delta-q
		Qsat	= wsat/(1.+wsat)
		;----- in some cases, Qsat is < 0.  delete these and interpolate
		Qsat1d	= ndtooned(Qsat)
		Qsat1d@_FillValue			= Qsat@_FillValue
		bad		= ind(Qsat1d.lt.0)
		if (.not.all(ismissing(bad)))
			Qsat1d(bad)	= Qsat@_FillValue
			Qsat	= onedtond(Qsat1d,dimsizes(Qsat))
			Qsat	= linmsg_n(Qsat, (/-1,5/), 0)
		end if
		delete(bad)
		;----- finished interpolating missing data

		delQ	= wsat/(1.+wsat) - Qtemp
		;----- in some cases, Qsat is < 0.  delete these and interpolate
		delQ1d	= ndtooned(delQ)
		delQ1d@_FillValue			= delQ@_FillValue
		bad		= ind(Qsat1d.lt.0)
		if (.not.all(ismissing(bad)))
			Qsat1d(bad)	= Qsat@_FillValue
			Qsat	= onedtond(Qsat1d,dimsizes(Qsat))
			Qsat	= linmsg_n(Qsat, (/-1,5/), 0)
		end if
		delete(bad)
		;----- finished interpolating missing data
		copy_VarCoords(Q,delQ)
		copy_VarCoords(Q,Qsat)
		delQ@units		= "kg/kg"
		delQ@long_name	= "delta-q"
		Qsat@units		= "kg/kg"
		Qsat@long_name	= "Sfc. q*"
		delete(wsat)
		
		x			= max(Qsat)
		print(" ")
		print("=================================")
		print("max Qsat kg/kg =	"+x)
		printMinMax(Qsat,True)
		print("=================================")
		print(" ")

		x			= max(delQ)
		print(" ")
		print("=================================")
		print("max delQ kg/kg = 			"+x)
		printMinMax(delQ,True)
		print("=================================")
		print(" ")

		;------------ write out daily mean computed fields
		filo	= diro + caseName + ".delQ."+ dateStr + "." + latbandStr + ".day.mean.nc"
		print("delQ output file = "+filo)
		system("/bin/rm -f "+filo)
		ncdf	= addfile(filo,"c")
		ncdf->delQ			= delQ

		filo	= diro + caseName + ".Qsat."+ dateStr + "." + latbandStr + ".day.mean.nc"
		system("/bin/rm -f "+filo)
		ncdf	= addfile(filo,"c")
		ncdf->Qsat	= Qsat
				
		delete(delQ)
		delete(Qsat)
		delete(SST_C)


		;============ calculations using smoothed SST ================
		;------------- smoothed SST
		SST_smSST		= runave_n_Wrap(SST,61,1,0)

		;------------ force ocean temperature to deg C units
		if (max(SST).gt.273.) then
			SST_C = SST_smSST - TK
		else
			SST_C = SST_smSST
		end if

		;------------ compute saturation vapor pressure and mixing ratio
		esat	= 6.112*exp(17.67*SST_C/(243.5+SST_C))	; vapor pressure in hPa [Bolton, 1980]
		wsat	= 0.622*esat/(SfcPressure_mb - esat) 	; above equation returns esat in hPa
		copy_VarCoords(Q,wsat)
		delete(esat)

		;------------ compute saturation specific humidity and delta-q
		Qsat	= wsat/(1.+wsat)
		;----- in some cases, Qsat is < 0.  delete these and interpolate
		Qsat1d	= ndtooned(Qsat)
		Qsat1d@_FillValue			= Qsat@_FillValue
		bad		= ind(Qsat1d.lt.0)
		if (.not.all(ismissing(bad)))
			Qsat1d(bad)	= Qsat@_FillValue
			Qsat	= onedtond(Qsat1d,dimsizes(Qsat))
			Qsat	= linmsg_n(Qsat, (/-1,5/), 0)
		end if
		delete(bad)
		;----- finished interpolating missing data

		delQ	= wsat/(1.+wsat) - Qtemp
		;----- in some cases, Qsat is < 0.  delete these and interpolate
		delQ1d	= ndtooned(delQ)
		delQ1d@_FillValue			= delQ@_FillValue
		bad		= ind(Qsat1d.lt.0)
		if (.not.all(ismissing(bad)))
			Qsat1d(bad)	= Qsat@_FillValue
			Qsat	= onedtond(Qsat1d,dimsizes(Qsat))
			Qsat	= linmsg_n(Qsat, (/-1,5/), 0)
		end if
		delete(bad)
		;----- finished interpolating missing data
		copy_VarCoords(Q,delQ)
		copy_VarCoords(Q,Qsat)
		delQ@units		= "kg/kg"
		delQ@long_name	= "delta-q"
		Qsat@units		= "kg/kg"
		Qsat@long_name	= "Sfc. q*"
		delete(wsat)
		
		;------------ write out daily mean computed fields
		filo	= diro + caseName + "." + sstName + "_smSST."+ dateStr + "." + latbandStr + ".day.mean.nc"
		system("/bin/rm -f "+filo)
		ncdf	= addfile(filo,"c")
		xName	= sstName+"_smSST"
		ncdf->$xName$	= SST_smSST

		filo			= diro + caseName + ".delQ_smSST."+ dateStr + "." + latbandStr + ".day.mean.nc"
		system("/bin/rm -f "+filo)
		ncdf			= addfile(filo,"c")
		ncdf->delQ_smSST= delQ

		filo			= diro + caseName + ".Qsat_smSST."+ dateStr + "." + latbandStr + ".day.mean.nc"
		system("/bin/rm -f "+filo)
		ncdf			= addfile(filo,"c")
		ncdf->Qsat_smSST= Qsat
		
		delete(delQ)
		delete(Qsat)
		delete(SST_C)
		delete(SfcPressure_mb)

; DELTA-T:
;------------------------------------------------------------

	print("delta-T...")

	filt	= diri + caseName + "." + tName + "."+ dateStr + "." + latbandStr + ".day.mean.nc"
	f		= addfile(filt, "r")  
	date	= cd_calendar(f->$timeName$, -2)   ; entire file
	time	= f->$timeName$						; for use in next section
	iStrt	= 0      			; desired dates
	iLast	= dimsizes(date)-1
	delete(date)
									  
	if (dimsizes(getfilevardims(f,tName)) .eq. 4) then
	  if (getfilevartypes(f,tName) .eq. "short") then
		  T  = short2flt( f->$tName$($timeName$|iStrt:iLast,$levName$|:,{$latName$|latS_globe:latN_globe},$lonName$|:) ) 
		  Tnew  = rm_single_dims(T)
		  delete(T)
		  T	= Tnew
		  delete(Tnew)
	  else
		  T  = f->$tName$($timeName$|iStrt:iLast,$levName$|:,{$latName$|latS_globe:latN_globe},$lonName$|:)
		  Tnew  = rm_single_dims(T)
		  delete(T)
		  T	= Tnew
		  delete(Tnew)
	  end if
	else
	  if (getfilevartypes(f,tName) .eq. "short") then
		  T  = short2flt( f->$tName$($timeName$|iStrt:iLast,{$latName$|latS_globe:latN_globe},$lonName$|:) ) 
	  else
		  T  = f->$tName$($timeName$|iStrt:iLast,{$latName$|latS_globe:latN_globe},$lonName$|:)
	  end if
	end if

	;------------ force SST to K
	if (max(SST).gt.273.) then
		SST_K = SST
	else
		SST_K = SST + TK
	end if
	
	;------------ compute delta-T (full and smoothed SST)
	delT				= SST_K - T							; full SST
	delT_smSST			= runave_n_Wrap(SST_K,61,1,0) - T	; smoothed SST
	copy_VarCoords(T,delT)
	copy_VarCoords(T,delT_smSST)
	delT@units			= "K"
	delT@long_name		= "delta-T"
	delT_smSST@units	= "K"
	delT_smSST@long_name= "delta-T (smoothed SST)"

	;------------ write out daily mean computed fields
	filo			= diro + caseName + ".delT."+ dateStr + "." + latbandStr + ".day.mean.nc"
	system("/bin/rm -f "+filo)
	ncdf			= addfile(filo,"c")
	ncdf->delT		= delT

	filo			= diro + caseName + ".delT_smSST."+ dateStr + "." + latbandStr + ".day.mean.nc"
	system("/bin/rm -f "+filo)
	ncdf			= addfile(filo,"c")
	ncdf->delT_smSST= delT_smSST

	delete(delT)
	delete(delT_smSST)
	delete(SST_K)


; dSST/dt:
;------------------------------------------------------------

	print("dSST/dt...")
	dSSTdt		= SST
	dSSTdt		= runave_n_Wrap(SST,5,1,0)	; apply 5-day running mean
	ndims		= dimsizes(dSSTdt)
	dSSTdt(1:ndims(0)-2,:,:)	= 0.5*(dSSTdt(2:ndims(0)-1,:,:) - dSSTdt(0:ndims(0)-3,:,:))
	dSSTdt(0,:,:)				= dSSTdt(1,:,:)
	dSSTdt(ndims(0)-1,:,:)		= dSSTdt(ndims(0)-2,:,:)
	dSSTdt@units				= "K/day"
	dSSTdt@long_name			= "SST warming rate"
	dSSTdt@calculation			= "5-day smoothing applied, 3-day centered warming rate"
	dSSTdt&$timeName$			= SST&$timeName$

	;------------ write out daily mean computed fields
	filo			= diro + caseName + ".dSSTdt."+ dateStr + "." + latbandStr + ".day.mean.nc"
	system("/bin/rm -f "+filo)
	ncdf			= addfile(filo,"c")
	xName			= "dSSTdt"
	ncdf->$xName$	= dSSTdt

	delete(dSSTdt)

; SURFACE RH:
;------------------------------------------------------------

	print("RH...")
	;------------ force SfcP to Pa units
	if (max(SFCP).gt.1200.) then ; calculation below requires pressure in mb.
		SfcPressure_Pa	= SFCP
	else
		SfcPressure_Pa = SFCP*100.
	end if
	
	;------------ force T to K units
	if (max(T).lt.273.) then ; calculation below requires T in Kelvin.
		T	= T + TK
	end if
	
	;------------ force Q to kg/kg units
	if (max(Q).gt.1.) then ; calculation below requires Q in kg/kg.
		Q	= Q * .001
	end if
	
	; compute daily mean near-surface RH
	RH			= relhum(T,Q,SfcPressure_Pa)
	copy_VarMeta(T,RH)
	RH@units	= "%"
	RH@long_name= "near-surface RH"

	;------------ write out daily mean fields
	filo		= diro + caseName + ".RHsfc."+ dateStr + "." + latbandStr + ".day.mean.nc"
	system("/bin/rm -f "+filo)
	ncdf		= addfile(filo,"c")
	ncdf->RHsfc= RH



end
	





