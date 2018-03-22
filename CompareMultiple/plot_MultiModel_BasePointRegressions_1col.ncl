load "/Users/demott/Dropbox/ncl/contrib_CAD.ncl"

begin

	print("=============== in plot_MultiModel_BasePointRegressions_1col.ncl =================")

	;------------- define season namesx
	seasonName 	= (/ "Nov-Apr", "May-Oct" /)

	;------------- get global environmental variables
	FNPrefix			= getenv("FilePrefix")
	nCases			= toint(getenv("nCases"))
	nRows			= toint(getenv("nRows"))
	pType			= getenv("PTYPE")
	dirp			= getenv("dirp")	
	baseVar			= getenv("baseVar")
	varName			= getenv("varName")	
	PanelStrt		= getenv("panelLabStrt")
	AxisFontHt		= tofloat(getenv("AxisFontHt"))
	TitleFontHt		= tofloat(getenv("TitleFontHt"))
	PanelFontHt		= tofloat(getenv("PanelFontHt"))
	LabelBarFontHt	= tofloat(getenv("LabelBarFontHt"))
;	nCases		= toint(getenv("nCases"))
;	nRows		= toint(getenv("nRows"))
;	baseVar		= getenv("BaseVar")
;	varName		= getenv("varName")	
;	PanelStrt	= getenv("panelLabStrt")
;	dirp		= getenv("dirp")	
;	wksType		= getenv("wksType")	
;	FNPrefix	= getenv("FileNamePrefix")	
	print("PanelStrt="+PanelStrt)	
	print("nCases = " + nCases)
	print("varName = " + varName)

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
	res@tmXBLabelFontHeightF	= 0.019         ; change maj lat tm spacing
	res@tmYLLabelFontHeightF	= 0.019         ; change maj lat tm spacing
	res@mpMinLatF				= -30.
	res@mpMaxLatF				=  30.
	res@mpMinLonF 				=  30.
	res@mpMaxLonF				= 240.
	res@mpCenterLonF			= 135. 
	res@cnLevelSelectionMode	= "ManualLevels"   
	res@lbLabelBarOn			= False
	res@gsnContourZeroLineThicknessF	= 0
	
	;------------- set up plot panels, contours, labels, units
	plot 				= new(nCases,graphic)   	; double the number to utilize left-column only
	metafile			= "./contours_BasePointRegression_Maps.txt"
	vName				= systemfunc("cut -d , -f1 "+metafile)
	cnMin				= tofloat(systemfunc("cut -d , -f2 "+metafile)) 
	cnMax				= tofloat(systemfunc("cut -d , -f3 "+metafile)) 
	cnInt				= tofloat(systemfunc("cut -d , -f4 "+metafile)) 
	landmask			= str_left_strip(systemfunc("cut -d , -f5 "+metafile))
	smooth				= str_left_strip(systemfunc("cut -d , -f6 "+metafile))
	varID				= ind(vName.eq.varName)
	maskID				= landmask(varID)
	smoothID			= smooth(varID)
	res@cnMinLevelValF	= cnMin(varID)
	res@cnMaxLevelValF	= cnMax(varID)
	res@cnLevelSpacingF	= cnInt(varID) 
	delete(vName)
	print("smoothID = " + smoothID)
		              	
	;------------- set up panel labels, units
	metafile			= "../Resources/variable_labels_units.txt"
	vName				= systemfunc("cut -d , -f1 "+metafile)
	label				= str_left_strip(systemfunc("cut -d , -f2 "+metafile))
	units				= str_left_strip(systemfunc("cut -d , -f3 "+metafile))
	varID				= ind(vName.eq.varName)
	PlotLabel			= label(varID)
	DataUnits			= units(varID)
	
	baselon	= (/ 90, 150 /)
	
	do s = 0,0 				; do for each season

		do b=0,dimsizes(baselon)-1

		;----------- set up plot file
		wksType = pType
		wksName	= dirp + FNPrefix + ".MultiModel_BasePointRegressions_1col." + varName + "." + baselon(b) + "E." + seasonName(s)
		wks = gsn_open_wks(wksType,wksName)

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
			fili_prefix		= diri + caseName + ".make_L2.5_regression_basepoint." + dateRange + "." + baseVar + "." + varName
			fili_suffix		= "." + seasonName(s) + ".nc"
			fili			= fili_prefix + fili_suffix
			f				= addfile(fili,"r")
			tName			= varName + "_reg"
			data_mean		= f->$tName$({baselon(b)},:,:)

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

			;------------ define color table
			if (varName.eq."PRECT".or.varName.eq."PW".or.varName.eq."omegadqdp850") then
				res@cnFillPalette			= "precip_diff_12lev"
				res@cnFillColors			= (/ 2,3,4,5,6,8,8,10,11,12,13,14 /) - 2
			else
				res@cnFillPalette			= "BlueWhiteOrangeRed"
				res@cnFillColors			= tointeger(fspan(20,234,12))
			end if

			;------------ make panel plots
			data_mean@long_name		= caseName
			data_mean@units			= units(varID)
			
			if (smoothID.eq."smooth") then
				pdata	= smth9_Wrap(data_mean,0.5,0.25,True)
			else
				pdata	= data_mean
			end if
			plot(n)	= gsn_csm_contour_map_ce(wks,pdata,res)

			delete(data_mean)
			delete(pdata)
			
		end do
		
		;------------- create plot page
		pStr		= (/"a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z" /)
		pID										= pStr(tointeger(PanelStrt)::)
		resP									= True                   	; modify the panel plot
		resP@gsnFrame							= False                  	; don't advance panel plot
		resP@gsnPanelMainString					= PlotLabel + ", " + seasonName(s); add common title
		resP@gsnPanelMainFontHeightF			= TitleFontHt
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
		resP@pmLabelBarWidthF     				= 0.28              ; default is shorter
		resP@pmLabelBarHeightF     				= 0.02              ; default is taller
		gsn_panel(wks,plot,(/nRows,1/),resP)                		; now draw as one plot

		if (wksType.eq."png") then
			frame(wks)
			trimPNG(wksName)
		end if

		res@tmXBLabelsOn	= False ; turn off longitude labels for next season
		
		end do			; base point loop
		
	end do				; season loop

end