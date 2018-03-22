load "./Resources/contrib_AirSea.ncl"

begin

	diri		= getenv("FILEDIR") + "/"
	caseName	= getenv("caseName")
	inName		= getenv("inName")
	dateStr		= getenv("FILESUFFSTR")
	latSstr		= getenv("latSouth")
	latNstr		= getenv("latNorth")

	latS_globe	= stringtofloat(latSstr)
	latN_globe	= stringtofloat(latNstr)
	
	print("inName		= "+inName)

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

	;------------- define input file and variable names 
	inFile		= diri + caseName + "." + inName + "."+ dateStr + "." + latbandStr + ".day.mean.nc"
	;print(inFile)	

	f			= addfile(inFile,"r")
	;printVarSummary(f)
	data		= f->$inName$
	;printVarSummary(data)
	fType		= getfilevartypes(f,inName)
	;print(fType)

	;================= uncomment appropriate line for variable group
	data@_FillValue	= default_fillvalue(fType)
	;data@_FillValue = max(data)
	;data@_FillValue = min(data)
	;====================================================
	
	;------------- overwrite the old variable with the new variable (that includes _FillValue) 
	outFile			= diri + "temp.nc"
	system("/bin/rm -f "+outFile) ; remove if already exists
	fout			= addfile(outFile,"c")
	fout->$inName$	= data
	system("mv "+outFile+" "+inFile)      ; copy temp.nc to original input file
	
end

