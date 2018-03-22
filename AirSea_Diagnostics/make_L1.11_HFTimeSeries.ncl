load "./Resources/contrib_AirSea.ncl"

begin
	print("")
	print("============== in make_L1.11_HFTimeSeries.ncl ==============")

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
	if (inName.eq.rainName) then
		factor	= stringtofloat(getenv("RAINFACTOR"))
		data	= data * factor
		data@units	= "mm/day"
	end if
	printMinMax(data,True)

	;----- generate filter weights (20-day cutoff frequency)
	spd			= 1.		; samples per day
	t1			= 20.	; days
	nwt			= 51	; # filter points
	fca			= spd/t1
	nsigma		= 1.
	ihp			= 1		; high-pass filter
	wgt			= filwgts_lanczos (nwt, ihp, fca, -999., nsigma)  
	
	temp		= wgt_runave_Wrap(data($latName$|:,$lonName$|:,$timeName$|:),wgt,0)
	dataf		= temp($timeName$|:,$latName$|:,$lonName$|:)
	delete(temp)
	printMinMax(dataf,True)
	
	;----- compute running variance
	nseg					= 31
	nhalf					= (nseg-1)/2
	data_runvar				= dataf
	do i=nhalf,dimsizes(dataf&$timeName$)-1-nhalf
		data_runvar(i,:,:)	= dim_variance_n(dataf(i-nhalf:i+nhalf,:,:),0)
	end do
	
	;----- subtract background running variance.  HP running variance may still have a seasonal cycle
	;		since our initial smoothing of the input series only removed low-frequency variability.
	data_runvar				= data_runvar - runave_n(runave_n(data_runvar,61,30,0),61,30,0)
	data_runvar@long_name	= "anomalous 31-day running variance (departure fro 61-day running mean)"
	
	;----- write filtered data to file
	filo 		= caseName + "." + inName + "." + "HiPass_filtered." + dateStr + "." + latbandStr + ".nc"
	print("writing output to " + diro+filo)
	system("/bin/rm -f "+diro+filo)
	ncdf 			= addfile(diro+filo,"c")
	filedimdef(ncdf,timeName,-1,True)
	outName			= inName + "_hp20"
	ncdf->$outName$ = dataf($timeName$|:,$latName$|:,$lonName$|:)
	outName			= inName + "_runvar_anom"
	ncdf->$outName$ = data_runvar($timeName$|:,$latName$|:,$lonName$|:)
	   

end