load "./Resources/contrib_AirSea.ncl"

begin

	; get variables names
	caseName	= getenv("caseName")
	diri		= getenv("FILEDIR") + "/"
	twStrt		= getenv("YMDSTRT")
	twLast		= getenv("YMDLAST")
	dateStr		= getenv("FILESUFFSTR")
	timeName	= getenv("TIMEVAR")
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
	
;	varName		= (/ pName, uName, vName, lhName, shName, swName, lwName, qName, tName, \
;					 sstName, sfcpName, u850Name, "Vlw", "Vsw", "Vmse", "Vdmdt", "Vm_hadv", \
;					 "Vudmdx", "Vvdmdy", "Vomegadmdp" /)
	varName		= (/ pName, uName, vName, lhName, shName, swName, lwName, qName, tName, \
					 sstName, sfcpName, u850Name /)


	;--------------- lat/lon coordinates accepted by NCL plotting routines
	lonUnits	= (/ "degrees_east",  "degree_east",  "degrees east",  "degrees_E" /)
	latUnits	= (/ "degrees_north", "degree_north", "degrees north", "degrees_N" /)

	;--------------- arrays to track misnamed lat/lon units
	noLonUnit	= new( (/dimsizes(varName)/), "integer")	
	noLatUnit	= new( (/dimsizes(varName)/), "integer")	
	LonUnitName	= new( (/dimsizes(varName)/), "string", default_fillvalue("string"))
	LatUnitName	= new( (/dimsizes(varName)/), "string", default_fillvalue("string"))
	
	;--------------- arrays to track missing _FillValue attributes
	noFill		= new( (/dimsizes(varName)/), "integer")	
	nfMin		= new( (/dimsizes(varName)/), "float")
	nfMax		= new( (/dimsizes(varName)/), "float")
	
	;--------------- arrays to track beginning/end dates and no. of unique time steps
	noSpan		= new( (/dimsizes(varName)/), "integer")	
	fBeg		= new( (/dimsizes(varName)/), "integer")
	fEnd		= new( (/dimsizes(varName)/), "integer")
	nTimesExp	= new( (/dimsizes(varName)/), "integer") ; expected number of time steps
	nTimesAct	= new( (/dimsizes(varName)/), "integer") ; actual number of time steps
	
	do v=0,dimsizes(varName)-1

		filName		= diri + caseName + "." + varName(v) + "." + dateStr + "." + latbandStr + ".day.mean.nc"

		;---------------- check for _FillValue attribute
		print(" ")
		print(" ")
		print("============= " + varName(v) + "===============")
		f		= addfile(filName,"r")
		data	= f->$varName(v)$
		printVarSummary(data)
		atts	= getfilevaratts(f,varName(v))
		print(" ")
		print("min  = "+min(data)+"		max  "+max(data))
		print(" ")
		if (any(atts.eq."_FillValue").or.any(atts.eq."missing_value")) then
			mv 			= data@_FillValue
			noFill(v)	= 0
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
			noLonUnit(v)	= 1
			LonUnitName(v)	= lon@units
		end if

		lat			= f->$latName$
		latcheck	= ind(lat@units.eq.latUnits)
		if (ismissing(latcheck)) then
			noLatUnit(v)	= 1
			LatUnitName(v)	= lat@units
		end if
		
		;---------------- check that input data file spans desired analysis period
		date	= cd_calendar(f->$timeName$, -2)	; entire file
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
	if (any(noFill.eq.1)) then
		noFillVars	= ind(noFill.eq.1)
		print(" ")
		print(" ")
		print(" ")
		print(" ")
		print("================ The following variables require a _FillValue attribute:")
		do v=0,dimsizes(noFillVars)-1
			print("var	= "+varName(noFillVars(v))+"		min = "+nfMin(noFillVars(v))+"		max = "+nfMax(noFillVars(v)))
		end do
		print("edit make_L0.1_Add_FillValue.ncl and airsea_diagnostics_DB.csh as needed")
	end if
	
	if (any(noLonUnit.eq.1)) then
		noLonVars	= ind(noLonUnit.eq.1)
		print(" ")
		print(" ")
		print("================ The following variables have non-conforming longitude units:")
		do v=0,dimsizes(noLonVars)-1
			print("var	= "+varName(noLonVars(v))+"		current unit = "+LonUnitName(noLonVars(v)))
		end do
		print("acceptable units are: 'degrees_east',  'degree_east',  'degrees east',  'degrees_E'")
		print("attributes can be changed using NCO, e.g.:  ncatted -O -a units,lon,o,c,"+dblquote+"degrees east"+dblquote+" in.nc")
	end if
	
	if (any(noLatUnit.eq.1)) then
		noLatVars	= ind(noLatUnit.eq.1)
		print(" ")
		print(" ")
		print("================ The following variables have non-conforming latitude units:")
		do v=0,dimsizes(noLatVars)-1
			print("var	= "+varName(noLatVars(v))+"		current unit = "+LatUnitName(noLatVars(v)))
		end do
		print("acceptable units are: 'degrees_north', 'degree_north', 'degrees north', 'degrees_N'")
		print("attributes can be changed using NCO, e.g.:  ncatted -O -a units,lat,o,c,"+dblquote+"degrees north"+dblquote+" in.nc")
	end if
		
	print(" ")
	print(" ")
	print("desired start date	= "+twStrt)
	print("desired end date	= "+twLast)
	print("variable	start date	end date	expected steps	actual steps")
	print("----------------------------------------------------------------------------------")
	do v=0,dimsizes(varName)-1
		print(varName(v)+"		"+fBeg(v)+"	"+fEnd(v)+"	"+nTimesExp(v)+"		"+nTimesAct(v))
	end do
		

end
		
