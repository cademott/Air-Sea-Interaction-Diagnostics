load "../Resources/contrib_AirSea.ncl"

begin

	print("=============== in plot_MultiModel_MSEbudget_regressions_1col.ncl =================")

	;----------- suppress warnings?
	debug		= getenv("DEBUG")
	if (debug.eq."false") then
		err = NhlGetErrorObjectId()
		setvalues err
			"errLevel" : "Fatal"          ; only report Fatal errors
		end setvalues
	end if

	;------------- define season names
	seasonName 	= (/ "Nov-Apr", "May-Oct" /)

	;------------- get global environmental variables
	fPrefix			= getenv("FilePrefix")
	nCases			= toint(getenv("nCases"))
	nRows			= toint(getenv("nRows"))
	pType			= getenv("PTYPE")
	dirp			= getenv("dirp")	
	varName			= getenv("varName")	
	PanelStrt		= getenv("panelLabStrt")
	baseVar			= getenv("baseVar")
	AxisFontHt		= tofloat(getenv("AxisFontHt"))
	TitleFontHt		= tofloat(getenv("TitleFontHt"))
	PanelFontHt		= tofloat(getenv("PanelFontHt"))
	LabelBarFontHt	= tofloat(getenv("LabelBarFontHt"))
	print("PanelStrt="+PanelStrt)	
	print("nCases 	= " + nCases)
	print("baseVar 	= " + baseVar)
	print("varName 	= " + varName)

	;------------- plot resources for base plot
	res                     	= True
	res@gsnDraw 				= False			; don't draw
	res@gsnFrame				= False			; don't advance frame
	res@cnLineLabelsOn			= False
	res@cnInfoLabelOn			= False 		; turn off cn info label
	res@cnFillOn				= True			; turn on color
	res@cnLinesOn				= True			; turn off contour lines
	res@cnLineColor				= "grey60"
	res@gsnSpreadColors			= True			; spread out color table
	res@gsnSpreadColorStart		= 2 
	res@gsnSpreadColorEnd		= -3 
	res@tmXBLabelsOn			= False
	res@tmXBLabelFontHeightF	= AxisFontHt         ; change maj lat tm spacing
	res@tmYLLabelFontHeightF	= AxisFontHt         ; change maj lat tm spacing
	res@mpMinLatF				= -30.
	res@mpMaxLatF				=  30.
	res@mpMinLonF 				=  30.
	res@mpMaxLonF				= 240.
	res@mpCenterLonF			= 135. 
	res@cnLevelSelectionMode	= "ManualLevels"   
	res@lbLabelBarOn			= False

	;------------- set up plot panels, contours, labels, units
	plot 				= new(nCases,graphic)   	; double the number to utilize left-column only
	metafile			= "contours_Season_MSEbudget_regression_Maps.txt"
	vName				= systemfunc("cut -d , -f1 "+metafile)
	cnMin				= tofloat(systemfunc("cut -d , -f2 "+metafile)) 
	cnMax				= tofloat(systemfunc("cut -d , -f3 "+metafile)) 
	cnInt				= tofloat(systemfunc("cut -d , -f4 "+metafile)) 
	landmask			= str_left_strip(systemfunc("cut -d , -f5 "+metafile))
	varID				= ind(vName.eq.varName)
	maskID				= landmask(varID)
	res@cnMinLevelValF	= cnMin(varID)
	res@cnMaxLevelValF	= cnMax(varID)
	res@cnLevelSpacingF	= cnInt(varID) 
	if (baseVar.eq."Vmse" .and. (varName.eq."LHFLX" .or. varName.eq."SHFLX")) then
		res@cnMinLevelValF	= res@cnMinLevelValF * 0.5
		res@cnMaxLevelValF	= res@cnMaxLevelValF * 0.5
		res@cnLevelSpacingF	= res@cnLevelSpacingF * 0.5
	end if			
	delete(vName)
				
	;------------- set up panel labels, units
	metafile			= "../Resources/variable_labels_units.txt"
	vName				= systemfunc("cut -d , -f1 "+metafile)
	label				= str_left_strip(systemfunc("cut -d , -f2 "+metafile))
	units				= str_left_strip(systemfunc("cut -d , -f3 "+metafile))
	varID				= ind(vName.eq.varName)
	PlotLabel			= label(varID)
	DataUnits			= units(varID)
	mseLabel			= label(ind(vName.eq."Vmse"))
	dmdtLabel			= label(ind(vName.eq."Vdmdt"))
	delete(vName)


	do s = 0,1 				; do for each season

		;----------- set up plot file
		wksType = pType
		if (fPrefix.eq."") then
			wksName	= dirp + "MultiModel_MSEbudget_regressions_1col." + baseVar + "." + varName + "." + seasonName(s)
		else
			wksName	= dirp + fPrefix + ".MultiModel_MSEbudget_regressions_1col." + baseVar + "." + varName + "." + seasonName(s)
		end if
		wks = gsn_open_wks(wksType,wksName)		; open a ps file
		gsn_define_colormap(wks,"cmp_b2r")

		do n=0,nCases-1
			
			;------------- get case-specific environmental variables
			MODNAME		= "MODNAME"	+ tostring(n)
			MODDIR		= "MODDIR" + tostring(n)
			MODDATES	= "MODDATES"+ tostring(n)
			caseName	= getenv(MODNAME)
			diri		= getenv(MODDIR) + "/proc/"
			dateRange	= getenv(MODDATES)		
			;print("caseName = " + caseName)
						
			;------------ read in the data
			fili			= diri + caseName + ".make_L3.1_regression_map."+ dateRange + "." +  baseVar + "." + varName + "." + seasonName(s) +".nc"
			f				= addfile(fili,"r")
			tName			= "regData"
			data_mean		= f->$tName$
		
			;------------ convert to familiar units
			if (baseVar.eq."Vmse") then
				data_mean		= data_mean * 100. * 86400.	; convert to % MSE per day
				data_mean@units	= "% " + mseLabel + " day~S2~-1"
				baseLabel		= mseLabel
				;printMinMax(data_mean,True)
			else
				data_mean		= data_mean * 100.			; convert to % dMSE/dt
				data_mean@units	= "% " + dmdtLabel
				baseLabel		= dmdtLabel
			end if

			;------------ define land mask
			if (maskID.eq."mask") then
				lon		= f->lon
				lat		= f->lat			
				a    	= addfile("$NCARG_ROOT/lib/ncarg/data/cdf/landsea.nc","r")
				lsdata	= a->LSMASK
				lsm		= landsea_mask(lsdata,lat,lon)
				data_mean	= mask(data_mean,lsm.ge.1,False)
				delete(lat)
				delete(lon)
				delete(lsm)
			end if
	
			;------------ turn on longitude labels for bottom panels
			if (n.eq.nCases-1) then
				res@tmXBLabelsOn			= True
			end if

			;------------ make panel plots
			data_mean@long_name		= caseName
			plot(n)					= gsn_csm_contour_map_ce(wks,smth9_Wrap(data_mean,0.5,0.25,True),res)

			delete(data_mean)
		
		end do
	
		;------------- create plot page
		pStr		= (/"a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z" /)
		pID										= pStr(0:nCases-1)
		resP									= True                   	; modify the panel plot
		resP@gsnFrame							= False                  	; don't advance panel plot
		resP@gsnPanelMainString					= label(varID) + " projection onto " + baseLabel + ", " + seasonName(s); add common title
		resP@gsnPanelMainFontHeightF			= TitleFontHt
		resP@gsnPanelRight						= 0.995
		resP@gsnPanelBottom						= 0.05                   	; add space at bottom
		resP@gsnPanelYWhiteSpacePercent 		= 4
		resP@gsnPanelFigureStrings 				= pID      
		resP@gsnPanelFigureStringsFontHeightF	= PanelFontHt
		resP@gsnPanelFigureStringsPerimOn		= True
		resP@amJust								= "TopLeft"
		resP@gsnPanelLabelBar					= True
		resP@lbLabelFontHeightF					= LabelBarFontHt
		resP@lbAutoManage          				= False             ; we control label bar
		resP@lbOrientation         				= "Horizontal"      ; ncl default is vertical
		resP@pmLabelBarWidthF     				= 0.28                ; default is shorter
		resP@pmLabelBarHeightF     				= 0.02              ; default is taller
		;resP@lbLabelFontHeightF    				= .01               ; default is HUGE
		gsn_panel(wks,plot,(/nRows,1/),resP)                		; now draw as one plot

		if (wksType.eq."png") then
			frame(wks)
			trimPNG(wksName)
		end if

		res@tmXBLabelsOn	= False ; turn off longitude labels for next season
	
	end do				; season loop
	
end