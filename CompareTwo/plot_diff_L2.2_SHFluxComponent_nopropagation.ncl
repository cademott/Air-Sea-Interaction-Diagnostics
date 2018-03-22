load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"   
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"    
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"    
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/diagnostics_cam.ncl"    
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"
load "./Resources/contrib_AirSea.ncl"

begin
	print("=============== in plot_diff_L2.2_SHFluxComponent_nopropagation.ncl =================")
	progGen		= ".make_L2.2_regression_nopropagation."

	;------------- set dynamic variable names
	debug			= getenv("DEBUG")
	if (debug.eq."false") then
		err = NhlGetErrorObjectId()
		setvalues err
			"errLevel" : "Fatal"          ; only report Fatal errors
		end setvalues
	end if
	figcap			= getenv("FIGCAP")
	CTRLNAME		= getenv("CTRLCASE")
	CTRLDIR			= getenv("CTRLDIR")
	EXPNAME			= getenv("EXPCASE")
	EXPDIR			= getenv("EXPDIR")
	dirp			= getenv("PLOTDIR")
	pType			= getenv("PTYPE")
	diri			= EXPDIR + "proc/" + EXPNAME + "_minus_" + CTRLNAME + "/" 
	print("dirp = " + dirp)
	
	;------------- define season names
	seasonName 	= (/ "Nov-Apr", "May-Oct" /)

	;----------- note:  input variables and metadata for plotting
	;					routines use standard naming conventions
	varName		= (/ "SHFLX",	"comptotSH", 			"wdSH", 			"tdSH",				"ecSH" /)
	
	;----------- read in variable labels and units
	metafile	= "./Resources/variable_labels_units.txt"
	vName_label	= systemfunc("cut -d , -f1 "+metafile)
	label		= str_left_strip(systemfunc("cut -d , -f2 "+metafile))
	units		= str_left_strip(systemfunc("cut -d , -f3 "+metafile))

	;----------- read in the contour intervals for stdev fields
	metafile			= "./CompareMultiple/contours_Season_DiffNoPropagation.txt"
	vName_ciReg		= systemfunc("cut -d , -f1 "+metafile)
	cnMin_ciReg		= tofloat(systemfunc("cut -d , -f2 "+metafile)) 
	cnMax_ciReg		= tofloat(systemfunc("cut -d , -f3 "+metafile)) 
	cnInt_ciReg		= tofloat(systemfunc("cut -d , -f4 "+metafile)) 
	
	;------------- plot resources for shaded base plot
	res 						= True
	res@vpWidthF				= 0.8
	res@vpHeightF				= 0.4
	res@gsnDraw             	= False			; don't draw
	res@gsnFrame            	= False			; don't advance frame
	res@cnInfoLabelOn       	= False 		; turn off cn info label
	res@tmXBLabelsOn			= False			; turn off longitude labels
	res@cnFillOn            	= True			; turn on color
	res@cnLinesOn				= False			; turn off contour lines
	res@gsnSpreadColors     	= True			; spread out color table
	res@gsnSpreadColorStart 	= 2 
	res@gsnSpreadColorEnd   	= -3 
	res@lbOrientation        	= "Vertical"	; vertical label bar
	res@cnLevelSelectionMode 	= "ManualLevels"   
	res@tmXBLabelFontHeightF 	= 0.025		
	res@tmYLLabelFontHeightF 	= 0.025		
	res@tmEqualizeXYSizes		= True
	res@txFontHeightF			= 0.03
	res@tiYAxisString			= "lag (day)"

	;------------- plot resources for overlaid precipitation
	resR								= True		; Precipitation resources
	resR@vpWidthF						= 0.8
	resR@vpHeightF						= 0.4
	resR@gsnDraw						= False		; don't draw
	resR@gsnFrame						= False		; don't advance frame
	resR@cnInfoLabelOn					= False		; turn off cn info label
	resR@gsnLeftString					= ""		; no titles
	resR@gsnRightString					= ""
	resR@tiXAxisString					= ""
	resR@cnLineThicknessF				= 1.5		; thicker contours
	resR@cnLineLabelsOn					= False		; no line labels
	resR@gsnContourZeroLineThicknessF	= 0.		; doubles thickness of zero contour
	resR@gsnContourNegLineDashPattern	= 1 		; sets negative contours to dash pattern 1
	resR@cnLevelSelectionMode 			= "ExplicitLevels"   
	resR@tmXBLabelFontHeightF 			= 0.025		
	resR@tmYLLabelFontHeightF 			= 0.025		
	resR@tmEqualizeXYSizes				= True
	resR@cnLevels						= fspan(-1,1,11)

	;-------------- polyLine
	resL								= True
	resL@gsLineThicknessF				= 2.0
	xvals								= (/ 30.,240. /)
	yvals								= (/ 0.,   0. /)
	lines							 	= new(10,graphic)

	do s = 0,1 						; do for each season
	
	;------------set up the plot
		wksType = pType
		wksName= dirp + EXPNAME + "_minus_"+ CTRLNAME + ".plot_diff_L2.2_SHFluxComponent_nopropogation." + seasonName(s)
		wks = gsn_open_wks(wksType,wksName)		; open a ps file
		gsn_define_colormap(wks,"cmp_b2r")
		plot = new(10,graphic)                 	; create a plot array

		do v = 0,4			; do for each variable
		
			;------------ read in the MSE data
			tName			= "Vmse"
			fili			= diri +  EXPNAME + "_minus_"+ CTRLNAME + progGen +"PRECT." + tName + "." +  seasonName(s) + ".nc"
			f				= addfile(fili,"r")
			mse				= f->$tName$
			mse				= 1E-06 * mse
			mse@units		= "[10~S~6 [J/m**2]/[mm/day]"


			;------------ read metadata, set longitude range for plot
			if (s.eq.0.and.v.eq.0) then
				lag		= f->lag
				lon		= f->lon
				;bpbar	= avg(f->gridp_stdev({40:180}))
				lonind	= ind(lon.ge.30.and.lon.le.240)
			end if

			;------------ read in the base plot data (full and smoothed SST)
			tName			= varName(v)
			fili			= diri +  EXPNAME + "_minus_"+ CTRLNAME + progGen + "PRECT." + tName + "." + seasonName(s) + ".nc"
			f				= addfile(fili,"r")
			data_full		= f->$tName$
			data_full@long_name	= label(ind(vName_label.eq.varName(v)))
			data_full@units	= "[" + units(ind(vName_label.eq.varName(v))) + "  ]/[mm day~S2~-1  ]"

			if (v.eq.0) then
				tName		= varName(v)
			else
				tName		= varName(v)+"_smSST"
			end if
			fili			= diri +  EXPNAME + "_minus_"+ CTRLNAME + progGen + "PRECT." + tName + "." + seasonName(s) + ".nc"
			f				= addfile(fili,"r")
			data_sm		= f->$tName$
			data_sm@long_name	= label(ind(vName_label.eq.varName(v)))
			data_sm@units	= "[" + units(ind(vName_label.eq.varName(v))) + "  ]/[mm day~S2~-1  ]"

			;------------ add longitude labels for bottom-most panels
			if (v.eq.4) then
				res@tmXBLabelsOn			= True	; turn on longitude labels

			end if

			;------------ make plots
			res@cnMinLevelValF		= cnMin_ciReg(ind(vName_ciReg.eq.varName(v)))
			res@cnMaxLevelValF		= cnMax_ciReg(ind(vName_ciReg.eq.varName(v)))
			res@cnLevelSpacingF		= cnInt_ciReg(ind(vName_ciReg.eq.varName(v))) 
			plotR	= gsn_csm_contour(wks, smth9_Wrap(mse(:,lonind),0.5,0.25,False), resR )
			plota	= gsn_csm_contour(wks, smth9_Wrap(data_full(:,lonind),0.5,0.25,False), res )
			lines(v*2)	= gsn_add_polyline(wks, plota, xvals, yvals, resL)
			overlay(plota,plotR)
			plot(v*2)=plota
			delete(plota)
			delete(plotR)
	
			plotR	= gsn_csm_contour(wks, smth9_Wrap(mse(:,lonind),0.5,0.25,False), resR )
			plota	= gsn_csm_contour(wks, smth9_Wrap(data_sm(:,lonind),0.5,0.25,False), res )
			lines(v*2+1)	= gsn_add_polyline(wks, plota, xvals, yvals, resL)
			overlay(plota,plotR)
			plot(v*2+1)=plota
			delete(plota)
			delete(plotR)

			nVars	= v+1 ; this keeps track of how total panels are being plotted

		end do			; variable loop

		;------------- create plot page
		pStr		= (/"a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z" /)
		nPanels		= nVars*2
		pID			= new(nPanels,"string")
		do i=0,nPanels/2-1
			pID(i*2)	= pStr(i)
			pID(i*2+1)	= pStr(i+nPanels/2)
		end do
		resP					= True                   	; modify the panel plot
		resP@gsnFrame			= False                  	; don't advance panel plot
		resP@gsnPanelLabelBar	= False                  	; add common colorbar
		resP@txString			= EXPNAME + " - "+ CTRLNAME + "," + " "+ seasonName(s)
		resP@gsnPanelBottom		= 0.05                   	; add space at bottom
		resP@gsnPanelYWhiteSpacePercent = 4
		resP@gsnPanelFigureStrings = pID      ; add letter labels to panels (# letters can be > # panels)
		resP@gsnPanelFigureStringsFontHeightF	= 0.012
		resP@gsnPanelFigureStringsPerimOn		= True
		resP@amJust								= "TopLeft"
		gsn_panel(wks,plot,(/5,2/),resP)               ; now draw as one plot

		;------------- print sign convention
		txres               	= True                     	; text mods desired
		txres@txFontHeightF		= 0.013                    	; font smaller. default big
		gsn_text_ndc(wks,"[positive (negative) anomalies moisten (dry) the atmosphere]",0.5,0.025,txres) 
		;gsn_text_ndc(wks,"40E-180E avg ~F33~s~F21~(rain) = "+sprintf("%5.2f",bpbar)+".  Overlay:  MSE; contour interval = 1x10~S~6~N~ [J m~S2~-2  ]/[mm day~S2~-1  ]",0.5,0.007,txres) 
		gsn_text_ndc(wks,"full SST",0.28,0.943,txres) 
		gsn_text_ndc(wks,"smoothed SST",0.69,0.943,txres) 

		res@tmXBLabelsOn			= False	; turn off longitude labels for next season plots

		if (wksType.eq."png") then
			frame(wks)
			trimPNG(wksName)
		end if
		
		print("output file = " + wksName)

	end do	; season loop

end
