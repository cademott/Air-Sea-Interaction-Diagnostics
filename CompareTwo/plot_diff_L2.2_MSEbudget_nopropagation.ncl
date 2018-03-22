load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"   
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"    
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"    
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/diagnostics_cam.ncl"    
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"
load "contrib_JJB.ncl"

begin
	print("=============== in plot_diff_L2.2_MSEbudget_nopropagation.ncl =================")
	
	progGen		= ".make_L2.2_regression_nopropagation."

	;------------- set dynamic variable names
	CTRLNAME	= getenv("CTRLCASE")
	CTRLDIR		= getenv("CTRLDIR")
	EXPNAME		= getenv("EXPCASE")
	diri		= CTRLDIR + "proc/" + CTRLNAME + "_minus_" + EXPNAME + "/" 
	print("diri = " + diri)
	dirp		=  CTRLDIR + "plots/"
	print("dirp = " + dirp)
	
	;------------- define season names
	seasonName 	= (/ "Nov-Apr", "May-Oct" /)

	;----------- note:  input variables and metadata for plotting
	;					routines use standard naming conventions
	;HADV_label	= "V~F34xv~q"
	;VADV_label	= "~F8wF34sF18s~MSE/~F18s~p"
	;udmdy_label	= "u
	varName		= (/ "Vmse",	  "Vdmdt", 	    "Vomegadmdp",	"Vlw",	"Vm_hadv", 	"LHFLX",	"Vudmdx",		"SHFLX",	"Vvdmdy",	"Vsw" /)
	;varID		= (/ "Vmse",				"dMSE/dt",			"VADV",			"LW",	"HADV",     "LHFLX",	"-udMSE/dx", 	"SHFLX",	"-vdMSE/dy", "SW" /)
	varID		= (/ "~F18~O~F14~m~F18~P", \									; m
					 "~F34~6~F18~O~F14~m~F18~P~F21~/~F34~6~F14~t",\							; dmdt
				 	 "-~F18~O~F8~w~F18~ D ~F34~6~F14~m~F21~/~F34~6~F14~p~F18~P",\	; omegadmdp
				 	 "~F18~O~F14~LW~F18~P",\									; LW
				 	 "-~F18~O~F21~|~F14~V~F21~|~F18~ D ~F34~Q~F14~m~F18~P",\				; HADV
				 	 "~F14~LH",	\													;
				 	 "-~F18~O~F14~u~F18~ D ~F34~6~F14~m~F21~/~F34~6~F14~x~F18~P", \; uHADV
				 	 "~F14~SH", \													; SH
				 	 "-~F18~O~F14~v~F18~ D ~F34~6~F14~m~F21~/~F34~6~F14~y~F18~P", \; vHADV
				 	 "~F18~O~F14~SW~F18~P" /)									; SW


	;------------- plot resources for shaded base plot
	res 								= True
	res@vpWidthF						= 0.8
	res@vpHeightF						= 0.4
	res@gsnDraw             			= False			; don't draw
	res@gsnFrame            			= False			; don't advance frame
	res@cnInfoLabelOn       			= False 		; turn off cn info label
	res@cnFillOn            			= True			; turn on color
	res@cnLinesOn						= False			; turn off contour lines
	res@tmXBLabelsOn					= False			; turn off longitude labels
	res@gsnSpreadColors     			= True			; spread out color table
	res@gsnSpreadColorStart 			= 2 
	res@gsnSpreadColorEnd   			= -3 
	res@lbOrientation        			= "Vertical"	; vertical label bar
	res@cnLevelSelectionMode 			= "ExplicitLevels"   
	res@cnLevels 						= fspan(-5,5,11)
	res@tmXBLabelFontHeightF 			= 0.025		
	res@tmYLLabelFontHeightF 			= 0.025		
	res@tmEqualizeXYSizes				= True
	res@txFontHeightF					= 0.03
	res@tiYAxisString					= "lag (day)"
	res@gsnPanelBottom					= 0.1			; leave room for contour interval text

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
	resR@cnLevelSelectionMode 			=  "ExplicitLevels"   
	resR@tmXBLabelFontHeightF 			= 0.025		
	resR@tmYLLabelFontHeightF 			= 0.025		
	resR@tmEqualizeXYSizes				= True
	resR@cnLevels						= fspan(-1,1,11)

	;------------- plot resources for overlaid significance
	resS								= True
	resS@vpWidthF						= 0.8
	resS@vpHeightF						= 0.4
	resS@gsnDraw						= False		; don't draw
	resS@gsnFrame						= False		; don't advance frame
	resS@cnInfoLabelOn					= False		; turn off cn info label
	resS@cnLinesOn						= False		; turn off contour lines
	resS@gsnLeftString					= ""		; no titles
	resS@gsnRightString					= ""
	resS@tiXAxisString					= ""
	resS@cnLineThicknessF				= 1.5		; thicker contours
	resS@cnLineLabelsOn					= False		; no line labels
	resS@cnLevelSelectionMode 			= "ExplicitLevels"	; manually specify contour levels
	resS@cnLevels						= (/ 0,0.85,1.1 /)
	resS@cnInfoLabelOn					= False					; turn off info label box
	resS@cnLineLabelsOn					= False					; no lables on line
	resS@cnFillOn						= True					; fill contour intervals
	resS@cnMonoFillColor				= True					; default color is fground [black]
	resS@cnMonoFillPattern				= False					; want multiple patterns 
	resS@cnMonoFillScale				= False					; want patterns w/ diff densities 
	resS@cnMonoFillPattern				= False        			; Use multiple fill patterns
	resS@cnFillPatterns					= (/ -1, 17, -1, -1 /)			; 3=slant lines
	resS@cnFillScales      				= (/0.55,0.55/)			; line density
	resS@cnFillColor					= "grey61"
	resS@lbLabelBarOn					= False					; Turn off labelbar

	do s = 0,1 						; do for each season
	
	;------------set up the plot
		wksType = "pdf"
		wksName= dirp + CTRLNAME + "_minus_"+ EXPNAME + ".plot_diff_L2.2_MSEbudget_nopropogation." + seasonName(s)
		wks = gsn_open_wks(wksType,wksName)		; open a ps file
		gsn_define_colormap(wks,"cmp_b2r")
		plot = new(10,graphic)                 	; create a plot array

		do v = 0,9			; do for each variable
		
			;------------ read in the rainfall data
			tName			= "Vmse"
			fili			= diri +  CTRLNAME + "_minus_"+ EXPNAME + progGen +"PRECT." + tName + "." +  seasonName(s) + ".nc"
			f				= addfile(fili,"r")
			bpbar			= avg(f->gridp_stdev({40:180}))
			mse				= f->$tName$
			mse				= 1E-06 * mse
			;mse@units		= "[10~S1~6 [J m~S2~-2~N~]/[mm day~S2~-1~N~]"

			;------------ read metadata, set longitude range for plot
			if (s.eq.0.and.v.eq.0) then
				lag		= f->lag
				lon		= f->lon
				bpbar	= avg(f->gridp_stdev({40:180}))
				lonind	= ind(lon.ge.30.and.lon.le.240)
			end if

			;------------ read in the base plot data
			tName			= varName(v)
			fili			= diri +  CTRLNAME + "_minus_"+ EXPNAME + progGen + "PRECT." + tName + "." + seasonName(s) + ".nc"
			f				= addfile(fili,"r")
			data			= f->$tName$
			data@long_name	= varID(v)
			sig				= f->statSig(:,lonind)
			;sig1d			= ndtooned(sig)
			;sig1d(ind(sig1d.lt.0.95))	= default_fillvalue(typeof(sig1d))
			;sig				= onedtond(sig,dimsizes(sig))
			if (v.eq.0) then
				data		= data * 1E-06
				data@units	= "[10~S~6~N~  J m~S2~-2  ]/[mm day~S2~-1  ]"
			else
				data@units	= "[W m~S2~-2  ]/[mm day~S2~-1  ]"
			end if

			;------------ turn on longitude labels for bottom panels
			if (v.eq.8) then
				res@tmXBLabelsOn			= True
			;else
			;	res@tmXBLabelsOn			= False
			end if

			;------------ make plots
			plotR	= gsn_csm_contour(wks, smth9_Wrap(mse(:,lonind),0.5,0.25,False), resR ) ; rainfall
			plota	= gsn_csm_contour(wks, smth9_Wrap(data(:,lonind),0.5,0.25,False), res ) ; regression
			plotS	= gsn_csm_contour(wks, sig, resS ); significance
			overlay(plota,plotR)
			;overlay(plota,plotS)
			plot(v)=plota
			delete(plota)
			delete(plotR)
	
			nVars	= v+1 ; this keeps track of how total panels are being plotted

		end do			; variable loop

		;------------- create plot page
		pStr		= (/"a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z" /)
		nPanels		= nVars
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
		resP@txString			= CTRLNAME + " - " + EXPNAME + "," + " "+ seasonName(s)
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
		gsn_text_ndc(wks,"[lowest four rows:  positive anomalies support positive MSE]",0.5,0.025,txres) 
		gsn_text_ndc(wks,"40E-180E avg ~F33~s~F21~(rain) = "+sprintf("%5.2f",bpbar)+".  Overlay:  MSE; contour interval = 1x10~S~6~N~ [J m~S2~-2  ]/[mm day~S2~-1  ]",0.5,0.007,txres) 

		res@tmXBLabelsOn		= False	; turn off longitude labels for next season plots

	end do	; season loop

end
