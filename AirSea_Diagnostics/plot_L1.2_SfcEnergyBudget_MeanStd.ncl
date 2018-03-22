load "./Resources/contrib_AirSea.ncl"

begin

	print("=============== in plot_L1.2_SfcEnergyBudget_MeanStd.ncl =================")

	;---------- read in environmental variables
	debug		= getenv("DEBUG")
	if (debug.eq."false") then
		err = NhlGetErrorObjectId()
		setvalues err
			"errLevel" : "Fatal"          ; only report Fatal errors
		end setvalues
	end if
	figcap		= getenv("FIGCAP")
	pType		= getenv("PTYPE")
	twStrt		= getenv("YMDSTRT")
	twLast		= getenv("YMDLAST")
	dateStr		= getenv("FILESUFFSTR")
	diri		= getenv("FILEDIR") + "/proc/"
	dirp		= getenv("FILEDIR") + "/plots/"
	caseName	= getenv("caseName")
	;ctable		= getenv("ctable")

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

	;------------- define season names
	seasonName 	= (/ "Nov-Apr", "May-Oct" /)

	;----------- note:  input variables and metadata for plotting
	;					routines use standard naming conventions
	varName		= (/ "Qnet","SWsfc","LHFLX","SHFLX","LWsfc" /)

	;----------- read in variable labels and units
	metafile	= "./Resources/variable_labels_units.txt"
	vName		= systemfunc("cut -d , -f1 "+metafile)
	label		= str_left_strip(systemfunc("cut -d , -f2 "+metafile))
	units		= str_left_strip(systemfunc("cut -d , -f3 "+metafile))

	;----------- assign contour intervals
	cnMinMean	= (/-45.,							150.,						-180.,						-18.,							-60.  /)
	cnMaxMean	= (/105.,						 	300.,						 -80.,						 -8.,							-30.  /)
	cnSpcMean	= (/ 15.,				 		 	 15.,						  10.,						  1.,							  3.  /)
	
	cnMinStdev	= (/  0.,							  0.,						  0.,						 0.,							 0.  /)
	cnMaxStdev	= (/ 60.,							 60.,						 60.,						 6.,							 6.  /)
	cnSpcStdev	= (/  5.,							  5.,						  5.,						 0.5,							 0.5 /)
	
	;------------- plot resources for base plot
	res                     	= True
	res@gsnDraw 				= False			; don't draw
	res@gsnFrame				= False			; don't advance frame
	res@cnInfoLabelOn			= False 		; turn off cn info label
	res@cnFillOn				= True			; turn on color
	res@cnLinesOn				= True			; turn off contour lines
	res@gsnSpreadColors			= True			; spread out color table
	res@tmXBLabelsOn			= False
	res@gsnSpreadColorStart		= 2
	res@gsnSpreadColorEnd		= -3 
	res@lbOrientation			= "Vertical"	; vertical label bar
	res@tmXBLabelFontHeightF	= 0.017         ; change maj lat tm spacing
	res@tmYLLabelFontHeightF	= 0.017         ; change maj lat tm spacing
	res@mpMinLatF				= -30.
	res@mpMaxLatF				=  30.
	res@mpMinLonF 				=  30.
	res@mpMaxLonF				= 240.
	res@mpCenterLonF			= 135. 
	res@cnLevelSelectionMode	= "ManualLevels"   

	do s = 0,1 					; do for each season
		;----------- set up plot file
		wksType = pType
		wksName	= dirp + caseName + ".plot_L1.2_SfcEnergyBudget_MeanStd_map."+ twStrt + "-" + twLast +"."+seasonName(s)
		wks = gsn_open_wks(wksType,wksName)		; open a ps file
		gsn_define_colormap(wks,"MPL_rainbow")
		plot = new(10,graphic)                 	

		do v = 0,4			; do for each variable
		
			;------------ read in the data
			fili_prefix		= diri + caseName + ".make_L1.4_mean_stdev_map."+ twStrt + "-" + twLast +"."
			fili_suffix		= "." + seasonName(s) + ".nc"
			fili			= fili_prefix + varName(v) + fili_suffix
			f				= addfile(fili,"r")
			tName			= varName(v) + "_mean"
			data_mean		= f->$tName$
			tName			= varName(v) + "_stdev"
			data_stdev		= f->$tName$

			;------------ define land mask
			if (s.eq.0.and.v.eq.0) then
				lon		= f->lon
				lat		= f->lat			
				a    	= addfile("$NCARG_ROOT/lib/ncarg/data/cdf/landsea.nc","r")
				lsdata	= a->LSMASK
				lsm		= landsea_mask(lsdata,lat,lon)
			end if

			;------------ mask land
			data_mean	= mask(data_mean,lsm.ge.1,False)
			data_stdev	= mask(data_stdev,lsm.ge.1,False)
			
			;------------ reverse color table for fluxes
			if (v.ge.2) then
				;res@gsnSpreadColorStart = -3 
				;res@gsnSpreadColorEnd   =  2
				data_mean				= -1.*data_mean ; plot so positive flux warms ocean
			else
				;res@gsnSpreadColorStart =  2 
				;res@gsnSpreadColorEnd   = -3
			end if			 

			;------------ turn on longitude labels for bottom panels
			if (v.eq.4) then
				res@tmXBLabelsOn			= True
			end if

			;------------ assign label and units
			varID					= ind(vName.eq.varName(v))
			labelID					= label(varID)
			unitsID					= units(varID)

			;------------ make panel plots
			res@cnMinLevelValF		= cnMinMean(v)
			res@cnMaxLevelValF		= cnMaxMean(v)
			res@cnLevelSpacingF		= cnSpcMean(v) 
			data_mean@long_name		= "mean " + labelID
			data_mean@units			= unitsID
			plot1					= gsn_csm_contour_map_ce(wks,data_mean,res)

			;------------ reset color table anomaly fields
			res@cnMinLevelValF		= cnMinStdev(v)
			res@cnMaxLevelValF		= cnMaxStdev(v)
			res@cnLevelSpacingF		= cnSpcStdev(v) 
			data_stdev@long_name	= "~F33~s~F21~(" + labelID + "~F21~)"
			data_stdev@units		= unitsID
			plot2					= gsn_csm_contour_map_ce(wks,data_stdev,res)
		
			plot(v*2)	= plot1
			plot(v*2+1)	= plot2
			
			delete(plot1)
			delete(plot2)

			nVars	= v+1 ; this keeps track of how total panels are being plotted

		end do			; variable loop

		;------------- create plot page
		pStr		= (/"a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z" /)
		nPanels		= nVars*2
		pID			= new(nPanels,"string")
		print("nPanels = "+nPanels)
		do i=0,nPanels/2-1
			pID(i*2)	= pStr(i)
			pID(i*2+1)	= pStr(i+nPanels/2)
		end do
		;print(pID)
		resP					= True                   	; modify the panel plot
		resP@gsnFrame			= False                  	; don't advance panel plot
		resP@gsnPanelLabelBar	= False                  	; add common colorbar
		resP@txString			= caseName+" " + seasonName(s); add common title
		resP@gsnPanelBottom		= 0.05                   	; add space at bottom
		resP@gsnPanelYWhiteSpacePercent = 6
		resP@gsnPanelFigureStrings = pID      ; add letter labels to panels (# letters can be > # panels)
		resP@gsnPanelFigureStringsFontHeightF	= 0.012
		resP@gsnPanelFigureStringsPerimOn		= True
		resP@amJust								= "TopLeft"
		gsn_panel(wks,plot,(/5,2/),resP)                	; now draw as one plot

		;------------- label columns
		txres               	= True                     	; text mods desired
		txres@txFontHeightF		= 0.013                    	; font smaller. default big
		gsn_text_ndc(wks,"mean",0.23,0.855,txres) 
		gsn_text_ndc(wks,"~F33~s ~F21~(20-100 day filtered)",0.73,0.855,txres) 
		
		if (figcap.eq."true") then
			gsn_text_ndc(wks,"[positive (negative) flux warms (cools) the ocean]",0.5,0.09,txres) 
		end if
		
		if (wksType.eq."png") then
			frame(wks)
			trimPNG(wksName)
		end if

		res@tmXBLabelsOn	= False ; turn off longitude labels for next season
		
	
	end do 			; season loop

end
	





