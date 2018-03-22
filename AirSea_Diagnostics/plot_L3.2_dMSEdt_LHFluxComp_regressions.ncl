load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"   
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"    
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"    
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/diagnostics_cam.ncl"    
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"
load "./Resources/contrib_AirSea.ncl"
  
begin
                           
	print("============= in plot_L3.2_MSE_LHFluxComp_regressions.ncl =============")   

	;----------- Retrieve required environment variables
	debug		= getenv("DEBUG")
	if (debug.eq."false") then
		err = NhlGetErrorObjectId()
		setvalues err
			"errLevel" : "Fatal"          ; only report Fatal errors
		end setvalues
	end if
	figcap		= getenv("FIGCAP")
	caseName	= getenv("caseName")
	diri		= getenv("FILEDIR")+"/proc/"
	dirp		= getenv("FILEDIR")+"/plots/"
	twStrt		= getenv("YMDSTRT")
	twLast		= getenv("YMDLAST")
	dateStr		= getenv("FILESUFFSTR")

	;------------- seasons
	seasonName	= (/ "Nov-Apr", "May-Oct" /)
	regVar		= (/ "LHFLX", "comptotLH",			"wdLH", 			"tdLH",				"ecLH" /) 
	;regName		= (/ "LHFLX", "component total LH",	"wind-driven LH",	"thermodynamic LH", "eddy-covariance LH" /)
	regName		= (/ "~F14~LH",\
					 "~F14~LH*",\
					 "~F8~D~F14~q~F18~ D ~F21~|~F14~V~F21~|~F14~'~H-115~~V31~~F21~__",\
					 "~F8~D~F14~q'~F18~ D ~F21~|~F14~V~F21~|~H-30~~V32~~F21~__",\
					 "~F8~D~F14~q'~F18~ D ~F21~|~F14~V~F21~|~F14~'" /)

	do s = 0,1 						; do for each season
		;------------set up the plot
		wksType = "pdf"
		wksName	= dirp + caseName + ".plot_L3.2_dMSEdt_LHFluxComp_regressions." + twStrt + "-" + twLast + "." + seasonName(s)
		print("--------- making "+wksName)
		wks = gsn_open_wks(wksType,wksName)		; open a ps file
		gsn_define_colormap(wks,"cmp_b2r")
		plot = new(15,graphic)                 	; create a plot array

		res							= True
		res@gsnDraw					= False			; don't draw
		res@gsnFrame				= False			; don't advance frame
		res@cnInfoLabelOn			= False 		; turn off cn info label
		res@cnLinesOn				= False			; turn off contour lines
		res@cnFillOn				= True			; turn on color
		res@gsnSpreadColors			= True			; spread out color table
		res@gsnSpreadColorStart		=  2 
		res@gsnSpreadColorEnd		= -3 
		res@lbOrientation			= "Vertical"	; vertical label bar
		res@tmXBLabelFontHeightF	= 0.017		; change maj lat tm spacing
		res@tmYLLabelFontHeightF	= 0.017		; change maj lat tm spacing

		res@mpMinLatF				= -30.
		res@mpMaxLatF				=  30.
		res@mpMinLonF 				=  30.
		res@mpMaxLonF				= 240.
		res@mpCenterLonF			= 135. 
		res@cnLevelSelectionMode 	=  "ExplicitLevels"   
	
		Name1						= "Vdmdt"
		do regV = 0,4					; do for each regressed variable

			Name2			= regVar(regV)
			;------------ read in the data for full SST and smoothed SST regressions
			fili			= caseName + ".make_L3.1_regression_map."+ twStrt + "-" + twLast + "." + Name1 + "." + Name2 + "." + seasonName(s) + ".nc"
			f				= addfile(diri + fili, "r")
			reg_full		= f->regData
		
			if (regV.ge.1) then
				fili			= caseName + ".make_L3.1_regression_map."+ twStrt + "-" + twLast + "." + Name1 + "." + Name2 + "." + seasonName(s) + "_smSST.nc"
			end if
			f				= addfile(diri + fili, "r")
			reg_sm			= f->regData

			;------------ make nice units, compute difference
			reg_full		= reg_full * 100.
			reg_full@units	= "% dMSE/dt"
			reg_sm			= reg_sm * 100.
			reg_sm@units	= "% dMSE/dt"
			reg_diff		= reg_full - reg_sm
			copy_VarMeta(reg_full,reg_diff)
		
			;------------ make plot panels
			res@cnLevels 	= fspan(-20.,20.,11)
			plot(regV*3)	= gsn_csm_contour_map_ce(wks,reg_full,res)
			plot(regV*3+1)	= gsn_csm_contour_map_ce(wks,reg_sm,res)

			res@cnLevels 	= fspan(-10,10,11)
			plot(regV*3+2)	= gsn_csm_contour_map_ce(wks,reg_diff,res)
			
		end do			; regressed variable
	
		;------------- create plot page
		resP                  = True                   ; modify the panel plot
		resP@gsnFrame         = False                  ; don't advance panel plot
		resP@gsnPanelLabelBar = False                  ; add common colorbar
		resP@txString         = caseName+" "+seasonName(s)	       ; add common title
		resP@gsnPanelBottom   = 0.05                   ; add space at bottom
		gsn_panel(wks,plot,(/5,3/),resP)               ; now draw as one plot

		;------------- label columns
		txres               = True                     ; text mods desired
		txres@txFontHeightF = 0.012                    ; font smaller. default big
		gsn_text_ndc(wks,"full SST",0.18,0.943,txres) 
		gsn_text_ndc(wks,"smoothed SST",0.49,0.75,txres) 
		gsn_text_ndc(wks,"difference",0.82,0.75,txres) 
		
	end	do		; for each season

end
	





