load "./Resources/contrib_AirSea.ncl"

;************************************************************
;
; compute seasonal mean u850 for specified time period:
;
;************************************************************
begin
                           
	print(" ")
	print("=============== in make_L1.3a_mean_u850.ncl =================")

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
	u850Name	= getenv("U850VARNAME")
	diro		= getenv("FILEDIR") + "/proc/"
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

	; U850 SEASONAL MEANS:
	;------------------------------------------------------------

	print("u850...")
	;print(u850Name)

	;------------- set up time variables
	filu850	= diri + caseName + "." + u850Name + "."+ dateStr + "." + latbandStr + ".day.mean.nc"
	f		= addfile(filu850, "r")  
	date	= cd_calendar(f->$timeName$, -2)				; entire file

	;------------- NOTE:  compute mean u850 ONLY for time span of interest
	iStrt  = ind(date.eq.twStrt)      			; desired dates
	iLast  = ind(date.eq.twLast)
	delete(date)
	TIME    = cd_calendar(f->$timeName$(iStrt:iLast), 0)	; type float 
	month   = floattointeger( TIME(:,1) )
	
	;------------- define seasons
	n2a		= ind(month.ge.11.or.month.le.4)
	m2o		= ind(month.ge.5.and.month.le.10)
	
	;------------- define season names
	seasonName	= (/ "Nov-Apr","May-Oct" /)
	
	;------------- read data
	; sometimes U=U(time,lev,lat,lon) where dimsize(lev)=1.
	; what we want is U=U(time,lat,lon)
	if (dimsizes(getfilevardims(f,u850Name)) .eq. 4) then
	  if (getfilevartypes(f,u850Name) .eq. "short") then
		  u850  = short2flt( f->$u850Name$($timeName$|iStrt:iLast,$levName$|:,{$latName$|latS_globe:latN_globe},$lonName$|:)) 
		  Unew  = rm_single_dims(u850)
		  delete(u850)
		  u850	= Unew
		  delete(Unew)
	  else
		  u850  = f->$u850Name$($timeName$|iStrt:iLast,$levName$|:,{$latName$|latS_globe:latN_globe},$lonName$|:)
		  Unew  = rm_single_dims(u850)
		  delete(u850)
		  u850	= Unew
		  delete(Unew)
	  end if
	else
	  if (getfilevartypes(f,u850Name) .eq. "short") then
		  u850  = short2flt( f->$u850Name$($timeName$|iStrt:iLast,{$latName$|latS_globe:latN_globe},$lonName$|:)) 
	  else
		  u850  = f->$u850Name$($timeName$|iStrt:iLast,{$latName$|latS_globe:latN_globe},$lonName$|:)
	  end if
	end if

	;------------- compute seasonal mean
	;printVarSummary(u850)
	do s=0,1					; seasonal loop
		;print("s="+s)	
		;------------- get rid of "other" season
		if (s.eq.0) then
			season		= ind(month.ge.11.or.month.le.4)	; Nov-Apr
		else
			season		= ind(month.ge.5.and.month.le.10)	; May-Oct
		end if
		;printVarSummary(season)
	
		u850_smean = dim_avg_n_Wrap(u850(season,:,:),0)
		;------------- write output
		filo	= diro + caseName + ".make_L1.3a_mean_u850." + twStrt + "-" + twLast + ".u850_SeasonMean." + seasonName(s) + ".nc"
		print("filo = " + filo)
		system("/bin/rm -f "+filo)
		ncdf	= addfile(filo,"c")
		xName	= "u850_SeasonMean"
		ncdf->$xName$	= u850_smean
	
		;delete(u850)
		delete(u850_smean)
		delete(season)
		
	end do
end