load "./Resources/contrib_AirSea.ncl"

begin

	print("=============== in make_L2.2_differences_DiffGrid.ncl =================")

	fName1		= getenv("inFile")
	fName2		= getenv("obsFile")
	;print("fName1 = " + fName1)
	;print("fName2 = " + fName2)
	var1		= getenv("inVar1")
	var2		= getenv("inVar2")
	season		= getenv("iSeason")
	progGen		= getenv("progGen")
	diro		= getenv("DIRO")
	modName		= getenv("MODNAME")
	obsName		= getenv("OBSNAME")

	
	f1			= addfile(fName1,"r")
	dataMod		= f1->$var2$
	
	f2			= addfile(fName2,"r")
	dataObs		= f2->$var2$
	
	
	dataDiff = dataMod
	dataDiff = 0.
	
	olon		= dataObs&lon
	olag		= dataObs&lag
	mlon		= dataMod&lon
	mlag		= dataMod&lag
	dataDiff	= dataMod - (/ area_hi2lores(olon,olag,dataObs,True,1,mlon,mlag,False) /)
	
	copy_VarMeta(dataMod,dataDiff)
	delete_VarAtts(dataDiff,(/ "tval","rstd","nptxy","xave","yave","yintercept" /) )
	;printVarSummary(dataDiff)
	;printMinMax(dataMod(0,:,:),True)
	;printMinMax(dataObs(0,:,:),True)
	;printMinMax(dataDiff(0,:,:),True)
	
	filo		= diro + modName + "_minus_" + obsName + "." + progGen + "." + var1 + "." + var2 + "." + season + ".nc"
	
	system("rm -f " + filo)
	fo			= addfile(filo,"c")
	fo->$var2$	= dataDiff
	
	print("output file = " + filo)
	
end
