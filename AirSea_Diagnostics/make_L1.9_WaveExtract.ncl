load "./Resources/contrib_AirSea.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/contrib/kf_filter.ncl"

begin
	print("")
	print("============== in make_L1.9_WaveExtract.ncl ==============")

	;----------- suppress warnings?
	debug		= getenv("DEBUG")
	if (debug.eq."false") then
		err = NhlGetErrorObjectId()
		setvalues err
			"errLevel" : "Fatal"          ; only report Fatal errors
		end setvalues
	end if

	; Retrieve required environment variables
	twStrt		= getenv("YMDSTRT")
	twLast		= getenv("YMDLAST")
	dateStr		= getenv("FILESUFFSTR")
	inName		= getenv("inName")
	caseName	= getenv("caseName")
	dateSt		= getenv("YMDSTRT")
	dateNd		= getenv("YMDLAST")
	rainName	= getenv("RAINVARNAME")
	waveType	= getenv("waveType")

	diri		= getenv("FILEDIR") + "/"
	diro		= diri 		
	caseName	= getenv("caseName")
	timeName	= getenv("TIMEVAR")
	latName		= getenv("LATNAME")
	lonName		= getenv("LONNAME")

	latSstr		= getenv("latSouth")
	latNstr		= getenv("latNorth")
	latS_globe	= stringtofloat(latSstr)
	latN_globe	= stringtofloat(latNstr)
	
	;----- define latitude string
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


	;----- read input data 
	latN				= 30
	latS				= -latN       ; symmetric about the equator
	fili		= diri + caseName + "." + inName + "."+ dateStr + "." + latbandStr + ".day.background.anom.nc"
	vName		= inName + "_anom_sm"  
	f 			= addfile (fili, "r") 
	data		= f->$vName$(:,{latS:latN},:)     ; (time,lat,lon)
	data		= linmsg(data,-1)
;	if (inName.eq.rainName) then
;		factor	= stringtofloat(getenv("RAINFACTOR"))
;		data	= data * factor
;		data@units	= "mm/day"
;	end if
	printMinMax(data,True)

	;----- extract wave type
	print("waveType = " + waveType)
	if (waveType.eq."MRG") then
		pMax = 8			; frequency = 0.125 cpd
		pMin = 3			; frequency = 0.333 cpd
		kMin = -10  		; negative for westward
		kMax = -1
		hMin = 8			; equivalent depth curve
		hMax = 90
		waveName = waveType	
	end if

	if (waveType.eq."ER") then
		pMax = 35		; frequency = 0.028 cpd
		pMin = 9		; frequency = 0.111 cpd
		kMin = -10	  	; negative for westward
		kMax = -1
		hMin = 8		; equivalent depth curve
		hMax = 90
		waveName = "ER"	
	end if

	if (waveType.eq."KW") then
		pMax = 25		; frequency = 0.028 cpd
		pMin = 2		; frequency = 0.111 cpd
		kMin = 1	  	; negative for westward
		kMax = 12
		hMin = 8		; equivalent depth curve
		hMax = 90
		waveName = "KW"	
	end if

	if (waveType.eq."KW_slow") then
		pMax = 28		
		pMin = 10		
		kMin = 1	  	; negative for westward
		kMax = 12
		hMin = 8		; equivalent depth curve
		hMax = 90
		waveName = "KW_slow"	
	end if

	if (waveType.eq."MJO") then
		pMax = 100		; frequency = 0.028 cpd
		pMin = 20		; frequency = 0.111 cpd
		kMin = 1  		; negative for westward
		kMax = 6
		hMin = -9999	; equivalent depth curve
		hMax = -9999
		waveName = "MJO"
	end if


	;----- filter at each latitude band
	spd						= 1       	; 1 sample per day (spd)	  
	data!0					= "time"	; temporarily force to CESM dimension names for kf_filter.ncl
	data!1					= "lat"
	data!2					= "lon"
	dataWave 				= data		; set up a new array to hold filtered data
	dataWave(:,:,:)			= 0
	do band=0,dimsizes(data&lat)-1   
		;dataf 				= kf_filter(data($timeName$|:,$latName$|band,$lonName$|:),spd,pMin,pMax,kMin,kMax,hMin,hMax,waveName)
		dataf 				= kf_filter(data(time|:,lat|band,lon|:),spd,pMin,pMax,kMin,kMax,hMin,hMax,waveName)
		dataWave(:,band,:) 	= dataf
	end do
	dataWave!0				= timeName	; return dimensions to original names
	dataWave!1				= latName
	dataWave!2				= lonName
	
	;----- write filtered data to file
	filo 		= caseName + "." + inName + "." + waveType + "_filtered." + dateStr + "." + latbandStr + ".nc"
	print("writing output to " + diro+filo)
	system("/bin/rm -f "+diro+filo)
	ncdf 			= addfile(diro+filo,"c")
	filedimdef(ncdf,timeName,-1,True)
	ncdf->$waveName$ = dataWave
	   

end