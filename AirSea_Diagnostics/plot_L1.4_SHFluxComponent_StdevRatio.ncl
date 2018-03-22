load "./Resources/contrib_AirSea.ncl"
  
;------------------------------------------------------------------------
begin
                           
	print("=============== in plot_L1.4_SHFluxComponent_StdevRatio.ncl =================")

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
	varName		= (/ "SHFLX",	"comptotSH", 		"wdSH", 		"tdSH",				"ecSH" /)

	;----------- read in variable labels and units
	metafile	= "./Resources/variable_labels_units.txt"
	vName		= systemfunc("cut -d , -f1 "+metafile)
	label		= str_left_strip(systemfunc("cut -d , -f2 "+metafile))
	units		= str_left_strip(systemfunc("cut -d , -f3 "+metafile))

	progGen		= (/ 	".make_L1.4_mean_stdev_map.", \
						".make_L1.5_stdev_map.", \	
						".make_L1.5_stdev_map.", \	
						".make_L1.5_stdev_map.", \	
						".make_L1.5_stdev_map." /)

	;------------- plot resources 
	res 						= True
	res@gsnDraw             	= False			; don't draw
	res@gsnFrame            	= False			; don't advance frame
	res@cnInfoLabelOn       	= False 		; turn off cn info label
	res@cnFillOn            	= True			; turn on color
	res@tmXBLabelsOn			= False			; turn off longitude labels
	res@gsnSpreadColors     	= True			; spread out color table
	res@gsnSpreadColorStart 	= 2 
	res@gsnSpreadColorEnd   	= -3 
	res@lbOrientation        	= "Vertical"	; vertical label bar
	res@tmXBLabelFontHeightF 	= 0.0175		; change maj lat tm spacing
	res@tmYLLabelFontHeightF 	= 0.0175		; change maj lat tm spacing
	res@mpMinLatF				= -30.
	res@mpMaxLatF				=  30.
	res@mpMinLonF 				=  30.
	res@mpMaxLonF				= 240.
	res@mpCenterLonF			= 135. 
	res@cnLevelSelectionMode 	=  "ManualLevels"   
	res@cnMinLevelValF			=   0.
	res@cnMaxLevelValF			= 100.
	res@cnLevelSpacingF			=  10. 

	do s = 0,1 						; do for each season
	
	;------------set up the plot
		wksType = pType
		wksName	= dirp + caseName + ".plot_L1.4_SHFluxComponent_StdevRatio."+ twStrt + "-" + twLast +"."+seasonName(s)
		wks = gsn_open_wks(wksType,wksName)		; open a ps file
		gsn_define_colormap(wks,"MPL_rainbow")
		plot = new(10,graphic)                 	; create a plot array

		do v = 0,4			; do for each variable
		
			;------------ read in the data
			tName			= varName(v)
			fili			= diri + caseName + progGen(v) + twStrt + "-" + twLast + "." + tName + "." + seasonName(s) + ".nc"
			f				= addfile(fili,"r")
			tName			= tName + "_stdev"
			data_full		= f->$tName$
			if (v.eq.0) then
				tName		= varName(v)
			else
				tName		= varName(v) + "_smSST"
			end if
			fili			= diri + caseName + progGen(v) + twStrt + "-" + twLast + "." + tName + "." + seasonName(s) + ".nc"
			f				= addfile(fili,"r")
			tName			= tName + "_stdev"
			data_sm			= f->$tName$
			
			;------------ define land mask
			if (s.eq.0.and.v.eq.0) then		; no _smSST for LHFLX, Qair
				lon		= f->lon
				lat		= f->lat			
				a    	= addfile("$NCARG_ROOT/lib/ncarg/data/cdf/landsea.nc","r")
				lsdata	= a->LSMASK
				lsm		= landsea_mask(lsdata,lat,lon)
			end if

			;------------ mask land
			data_full	= mask(data_full,lsm.ge.1,False)
			data_sm		= mask(data_sm,lsm.ge.1,False)
			
			;------------ assign label and units
			varID					= ind(vName.eq.varName(v))
			labelID					= label(varID)
			unitsID					= units(varID)
			labelFULL				= label(ind(vName.eq.varName(0)))

			;------------ save total flux for computing ratios
			if (v.eq.0) then
				totflux_full		= data_full
				totflux_sm			= data_sm
			else
				data_full			= 100. * data_full / totflux_full
				data_full@units		= "%"
				data_full@long_name	= "~F33~s~F21~(" + labelID + "~F21~) / ~F33~s~F21~(" + labelFULL + "~F21~)"
				
				data_sm				= 100. * data_sm / totflux_sm
				data_sm@units		= "%"
				data_sm@long_name	= "~F33~s~F21~(" + labelID + "~F21~) / ~F33~s~F21~(" + labelFULL + "~F21~)"
			end if
					
			;------------ make panel plots
			if (v.eq.4) then
				res@tmXBLabelsOn			= True			; turn on longitude labels
			end if
			if (v.gt.0) then
				plot1					= gsn_csm_contour_map_ce(wks,data_full,res)
				plot2					= gsn_csm_contour_map_ce(wks,data_sm,res)
		
				plot(v*2)	= plot1
				plot(v*2+1)	= plot2
			
				delete(plot1)
				delete(plot2)
				
			end if

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
		resP@gsnPanelYWhiteSpacePercent = 5
		resP@gsnPanelFigureStrings = pID      ; add letter labels to panels (# letters can be > # panels)
		resP@gsnPanelFigureStringsFontHeightF	= 0.012
		resP@gsnPanelFigureStringsPerimOn		= True
		resP@amJust								= "TopLeft"
		gsn_panel(wks,plot,(/5,2/),resP)                	; now draw as one plot

		;------------- label columns
		txres               	= True                     	; text mods desired
		txres@txFontHeightF		= 0.013                    	; font smaller. default big
		gsn_text_ndc(wks,"ratio (full SST)",0.23,0.71,txres) 
		gsn_text_ndc(wks,"ratio (smoothed SST)",0.73,0.71,txres) 

		if (wksType.eq."png") then
			frame(wks)
			trimPNG(wksName)
		end if

		res@tmXBLabelsOn		= False			; turn off longitude labels

	
	end do 			; season loop		

end
	





