load "../Resources/contrib_AirSea.ncl"

begin

	print("=============== in plot_MultiModel_StDev_1col.ncl =================")

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
	FNPrefix		= getenv("FilePrefix")
	nCases			= toint(getenv("nCases"))
	nRows			= toint(getenv("nRows"))
	pType			= getenv("PTYPE")
	dirp			= getenv("dirp")	
	varName			= getenv("varName")	
	PanelStrt		= getenv("panelLabStrt")
	u850_overlay	= getenv("u850_overlay")
	AxisFontHt		= tofloat(getenv("AxisFontHt"))
	TitleFontHt		= tofloat(getenv("TitleFontHt"))
	PanelFontHt		= tofloat(getenv("PanelFontHt"))
	LabelBarFontHt	= tofloat(getenv("LabelBarFontHt"))
	print("PanelStrt="+PanelStrt)	
	print("nCases = " + nCases)
	print("varName = " + varName)
	print("u850_overlay = " + u850_overlay)

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

	;------------- plot resources for u850 overlay plot
	ures                     	= True
	ures@gsnDraw				= False
	ures@gsnFrame				= False
	ures@cnLineLabelsOn			= False
	ures@cnInfoLabelOn			= False
	ures@cnFillOn				= False			; turn off color
	ures@cnLinesOn				= True			; turn on contour lines
	ures@cnLineColor			= "Black"
	if (pType.eq."png") then
		ures@cnLineThicknessF	= 6
	else
		ures@cnLineThicknessF	= 2
	end if
	ures@cnLevels				= (/ 0., 2.5, 5., 7.5 /)
	ures@cnLevelSelectionMode	= "ExplicitLevels"   
	ures@tiXAxisOn				= False
	ures@tiYAxisOn				= False
	ures@tiMainOn				= False

	;------------- set up plot panels, contours
	plot 				= new(nCases,graphic)   	; double the number to utilize left-column only
	metafile			= "contours_Season_StDev_Maps.txt"
	vName				= systemfunc("cut -d , -f1 "+metafile)
	cnMin				= tofloat(systemfunc("cut -d , -f2 "+metafile)) 
	cnMax				= tofloat(systemfunc("cut -d , -f3 "+metafile)) 
	cnInt				= tofloat(systemfunc("cut -d , -f4 "+metafile)) 
	landmask			= str_left_strip(systemfunc("cut -d , -f5 "+metafile))
	varID				= ind(vName.eq.varName)
	maskID				= landmask(varID)
	maskID				= landmask(varID)
	res@cnMinLevelValF	= cnMin(varID)
	res@cnMaxLevelValF	= cnMax(varID)
	res@cnLevelSpacingF	= cnInt(varID) 
	delete(vName)

	;------------- set up panel labels, units
	metafile			= "../Resources/variable_labels_units.txt"
	vName				= systemfunc("cut -d , -f1 "+metafile)
	label				= str_left_strip(systemfunc("cut -d , -f2 "+metafile))
	units				= str_left_strip(systemfunc("cut -d , -f3 "+metafile))
	varID				= ind(vName.eq.varName)
	PlotLabel			= label(varID)
	DataUnits			= units(varID)
		              	
	do s = 0,1 				; do for each season

		;----------- set up plot file
		wksType = pType
		if (FNPrefix.eq."") then
			wksName	= dirp + "MultiModel_StDev_1col." + varName + "." + seasonName(s)
		else
			wksName	= dirp + FNPrefix + ".MultiModel_StDev_1col." + varName + "." + seasonName(s)
		end if
		wks = gsn_open_wks(wksType,wksName)		; open a ps file
		gsn_define_colormap(wks,"MPL_rainbow")

		do n=0,nCases-1
				
			;------------- get case-specific environmental variables
			MODNAME		= "MODNAME"	+ tostring(n)
			MODDIR		= "MODDIR" + tostring(n)
			MODDATES	= "MODDATES"+ tostring(n)
			caseName	= getenv(MODNAME)
			diri		= getenv(MODDIR) + "/proc/"
			dateRange	= getenv(MODDATES)		
			;print("caseName = " + caseName)
			
			;----------- read in seasonal mean u850 wind
			fili	= diri + caseName + ".make_L1.4_mean_stdev_map."+ dateRange +".U850." + seasonName(s) + ".nc"
			f		= addfile(fili,"r")
			ubar	= f->U850_mean
			ubar@long_name	= " "
			ubar@units		= " "
				
			;------------ read in the data
			if (varName.eq."comptotLH".or.varName.eq."wdLH".or.varName.eq."tdLH".or.varName.eq."ecLH".or. \
			    varName.eq."comptotSH".or.varName.eq."wdSH".or.varName.eq."tdSH".or.varName.eq."ecSH") then
			    	progGen	= ".make_L1.5_stdev_map."
			else
					progGen	= ".make_L1.4_mean_stdev_map."
			end if

			fili_prefix		= diri + caseName + progGen+ dateRange +"."
			fili_suffix		= "." + seasonName(s) + ".nc"
			fili			= fili_prefix + varName + fili_suffix
			f				= addfile(fili,"r")
			tName			= varName + "_stdev"
			data_stdev		= f->$tName$
			if (varName.eq."delQ".or.varName.eq."Qair".or.varName.eq."Qsat") then
				data_stdev	= data_stdev * 1000.
			end if

			;------------ define land mask
			if (maskID.eq."mask") then
				lon		= f->lon
				lat		= f->lat			
				a    	= addfile("$NCARG_ROOT/lib/ncarg/data/cdf/landsea.nc","r")
				lsdata	= a->LSMASK
				lsm		= landsea_mask(lsdata,lat,lon)
				data_stdev	= mask(data_stdev,lsm.ge.1,False)
				delete(lat)
				delete(lon)
				delete(lsm)
			end if
		
			;------------ turn on longitude labels for bottom panels
			if (n.eq.nCases-1) then
				res@tmXBLabelsOn			= True
			end if

			;------------ make panel plots
			data_stdev@long_name	= caseName
			data_stdev@units		= DataUnits

			;------------ overlay U850?
			if (u850_overlay.eq."True".or.u850_overlay.eq."true") then
				;----------- create the overlay plot
				plot1	= gsn_csm_contour_map_ce(wks,data_stdev,res)
				uplot1	= gsn_csm_contour(wks,ubar,ures)
				overlay(plot1,uplot1)
				plot(n)	= plot1
				delete(plot1)
				delete(uplot1)
			else
				plot(n)	= gsn_csm_contour_map_ce(wks,data_stdev,res)
			end if

			delete(ubar)
			delete(data_stdev)
			
		end do
		
		;------------- create plot page
		pStr		= (/"a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z" /)
		pID										= pStr(tointeger(PanelStrt)::)
		resP									= True                   	; modify the panel plot
		resP@gsnFrame							= False                  	; don't advance panel plot
		resP@gsnPanelMainString					= "~F33~s ~F21~(" + label(varID) + "), " + seasonName(s); add common title
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
		resP@pmLabelBarWidthF     				= 0.28               ; default is shorter
		resP@pmLabelBarHeightF     				= 0.02              ; default is taller
		gsn_panel(wks,plot,(/nRows,1/),resP)                		; now draw as one plot


		if (wksType.eq."png") then
			frame(wks)
			trimPNG(wksName)
		end if

		res@tmXBLabelsOn	= False ; turn off longitude labels for next season
		
	end do				; season loop

end