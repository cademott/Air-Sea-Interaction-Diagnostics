load "./Resources/contrib_AirSea.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/contrib/kf_filter.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/diagnostics_cam.ncl"

begin
	print("============== in make_L2.3_wkSpaceTime_AirSea.ncl ==============")

	;----------- suppress warnings?
	debug		= getenv("DEBUG")
	if (debug.eq."false") then
		err = NhlGetErrorObjectId()
		setvalues err
			"errLevel" : "Fatal"          ; only report Fatal errors
		end setvalues
	end if

	;------------- define input variable names 
	diri			= getenv("FILEDIR") + "/"
	dirp			= getenv("FILEDIR")+"/plots/"
	diro			= getenv("FILEDIR")+"/proc/"
	caseName		= getenv("caseName")
	twStrt			= getenv("YMDSTRT")
	twLast			= getenv("YMDLAST")
	dateStr			= getenv("FILESUFFSTR")
	inName1			= getenv("inName1")
	Name1			= inName1
	inName1			= inName1 + "_anom_sm"
	timeName		= getenv("TIMEVAR")
	latName			= getenv("LATNAME")
	lonName			= getenv("LONNAME")
	sstName			= getenv("SSTVARNAME")
	lhName			= getenv("LHVARNAME")
	shName			= getenv("SHVARNAME")
	lwName			= getenv("LWVARNAME")
	swName			= getenv("SWVARNAME")
	qName			= getenv("QVARNAME")
	tName			= getenv("TKVARNAME")
	sstName			= getenv("SSTVARNAME")
	sfcpName		= getenv("SFCPVARNAME")
	pName			= getenv("RAINVARNAME")
	rainFstr		= getenv("RAINFACTOR")

	;----------- define latitude string
	latSstr			= getenv("latSouth")
	latNstr			= getenv("latNorth")
	latS_globe		= stringtofloat(latSstr)
	latN_globe		= stringtofloat(latNstr)
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

	;----------- define input file name
	inFile1			= diri + caseName + "." + Name1 + "."+ dateStr + "." + latbandStr + ".day.background.anom.nc"

	print("variable 	= " + Name1)


	;----------- read in the data
	latN			= 15
	latS     		= -latN		; symmetric about the equator
	f 				= addfile (inFile1, "r") 
	date			= cd_calendar(f->$timeName$, -2)
	iStrt 			= ind(date.eq.twStrt)				; desired dates
	iLast 			= ind(date.eq.twLast)
	time			= f->$timeName$(iStrt:iLast)
	ndays			= dimsizes(time)
	if (ndays.ge.7300) then
		iLast		= iStrt + 7299	; only process 1st 20 years to speed up this step
	end if
	data			= f->$inName1$($timeName$|iStrt:iLast,{$latName$|latS:latN},$lonName$|:)	; (time,lat,lon)
	data			= linmsg(data,-1)			; fill in any missing data
	
	;printMinMax(data,True)
	;printVarSummary(data)
  
	;----------- apply uniform variable naming conventions
	outvarName1		= Name1
	if (Name1.eq.swName) then
		outvarName1	= "SWsfc"
	end if
	if (Name1.eq.lwName) then
		outvarName1	= "LWsfc"
	end if	
	if (Name1.eq.lhName) then
		outvarName1	= "LHFLX"
	end if	
	if (Name1.eq.shName) then
		outvarName1	= "SHFLX"
	end if	
	if (Name1.eq.pName) then
		outvarName1	= "PRECT"
	end if	
	if (Name1.eq.qName) then
		outvarName1	= "Qair"
	end if	
	if (Name1.eq.tName) then
		outvarName1	= "Tair"
	end if	
	if (Name1.eq.sstName) then
		outvarName1	= "SST"
	end if	
	if (Name1.eq.sstName+"_smSST") then
		outvarName1	= "SST_smSST"
	end if		
	if (Name1.eq.sfcpName) then
		outvarName1	= "SFCP"
	end if		
	print("outvarName1	= "+outvarName1)

	;----------- define processing details and output file name
	nDayWin  		= 96		; Wheeler-Kiladis [WK] temporal window length (days)
	nDaySkip 		= 30		; time (days) between temporal windows [segments]
								; negative means there will be overlapping 
								; temporal segments
	outfile			= caseName + "." + Name1 + "."+ twStrt + "-" + twLast + ".wkSpaceTime.nc"
	opt      		= True
	opt@pltType		= "pdf"
	opt@netCDF		= True
	opt@dirNetCDF	= diro
	opt@filNetCDF	= outfile
	opt@cnLinesOn	= False		; turn off contour lines
	units			= data@units

	;----------- check MSE units
	if (Name1.eq."Vmse") then
		data	= data * 1e-06
		data@units	= "1E06 J/kg"
	end if
	
	;----------- check precipitation units
	if (Name1.eq.pName) then
		rainfact	=stringtofloat(rainFstr)
		print("rain factor = " + rainfact)
		data		= data * rainfact
		data@units		= "mm/day"
	end if

	;----------- check specific humidity units
	if (data@units.eq."kg/kg".or.data@units.eq."kg kg**-1") then
		data		= data * 1000.
		data@units		= "g/kg"
	end if

	;----------- check specific humidity units
	if (data@units.eq."Pa") then
		data		= data * .01
		data@units		= "mb"
	end if

	;----------- select uniform contour interval for raw, smoothed spectra based on data stdev
	sd				= stddev(data)
	print("sd	= "+sd)
	opt				= True
	if (sd.lt.2) then
		opt@Fig_1	= decimalPlaces(fspan(-3,0,16),2,1)
		opt@Fig_2	= opt@Fig_1
	else
		opt@Fig_1	= decimalPlaces(fspan(-2,2,16),2,1)
		opt@Fig_2	= opt@Fig_1
	end if

	opt@pltTitle	= caseName + " " + Name1 + " [log10(" + units + ")]"
	opt@Fig_3a		= (/ 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1., 1.1, 1.2, 1.4, 1.7, 2.0, 2.4, 2.8 /)
	opt@Fig_3b		= opt@Fig_3a

	spd				= 1				; samples per day (6 hour sampling rate)
	var				= inName1		; user specified 

;	printVarSummary(data)
;	print("dirp = "+dirp)
;	print("caseName = "+caseName)
;	print("Name1 = "+Name1)
;	print("latN = "+latN)
;	print("spd = "+spd)
;	print("nDayWin = "+nDayWin)
;	print("nDaySkip = "+nDaySkip)
;	print("opt = "+opt)
;	printVarSummary(opt)
;	print("dimsizes(opt@Fig_1) = "+dimsizes(opt@Fig_1))
;	print("dimsizes(opt@Fig_2) = "+dimsizes(opt@Fig_2))
;	print("dimsizes(opt@Fig_3a) = "+dimsizes(opt@Fig_3a))
;	print("dimsizes(opt@Fig_3b) = "+dimsizes(opt@Fig_3b))
	;-----------  calculation and create plots
	
	;----------- change name of variable if PRECT.  diagnostics_cam.ncl
	;----------- tries to set the number of contour intervals to something
	;----------- other than what is specified above, and causes the program
	;----------- to crash.
	if (Name1.eq."PRECT") then ; PRECT causes a conflict in diagnostics_cam.ncl w
		tName	= "Rain"
	else
		tName	= Name1
	end if
	wkSpaceTime(data,dirp,caseName,tName,latN,spd,nDayWin,nDaySkip,opt)
   	
end