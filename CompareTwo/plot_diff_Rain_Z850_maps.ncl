load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"   
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"    
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"    
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/diagnostics_cam.ncl"    
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"

begin

	print("=============== in plot_L1.1_SfcVariables_MeanStd.ncl =================")

	;------------- set dynamic variable names
;	ctrlName	= "SPCCSM"
;	ctrlDir		= "/volumes/Rocstor/Model_output/SPCAM3/sp-ccsm_MJODIABATICHEATING/AirSeaDiagnostics/"
;	expName		= "SPCAM3_mon"
;	expDir		= "/volumes/Rocstor/Model_output/SPCAM3/spcam_monthlySSTs_spec/rerun/daily/AirSea/"

	ctrlName	= "MetUM-GOML"
	ctrlDir		= "/volumes/lava/Model_output/MetUM/GOML/AirSea/"
	expName		= "MetUM-ACM"
	expDir		= "/volumes/lava/Model_output/MetUM/ACM/AirSea/"

;	ctrlName	= "CNRM-CM"
;	ctrlDir		= "/volumes/Rocstor/Model_output/CNRM-CM/AirSea/"
;	expName		= "CNRM-ACM"
;	expDir		= "/volumes/Rocstor/Model_output/CNRM-ACM/AirSea/"

	dirp		= ctrlDir + "plots/"

	;------------- define season names
	seasonName 	= (/ "Nov-Apr", "May-Oct" /)
	
	;------------- define base point locations
	locID		= (/ "60E","90E" /)
	
	;------------- plot resources for base plot
	resS                     	= True
	resS@gsnDraw 				= False			; don't draw
	resS@gsnFrame				= False			; don't advance frame
	resS@cnInfoLabelOn			= False 		; turn off cn info label
	resS@cnFillOn				= True			; turn on color
	resS@cnLinesOn				= True			; turn off contour lines
	resS@cnLineColor			= "grey60"
	resS@gsnSpreadColors		= True			; spread out color table
	resS@gsnSpreadColorStart	= 2 
	resS@gsnSpreadColorEnd		= -3 
	resS@tmXBLabelsOn			= False
	resS@lbOrientation			= "Vertical"	; vertical label bar
	resS@tmXBLabelFontHeightF	= 0.017         ; change maj lat tm spacing
	resS@tmYLLabelFontHeightF	= 0.017         ; change maj lat tm spacing
	resS@mpMinLatF				= -30.
	resS@mpMaxLatF				=  30.
	resS@mpMinLonF 				=  30.
	resS@mpMaxLonF				= 300.
	resS@mpCenterLonF			= 165. 
	resS@mpGridLatSpacingF		=  30.
	resS@cnLevelSelectionMode	= "ManualLevels"   
;	resS@cnMinLevelValF			= -2.5
;	resS@cnMaxLevelValF			=  2.5
;	resS@cnLevelSpacingF		=  0.5
;	resS@cnMinLevelValF			= -5.
;	resS@cnMaxLevelValF			=  5.
;	resS@cnLevelSpacingF		=  1.
	resS@cnMinLevelValF			= -1.
	resS@cnMaxLevelValF			=  1.
	resS@cnLevelSpacingF		=  0.2

	;------------- plot resources for u850 overlay plot
	resC                     	= True
	resC@gsnDraw				= False
	resC@gsnFrame				= False
	resC@cnFillOn				= False			; turn off color
	resC@cnLinesOn				= True			; turn on contour lines
	resC@cnLineColor			= "Black"
	resC@cnLineThicknessF		= 2.
	resC@cnInfoLabelOn			= False
	resC@cnLevelSelectionMode	= "ExplicitLevels"   
	resC@tiXAxisOn				= False
	resC@tiYAxisOn				= False
	resC@tiMainOn				= False
	resC@cnLineLabelsOn			= False
	resC@gsnContourZeroLineThicknessF	= 2.		; doubles thickness of zero contour
	resC@gsnContourNegLineDashPattern	= 1 		; sets negative contours to dash pattern 1

	do s = 0,0 				; do for each season
		
		fili_ctrl	= ctrlDir + ctrlName + ".Rainfall_15S-15N_hw5_regressions." + seasonName(s) + ".nc"
		fctrl		= addfile(fili_ctrl,"r")
		fili_exp	= expDir + expName + ".Rainfall_15S-15N_hw5_regressions." + seasonName(s) + ".nc"
		fexp		= addfile(fili_exp,"r")

		nVars		= 3
		do loc = 1,1			; do for each variable
		
			print(" ")
			print("locID = "+locID(loc))
		
			;----------- read in seasonal Z850 and Rainfall regressions
			tName			= "DIV200_reg_" + locID(loc)
			Z850_reg_ctrl	= fctrl->$tName$
			Z850_reg_ctrl	= Z850_reg_ctrl * 1E06
			tName			= "Rain_reg_" + locID(loc)
			Rain_reg_ctrl	= fctrl->$tName$
			;printMinMax(Z850_reg_ctrl,True)
			;printMinMax(Rain_reg_ctrl,True)
			;tName			= "Rain_sig_" + locID(loc)
			;Rain_sig_ctrl	= fctrl->$tName$
			;Z850_reg_ctrl	= Z850_reg_ctrl - conform_dims(dimsizes(Z850_reg_ctrl),dim_avg_n_Wrap(Z850_reg_ctrl,0),1)
			;Rain_reg_ctrl	= Rain_reg_ctrl - conform_dims(dimsizes(Rain_reg_ctrl),dim_avg_n_Wrap(Rain_reg_ctrl,0),1)
			;Z850_reg_ctrl	= Z850_reg_ctrl - conform_dims(dimsizes(Z850_reg_ctrl),dim_avg_n_Wrap(Z850_reg_ctrl,1),0)
			;Rain_reg_ctrl	= Rain_reg_ctrl - conform_dims(dimsizes(Rain_reg_ctrl),dim_avg_n_Wrap(Rain_reg_ctrl,1),0)
		
			tName			= "DIV200_reg_" + locID(loc)
			Z850_reg_exp	= fexp->$tName$
			Z850_reg_exp	= Z850_reg_exp * 1E06
			tName			= "Rain_reg_" + locID(loc)
			Rain_reg_exp	= fexp->$tName$
			;printMinMax(Z850_reg_exp,True)
			;printMinMax(Rain_reg_exp,True)
			;tName			= "Rain_sig_" + locID(loc)
			;Rain_sig_exp	= fexp->$tName$
			;Z850_reg_exp	= Z850_reg_exp - conform_dims(dimsizes(Z850_reg_exp),dim_avg_n_Wrap(Z850_reg_exp,0),1)
			;Rain_reg_exp	= Rain_reg_exp - conform_dims(dimsizes(Rain_reg_exp),dim_avg_n_Wrap(Rain_reg_exp,0),1)
			;Z850_reg_exp	= Z850_reg_exp - conform_dims(dimsizes(Z850_reg_exp),dim_avg_n_Wrap(Z850_reg_exp,1),0)
			;Rain_reg_exp	= Rain_reg_exp - conform_dims(dimsizes(Rain_reg_exp),dim_avg_n_Wrap(Rain_reg_exp,1),0)
		
			;----------- set up plot file
			wksType = "pdf"
			;wksName	= dirp + expName + "_minus_" + ctrlName + ".Rain_Z850_map." + locID(loc) + "." +seasonName(s)+".zonalAnom"
			wksName	= dirp + expName + "_minus_" + ctrlName + ".Rain_DIV200_map." + locID(loc) + "." +seasonName(s)
			print(wksName)
			wks = gsn_open_wks(wksType,wksName)		; open a ps file
			gsn_define_colormap(wks,"cmp_b2r")
			plot = new(3,graphic)                 	

			;------------ smooth rainfall for nice contours
			resS@tmXBLabelsOn			= False
			if (loc.ge.1) then
				delete(resC@cnLevels)
			end if
			resC@cnLevels			= fspan(0.4,1.2,5)
			Rain_reg_ctrl			= smth9_Wrap(Rain_reg_ctrl, 0.50, 0.25, True)
			Rain_reg_ctrl@long_name	= " "
			Rain_reg_ctrl@units		= " "
			Rain_reg_exp			= smth9_Wrap(Rain_reg_exp, 0.50, 0.25, True)
			Rain_reg_exp@long_name	= " "
			Rain_reg_exp@units		= " "
			
			;------------ make Z850 plot
			Z850_reg_ctrl@long_name		= ctrlName
			Z850_reg_ctrl@units			= "[10~S2~-6   s~S2~-1  ] / [mm/day]"
			Z850_reg_exp@long_name		= expName
			Z850_reg_exp@units			= "[10~S2~-6   s~S2~-1  ] / [mm/day]"
			Zplot_ctrl					= gsn_csm_contour_map_ce(wks,smth9_Wrap(Z850_reg_ctrl, 0.50, 0.25, True),resS)
			Zplot_exp					= gsn_csm_contour_map_ce(wks,smth9_Wrap(Z850_reg_exp, 0.50, 0.25, True),resS)

			;----------- create the rainfall overlay plot
			Rplot_ctrl					= gsn_csm_contour(wks,Rain_reg_ctrl,resC)
			Rplot_exp					= gsn_csm_contour(wks,Rain_reg_exp,resC)
			overlay(Zplot_ctrl,Rplot_ctrl)
			plot(0)	= Zplot_ctrl

			overlay(Zplot_exp,Rplot_exp)
			plot(1)	= Zplot_exp
			
			;----------- create the difference plots
			resS@tmXBLabelsOn			= True
			;resS@cnMinLevelValF			= -2.5
			;resS@cnMaxLevelValF			=  2.5
			;resS@cnLevelSpacingF		=  0.5
			delete(resC@cnLevels)
			resC@cnLevels	= (/ -.3,-.1,.1,.3 /)
			;resC@cnLevels	= (/ -.15,-.05,.05,.15 /)
			Zdiff			= Z850_reg_exp - Z850_reg_ctrl
			copy_VarMeta(Z850_reg_ctrl,Zdiff)
			Zdiff@long_name	= expName + " - " + ctrlName
			Rdiff			= smth9_Wrap(Rain_reg_exp, 0.50, 0.25, True) - smth9_Wrap(Rain_reg_ctrl, 0.50, 0.25, True)
			copy_VarMeta(Rain_reg_ctrl,Rdiff)
			
			Zplot_diff	= gsn_csm_contour_map_ce(wks,smth9_Wrap(Zdiff, 0.50, 0.25, True),resS)
			Rplot_diff	= gsn_csm_contour(wks,Rdiff,resC)
			overlay(Zplot_diff,Rplot_diff)
			plot(2)		= Zplot_diff
			
			delete(Zplot_ctrl)
			delete(Zplot_exp)
			delete(Zdiff)
			delete(Rplot_ctrl)
			delete(Rplot_exp)
			delete(Rdiff)
			delete(Z850_reg_ctrl)
			delete(Rain_reg_ctrl)
			delete(Z850_reg_exp)
			delete(Rain_reg_exp)
			;delete(plot)
			
		end do			; variable loop

		;------------- create plot page
		pStr		= (/"a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z" /)
		nPanels		= nVars
		pID			= new(nPanels,"string")
		print("nPanels = "+nPanels)
		do i=0,nPanels-1
			pID(i)	= pStr(i)
		end do
		;print(pID)
		resP					= True                   	; modify the panel plot
		resP@gsnFrame			= False                  	; don't advance panel plot
		resP@gsnPanelLabelBar	= False                  	; add common colorbar
		;resP@txString			= expName+" - " ctrlName + "  " seasonName(s); add common title
		resP@gsnPanelBottom		= 0.05                   	; add space at bottom
		resP@gsnPanelYWhiteSpacePercent = 6
		resP@gsnPanelFigureStrings = pID      ; add letter labels to panels (# letters can be > # panels)
		resP@gsnPanelFigureStringsFontHeightF	= 0.012
		resP@gsnPanelFigureStringsPerimOn		= True
		resP@amJust								= "TopLeft"
		gsn_panel(wks,plot,(/3,1/),resP)                	; now draw as one plot
		;------------- label columns
		txres               	= True                     	; text mods desired
		txres@txFontHeightF		= 0.013                    	; font smaller. default big
;		gsn_text_ndc(wks,"mean",0.23,0.855,txres) 
;		gsn_text_ndc(wks,"~F33~s ~F21~(20-100 day filtered)",0.73,0.855,txres) 
;		gsn_text_ndc(wks,"[positive (negative) surface fluxes heat (cool) the atmosphere]",0.5,0.09,txres) 
;		gsn_text_ndc(wks,"overlay:  u850 > 0 [c.i. = 0, 2.5, 5 m/s]",0.5,0.07,txres) 

		;res@tmXBLabelsOn	= False ; turn off longitude labels for next season
		delete(plot)
		
	end do				; season loop

end