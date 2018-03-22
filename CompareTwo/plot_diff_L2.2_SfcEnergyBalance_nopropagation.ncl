load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"   
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"    
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"    
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/diagnostics_cam.ncl"    
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"
load "/Users/demott/Dropbox/ncl/AirSeaDiagnostics/Diagnostics_V4/contrib_JJB.ncl"

begin
	print("=============== in plot_diff_L2.2_SfcEnergyBalance_nopropagation.ncl =================")
	
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
	varName		= (/ "SST",		"Qnet", 	"SWsfc", 			"LHFLX",	"LWsfc",			"SHFLX" /)
	varID		= (/ "SST",		"Qnet",		"net surface SW",	"LHFLX",	"net surface LW", 	"SHFLX" /)

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
	res@cnLevelSelectionMode 	=  "ExplicitLevels"   
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
	resR@cnLevelSelectionMode 			=  "ExplicitLevels"   
	resR@tmXBLabelFontHeightF 			= 0.025		
	resR@tmYLLabelFontHeightF 			= 0.025		
	resR@tmEqualizeXYSizes				= True
	resR@cnLevels						= fspan(-1,1,11)

	do s = 0,1 						; do for each season
	
	;------------set up the plot
		wksType = "pdf"
		wksName= dirp + CTRLNAME + "_minus_"+ EXPNAME + ".plot_diff_L2.2_SfcEnergyBalance_nopropogation." + seasonName(s)
		wks = gsn_open_wks(wksType,wksName)		; open a ps file
		gsn_define_colormap(wks,"cmp_b2r")
		plot = new(10,graphic)                 	; create a plot array

		do v = 0,5			; do for each variable
		
			;------------ read in the rainfall data
			tName			= "Vmse"
			fili			= diri +  CTRLNAME + "_minus_"+ EXPNAME + progGen +"PRECT." + tName + "." +  seasonName(s) + ".nc"
			f				= addfile(fili,"r")
			bpbar			= avg(f->gridp_stdev({40:180}))
			mse				= f->$tName$
			mse				= 1E-06 * mse
			mse@units		= "[10~S~6 [J/m**2]/[mm/day]"

			;------------ read metadata, set longitude range for plot
			if (s.eq.0.and.v.eq.0) then
				lag		= f->lag
				lon		= f->lon
				lonind	= ind(lon.ge.30.and.lon.le.240)
			end if

			;------------ read in the base plot data
			tName			= varName(v)
			fili			= diri +  CTRLNAME + "_minus_"+ EXPNAME + progGen + "PRECT." + tName + "." + seasonName(s) + ".nc"
			f				= addfile(fili,"r")
			data			= f->$tName$
			data@long_name	= varID(v)
			
			;------------ define contour interval for base plot; reformat units
			if (v.eq.0) then	; SST
				res@cnLevels = fspan(-.125,.125,11)
				data@units	 = "[K]/[mm day~S2~-1  ]"
			end if
			if (v.ge.1) then	; all fluxes
				res@cnLevels = fspan(-2.5,2.5,11)
				data@units	= "[W m~S2~-2  ]/[mm day~S2~-1  ]"
			end if
			
			;------------ change sign of LH, SH, LW so that all + fluxes warm ocean
			if (v.ge.3) then
				data	= -1.*data
			end if

			;------------ turn on longitude labels for bottom most panels
			if (v.ge.4) then
				res@tmXBLabelsOn	= True	; turn on longitude labels
			end if

			;------------ make plots
			plotR	= gsn_csm_contour(wks, smth9_Wrap(mse(:,lonind),0.5,0.25,False), resR )
			plota	= gsn_csm_contour(wks, smth9_Wrap(data(:,lonind),0.5,0.25,False), res )
			overlay(plota,plotR)
			plot(v)=plota
			delete(plota)
			delete(plotR)
	
			res@tmXBLabelsOn	= False	; turn off longitude labels for next panel
		
			nVars	= v+1 ; this keeps track of how total panels are being plotted

		end do			; variable loop

		;------------- create plot page
		pStr		= (/"a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z" /)
		nPanels		= nVars
		pID			= new(nPanels,"string")
		do i=0,nPanels/2-1
			pID(i*2)	= pStr(i)
			pID(i*2+1)	= pStr(i+nPanels/2)
		end do
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
		gsn_text_ndc(wks,"[positive (negative) anomalies warm (cool) the ocean]",0.5,0.37,txres) 
		gsn_text_ndc(wks,"40E-180E avg ~F33~s~F21~(rain) = "+sprintf("%5.2f",bpbar)+".  Overlay:  MSE; contour interval = 1x10~S~6~N~ [J m~S2~-2  ]/[mm day~S2~-1  ]",0.5,0.348,txres) 

	end do	; season loop

end
