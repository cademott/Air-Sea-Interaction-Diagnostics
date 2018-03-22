load "./Resources/contrib_AirSea.ncl"
  
;******************** MAIN **********************************
begin
                           
	print(" ")
	print("============= in program make_L1.2a_background_anomaly_2Dfield.nc =============")

	;----------- suppress warnings?
	debug		= getenv("DEBUG")
	if (debug.eq."false") then
		err = NhlGetErrorObjectId()
		setvalues err
			"errLevel" : "Fatal"          ; only report Fatal errors
		end setvalues
	end if

	;------------- define dynamic variables
	diri		= getenv("FILEDIR") + "/"
	diro		= diri
	caseName	= getenv("caseName")
	twStrt		= getenv("YMDSTRT")
	twLast		= getenv("YMDLAST")
	dateStr		= getenv("FILESUFFSTR")
	inName		= getenv("inName")
	timeName	= getenv("TIMEVAR")
	levName		= getenv("LEVNAME")
	latName		= getenv("LATNAME")
	lonName		= getenv("LONNAME")
	pName		= getenv("RAINVARNAME")	; special case for rainfall
	
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
	print("var  = " + inName)

	;------------- define input filename
	inFile		= diri + caseName + "." + inName + "."+ dateStr + "." + latbandStr + ".day.mean.nc"
	print("file = " + inFile)

	;------------- date checking
	f		= addfile(inFile, "r")  
	date	= cd_calendar(f->$timeName$, -2)	; entire file
	iStrt  = 0      			; desired dates
	iLast  = dimsizes(date)-1
	print("iStrt = "+iStrt+"   iLast = "+iLast)
	delete(date)
	
	;------------- read data
	; sometimes DATA=DATA(time,lev,lat,lon) where dimsize(lev)=1.
	; what we want is DATA=DATA(time,lat,lon)
	;if (inName.eq."Qsfc") then
	;	print("vardims = "+getfilevardims(f,inName))
	;	print("ndims = "+dimsizes(getfilevardims(f,inName)))
	;	print("vartype = "+getfilevartypes(f,inName))
	;end if
	if (dimsizes(getfilevardims(f,inName)) .eq. 4) then
	  if (getfilevartypes(f,inName) .eq. "short") then
		  DATA		= short2flt( f->$inName$($timeName$|iStrt:iLast,$levName$|:,{$latName$|latS_globe:latN_globe},$lonName$|:)) 
		  DATAnew	= rm_single_dims(DATA)
		  delete(DATA)
		  DATA		= DATAnew
		  delete(DATAnew)
	  else
		  DATA		= f->$inName$($timeName$|iStrt:iLast,$levName$|:,{$latName$|latS_globe:latN_globe},$lonName$|:)
		  DATAnew	= rm_single_dims(DATA)
		  delete(DATA)
		  DATA		= DATAnew
		  delete(DATAnew)
	  end if
	else
	  if (getfilevartypes(f,inName) .eq. "short") then
		  DATA		= short2flt( f->$inName$($timeName$|iStrt:iLast,{$latName$|latS_globe:latN_globe},$lonName$|:)) 
	  else
		  DATA		= f->$inName$($timeName$|iStrt:iLast,{$latName$|latS_globe:latN_globe},$lonName$|:)
	  end if
	end if
	

	;------------- define time and date variables
	time	= DATA&$timeName$
	date	= cd_calendar(time, -2 )			; yyyymmdd
	TIME    = cd_calendar(time, 0)				; type float 
	year    = floattointeger( TIME(:,0) )
	month   = floattointeger( TIME(:,1) )
	day     = floattointeger( TIME(:,2) ) 
	if (isatt(time,"calendar")) then
		year@calendar = time@calendar 		; needed for day_of_year
	end if
	ddd     = day_of_year(year, month, day) 
	yyyyddd = year*1000 + ddd					; needed for clmDayTLL
	if (isatt(time,"calendar")) then
		yyyyddd@calendar = time@calendar 		; needed for clmDayTLL
	end if
  
	;------------- compute the background smoothed time series
	ndays			= 61
	DATA_bg			= runave_n_Wrap(runave_n_Wrap(DATA,ndays,1,0),ndays,1,0) ; opt=1 mean reflective endpoints, usually OK
	print(DATA_bg@long_name)
	
	;------------- compute anomaly time series
	DATA_anom		= DATA ; copy metadata
	DATA_anom		= DATA - DATA_bg
	print(DATA_anom@long_name)

	DATA_anom@calculation	= "departure from 61-day running mean (reflection used at endpoints)"
	DATA_bg@calculation	= ndays + "-day running mean (reflection used at endpoints)"

	;------------- write data to file
	filo	= diro + caseName + "." + inName + "."+ dateStr + "." + latbandStr + ".day.background.anom.nc"
	print("output file = "+filo)
	system("/bin/rm -f "+filo)      ; rm any pre-exist file, if any
	ncdf	= addfile(filo,"c")
	xName	= inName+"_anom_sm"
	ncdf->$xName$	= DATA_anom
	xName	= inName+"_bg"
	ncdf->$xName$	= DATA_bg

	delete(DATA)
	delete(DATA_anom)
	delete(DATA_bg)
	delete(time)
	delete(date)

end