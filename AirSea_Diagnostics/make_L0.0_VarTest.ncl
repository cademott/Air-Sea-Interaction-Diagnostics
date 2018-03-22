load "./Resources/contrib_AirSea.ncl"

begin

	; get variables names
	caseName	= getenv("caseName")
	diri		= getenv("FILEDIR") + "/"
	twStrt		= getenv("YMDSTRT")
	twLast		= getenv("YMDLAST")
	dateStr		= getenv("FILESUFFSTR")
	timeName	= getenv("TIMEVAR")
	vName		= getenv("VARNAME")
	pName		= getenv("RAINVARNAME")
	uName		= getenv("UVARNAME")
	vName		= getenv("VVARNAME")
	u850Name	= getenv("U850VARNAME")
	lhName		= getenv("LHVARNAME")
	shName		= getenv("SHVARNAME")
	lwName		= getenv("LWVARNAME")
	swName		= getenv("SWVARNAME")
	qName		= getenv("QVARNAME")
	tName		= getenv("TKVARNAME")
	sstName		= getenv("SSTVARNAME")
	sfcpName	= getenv("SFCPVARNAME")
	lonName		= getenv("LONNAME")
	latName		= getenv("LATNAME")
	latSstr		= getenv("latSouth")
	latNstr		= getenv("latNorth")
	latS_globe	= stringtofloat(latSstr)
	latN_globe	= stringtofloat(latNstr)
	
	
	;----------- define latitude string
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
	
;	varName		= (/ vName, vName /)
	varName		= (/ pName, uName, vName, lhName, shName, swName, lwName, qName, tName, \
					 sstName, sfcpName, u850Name, "Vlw", "Vsw", "Vmse", "Vdmdt", "Vm_hadv", \
					 "Vudmdx", "Vvdmdy", "Vomegadmdp" /)


	;--------------- lat/lon coordinates accepted by NCL plotting routines AND cdo operators
	lonUnits	= (/ "degrees_east",  "degrees_E" /)
	latUnits	= (/ "degrees_north", "degrees_N" /)

	;--------------- arrays to track misnamed lat/lon units
	noLonUnit	= new( (/dimsizes(varName)/), "integer", 0)	
	noLatUnit	= new( (/dimsizes(varName)/), "integer", 0)	
	LonUnitName	= new( (/dimsizes(varName)/), "string", default_fillvalue("string"))
	LatUnitName	= new( (/dimsizes(varName)/), "string", default_fillvalue("string"))
	
	;--------------- arrays to track missing _FillValue attributes
	noFill		= new( (/dimsizes(varName)/), "integer", 0)	
	nfMin		= new( (/dimsizes(varName)/), "float",0)
	nfMax		= new( (/dimsizes(varName)/), "float",0)
	
	;--------------- arrays to track min/max of input data
	dataMin		= new( (/dimsizes(varName)/), "float",0)
	dataMax		= new( (/dimsizes(varName)/), "float",0)
	
	;--------------- arrays to track beginning/end dates and no. of unique time steps
	noSpan		= new( (/dimsizes(varName)/), "integer", 0)	
	fBeg		= new( (/dimsizes(varName)/), "integer",0)
	fEnd		= new( (/dimsizes(varName)/), "integer",0)
	nTimesExp	= new( (/dimsizes(varName)/), "integer",0) ; expected number of time steps
	nTimesAct	= new( (/dimsizes(varName)/), "integer",0) ; actual number of time steps
	
	do v=0,dimsizes(varName)-1

		filName		= diri + caseName + "." + varName(v) + "." + dateStr + "." + latbandStr + ".day.mean.nc"

		;---------------- check for _FillValue attribute
		print(" ")
		print(" ")
		print("============= " + varName(v) + "===============")
		print("input file = " + filName)
		f		= addfile(filName,"r")
		data	= f->$varName(v)$
		;printVarSummary(data)
		atts	= getfilevaratts(f,varName(v))
		dType	= typeof(data)
		if (dType.eq."double") then
			temp	= data
			delete(data)
			data	= dble2flt(temp)
			delete(temp)
		end if	
		dataMin(v)	= min(data)
		dataMax(v)	= max(data)
		print(" ")
		print("min  = "+dataMin(v)+"		max  "+dataMax(v))
		print(" ")
		if (any(atts.eq."_FillValue").or.any(atts.eq."missing_value")) then
			mv = data@_FillValue
		else
			mv = "no _FillValue or missing_value found"
			noFill(v)	= 1
			nfMin(v)	= min(data)
			nfMax(v)	= max(data)
			print("no _FillValue or missing_value found")
		end if
		delete(data)
		delete(atts)

		;---------------- check the lat,lon units (fixme:  and fix if necessary)
		lon			= f->$lonName$
		loncheck	= ind(lon@units.eq.lonUnits)
		if (ismissing(loncheck)) then
			noLonUnit(v)	= -1
			LonUnitName(v)	= lon@units
		end if
		print("loncheck = "+loncheck+"  (-1 means units not acceptable)")

		lat			= f->$latName$
		latcheck	= ind(lat@units.eq.latUnits)
		if (ismissing(latcheck)) then
			noLatUnit(v)	= -1
			LatUnitName(v)	= lat@units
		end if
		print("latcheck = "+latcheck+"  (-1 means units not acceptable)")
		
		;---------------- check that input data file spans desired analysis period
		;temp	= f->$timeName$
		;printVarSummary(temp)
		date	= cd_calendar(f->$timeName$, -2)	; entire file
		;printMinMax(temp,True)
		iStrt  = ind(date.eq.twStrt)      			; desired dates
		iLast  = ind(date.eq.twLast)
		print("twStrt = "+twStrt)
		print("twLast = "+twLast)
		printMinMax(date,True)
		if (ismissing(iStrt).or.ismissing(iLast)) then
			print("iStrt = "+iStrt)
			print("iLast = "+iLast)
			noSpan(v)		= 1
			fBeg(v)			= date(0)
			fEnd(v)			= date(dimsizes(date)-1)
			nTimesExp(v)	= iLast - iStrt + 1
			temptime		= f->$timeName$(iStrt:iLast)
			nTimesAct(v)	= dimsizes(temptime)
			delete(temptime)
		else
			delete(date)
			date			= cd_calendar(f->$timeName$(iStrt:iLast), -2)
			fBeg(v)			= date(0)
			fEnd(v)			= date(dimsizes(date)-1)
			nTimesExp(v)	= iLast - iStrt + 1
			nTimesAct(v)	= dimsizes(date)
		end if

		delete(date)
		delete(f)
		delete(mv)
		delete(loncheck)
		delete(latcheck)
		delete(lat)
		delete(lon)
	end do
	
	
    dblquote = integertochar(34) 	; decimal 34 is a double quote in the 
                                    ; standard ASCII table 
	;printVarSummary(noFill)
	print(" ")
	print(" ")
	print("min/max of data field:")
	print("----------------------------------------------------------------------------------")
	do v=0,dimsizes(varName)-1
		print(varName(v)+"		"+dataMin(v)+"	"+dataMax(v))
	end do


	print(" ")
	print(" ")
	print("desired start date	= "+twStrt)
	print("desired end date	= "+twLast)
	print("variable	start date	end date	expected steps	actual steps")
	print("----------------------------------------------------------------------------------")
	do v=0,dimsizes(varName)-1
		print(varName(v)+"		"+fBeg(v)+"	"+fEnd(v)+"	"+nTimesExp(v)+"		"+nTimesAct(v))
	end do
		
	if (any(noFill.eq.1)) then
		noFillVars	= ind(noFill.eq.1)
		print(" ")
		print(" ")
		print("================ The following variables require a _FillValue attribute:")
		do v=0,dimsizes(noFillVars)-1
			print("var	= "+varName(noFillVars(v))+"		min = "+nfMin(noFillVars(v))+"		max = "+nfMax(noFillVars(v)))
		end do
		print("check max/min values reported above, then")
		print("edit make_L0.1_Add_FillValue.ncl and airsea_diagnostics_DB.csh as needed")
		print(" ")
	else
		print(" ")
		print(" ")
		print(" ")
		print("================ All variables have _FillValue attribute; no adjustments needed.")
		print(" ")
	end if
	
	;printVarSummary(noLonUnit)
	if (any(noLonUnit.eq.-1)) then
		noLonVars	= ind(noLonUnit.eq.-1)
		print(" ")
		print(" ")
		print("================ The following variables have non-conforming longitude units:")
		do v=0,dimsizes(noLonVars)-1
			;print("var	= "+varName(noLonVars(v))+"		current unit = "+LonUnitName(noLonVars(v)))
			print("var	= "+varName(noLonVars(v))+"		current unit = "+LonUnitName(noLonVars(v)))
		end do
		print("acceptable units are: 'degree_east',  'degrees_E'")
		print("attributes can be changed using NCO, e.g.:  ncatted -O -a units,lon,o,c,"+dblquote+"degrees_east"+dblquote+" in.nc")
		print(" ")
	else
		print("================ All variables have acceptable longitude units; no adjustments needed.")
		print(" ")
	end if
	
	if (any(noLatUnit.eq.-1)) then
		noLatVars	= ind(noLatUnit.eq.-1)
		print(" ")
		print(" ")
		print("================ The following variables have non-conforming latitude units:")
		do v=0,dimsizes(noLatVars)-1
			print("var	= "+varName(noLatVars(v))+"		current unit = "+LatUnitName(noLatVars(v)))
		end do
		print("acceptable units are: 'degree_north', 'degrees_N'")
		print("attributes can be changed using NCO, e.g.:  ncatted -O -a units,lat,o,c,"+dblquote+"degrees_north"+dblquote+" in.nc")
		print(" ")
	else
		print("================ All variables have acceptable latitude units; no adjustments needed.")
		print(" ")
	end if
		
	


end
		
