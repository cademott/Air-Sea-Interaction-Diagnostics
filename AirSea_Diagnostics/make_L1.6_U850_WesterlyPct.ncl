load "./Resources/contrib_AirSea.ncl"
  
;******************** MAIN **********************************
begin
                           
	print(" ")
	print("=============== in make_L1.6_U850_WesterlyPct.ncl =================")

	;----------- suppress warnings?
	debug		= getenv("DEBUG")
	if (debug.eq."false") then
		err = NhlGetErrorObjectId()
		setvalues err
			"errLevel" : "Fatal"          ; only report Fatal errors
		end setvalues
	end if

	;------------- change method of setting dynamic variable names
	twStrt		= getenv("YMDSTRT")
	twLast		= getenv("YMDLAST")
	dateStr		= getenv("FILESUFFSTR")
	u850Name	= getenv("U850VARNAME")
	diri		= getenv("FILEDIR") + "/"
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

	;------------- set up time variables
	filu850	= diri + caseName + "." + u850Name + "."+ dateStr + "." + latbandStr + ".day.mean.nc"
	f		= addfile(filu850, "r")  
	date	= cd_calendar(f->$timeName$, -2)				; entire file
	iStrt 	= ind(date.eq.twStrt)				; desired dates
	iLast 	= ind(date.eq.twLast)
	time	= f->$timeName$(iStrt:iLast)	
	printMinMax(date,True)
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
	tName	= u850Name
	if (dimsizes(getfilevardims(f,u850Name)) .eq. 4) then
	  if (getfilevartypes(f,u850Name) .eq. "short") then
		  u850  = short2flt( f->$tName$($timeName$|iStrt:iLast,$levName$|:,{$latName$|latS_globe:latN_globe},$lonName$|:)) 
		  Unew  = rm_single_dims(u850)
		  delete(u850)
		  u850	= Unew
		  delete(Unew)
	  else
		  u850  = f->$tName$($timeName$|iStrt:iLast,$levName$|:,{$latName$|latS_globe:latN_globe},$lonName$|:)
		  Unew  = rm_single_dims(u850)
		  delete(u850)
		  u850	= Unew
		  delete(Unew)
	  end if
	else
	  if (getfilevartypes(f,u850Name) .eq. "short") then
		  u850  = short2flt( f->$tName$($timeName$|iStrt:iLast,{$latName$|latS_globe:latN_globe},$lonName$|:)) 
	  else
		  u850  = f->$tName$($timeName$|iStrt:iLast,{$latName$|latS_globe:latN_globe},$lonName$|:)
	  end if
	end if

	;------------- define output array
	dims				= dimsizes(u850)
	season				= (/ 0, 1 /)
	season@long_name	= "season"
	season@definition	= "0 = Nov-Apr; 1 = May-Oct"
	lon					= u850&$lonName$
	lon@units			= "degrees east"
	lat					= u850&$latName$
	lat@units			= "degrees north"
	pctPos				= new ( (/ 2, dims(1), dims(2) /),"float")	; season x lat x lon
	pctPos!0			= "season"
	pctPos&season		= season		
	pctPos!1			= "lat"
	pctPos&lat			= lat
	pctPos!2			= "lon"
	pctPos&lon			= lon
	pctPos@long_name	= "percent days where U850 > 0"
	pctPos@units		= "%"
	
	do s=0,1					; seasonal loop
	
		;------------- get rid of "other" season
		uSeason				= u850
		if (s.eq.0) then
			uSeason(m2o,:,:)= 0.0
			totDays			= dimsizes(n2a)
		else
			uSeason(n2a,:,:)= 0.0
			totDays			= dimsizes(m2o)
		end if
		;print("totDays = "+totDays)
		
		;------------- calculate percentage days where U > 0
		do j=0,dims(1)-1		; latitude loop
			do i=0,dims(2)-1	; longitude loop
				pctPos(s,j,i)	= 100. * num(ind(uSeason(:,j,i).gt.0)) / int2flt(totDays(0))
			end do
		end do
	
		delete(uSeason)
		
		dataOut				= pctPos(s,:,:)
		dataOut@seasonName	= seasonName(s)
		
		;printVarSummary(pctPos)
		;------------- write output
		filo	= diro + caseName + ".make_L1.6_U850_WesterlyPct." + twStrt + "-" + twLast + ".U850_WestPct." + seasonName(s) + ".nc"
		system("/bin/rm -f "+filo)
		ncdf	= addfile(filo,"c")
		xName	= "U850_WestPct"
		ncdf->$xName$	= dataOut

	end do
	
	printMinMax(pctPos,True)
					

end
	





