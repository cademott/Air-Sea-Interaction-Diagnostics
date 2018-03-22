load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"   
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"    
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"    
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/diagnostics_cam.ncl"    
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"

begin

	print("=============== in plot_diff_Rain_MeanStd.ncl =================")

	;------------- set dynamic variable names
;	ctrlName	= "SPCCSM"
;	ctrlDir		= "/volumes/Rocstor/Model_output/SPCAM3/sp-ccsm_MJODIABATICHEATING/AirSeaDiagnostics/"
;	expName		= "SPCAM3_mon"
;	expDir		= "/volumes/Rocstor/Model_output/SPCAM3/spcam_monthlySSTs_spec/rerun/daily/AirSea/"
;	ctrldateStr	= "40101-231231"
;	expdateStr	= "10917-141017"

;	ctrlName	= "MetUM-GOML"
;	ctrlDir		= "/volumes/lava/Model_output/MetUM/GOML/AirSea/"
;	expName		= "MetUM-ACM"
;	expDir		= "/volumes/lava/Model_output/MetUM/ACM/AirSea/"
;	ctrldateStr	= "19820101-20061230"
;	expdateStr	= "19820101-20061230"

;	ctrlName	= "CNRM-CM"
;	ctrlDir		= "/volumes/Rocstor/Model_output/CNRM-CM/AirSea/"
;	expName		= "CNRM-ACM"
;	expDir		= "/volumes/Rocstor/Model_output/CNRM-ACM/AirSea/"
;	ctrldateStr	= "19910101-20101231"
;	expdateStr	= "19910101-20101231"

	ctrlName	= "v1.5.2_B1850_CTR"
	ctrlDir		= "/volumes/Rocstor/Model_output/CESM/v1.5.2_B1850_CTR/AirSea/"
	expName		= "v1.5.2_B1850_EBM"
	expDir		= "/volumes/Rocstor/Model_output/CESM/v1.5.2_B1850_EBM/AirSea/"
	ctrldateStr	= "10101-201231"
	expdateStr	= "10101-201231"

	dirp		= expDir + "plots/"
	
	progGen		= ".make_L1.4_mean_stdev_map."

	;------------- define season names
	seasonName 	= (/ "Nov-Apr", "May-Oct" /)
	varName		= (/ "PRECT", 			"LHFLX" 	/)
	varID		= (/ "precipitation",	"LH" 		/)
	varUnits	= (/ "mm day~S2~-1",	"W m~S2~-2" /)
	MeanMinLev	= (/  0,				80.			/)
	MeanMaxLev	= (/ 12,			   180.			/)
	MeanInt		= (/  2,				10.			/)
	DiffMMinLev	= (/ -2.5,				-25			/)
	DiffMMaxLev	= -1. * DiffMMinLev
	DiffMInt	= (/ 0.5,				  5.		/)
	
	StdevMinLev	= (/  0,				 0.			/)
	StdevMaxLev	= (/  5,				40.			/)
	StdevInt	= (/  0.5,				 5.			/)
	DiffSMinLev	= (/ -2.5,				-10			/)
	DiffSMaxLev	= -1. * DiffSMinLev
	DiffSInt	= (/ 0.5,				 2.			/)
	
	;------------- plot resources for base plot
	;------------- plot resources for base plot
	res                     	= True
	res@gsnDraw 				= False			; don't draw
	res@gsnFrame				= False			; don't advance frame
	res@cnInfoLabelOn			= False 		; turn off cn info label
	res@cnFillOn				= True			; turn on color
	res@cnLinesOn				= True			; turn off contour lines
	res@cnSpanFillPalette		= True
	res@tmXBLabelsOn			= True
	res@lbOrientation			= "Vertical"	; vertical label bar
	res@tmXBLabelFontHeightF	= 0.017         ; change maj lat tm spacing
	res@tmYLLabelFontHeightF	= 0.017         ; change maj lat tm spacing
	res@mpMinLatF				= -30.
	res@mpMaxLatF				=  30.
	res@mpMinLonF 				=  30.
	res@mpMaxLonF				= 240.
	res@mpCenterLonF			= 135. 
	res@cnLevelSelectionMode	= "ManualLevels"   
	res@cnFillPalette			= "MPL_rainbow"
	;res@cnFillColors			= ispan(2,124,11)

	;------------- plot resources for difference plot
	resD                     	= True
	resD@gsnDraw 				= False			; don't draw
	resD@gsnFrame				= False			; don't advance frame
	resD@cnInfoLabelOn			= False 		; turn off cn info label
	resD@cnFillOn				= True			; turn on color
	resD@cnLinesOn				= True			; turn off contour lines
	resD@cnSpanFillPalette		= True			; spread out color table
	resD@tmXBLabelsOn			= False
	resD@lbOrientation			= "Vertical"	; vertical label bar
	resD@tmXBLabelFontHeightF	= 0.017         ; change maj lat tm spacing
	resD@tmYLLabelFontHeightF	= 0.017         ; change maj lat tm spacing
	resD@mpMinLatF				= -30.
	resD@mpMaxLatF				=  30.
	resD@mpMinLonF 				=  30.
	resD@mpMaxLonF				= 240.
	resD@mpCenterLonF			= 135. 
	resD@cnFillPalette			= "NCV_blu_red"
	resD@cnLevelSelectionMode	= "ManualLevels"   

;	resS                     	= True
;	resS@gsnDraw 				= False			; don't draw
;	resS@gsnFrame				= False			; don't advance frame
;	resS@cnInfoLabelOn			= False 		; turn off cn info label
;	resS@cnFillOn				= True			; turn on color
;	resS@cnLinesOn				= True			; turn off contour lines
;	resS@cnLineColor			= "grey60"
;	resS@tmXBLabelsOn			= False
;	resS@lbOrientation			= "Vertical"	; vertical label bar
;	resS@tmXBLabelFontHeightF	= 0.017         ; change maj lat tm spacing
;	resS@tmYLLabelFontHeightF	= 0.017         ; change maj lat tm spacing
;	resS@mpMinLatF				= -30.
;	resS@mpMaxLatF				=  30.
;	resS@mpMinLonF 				=  30.
;	resS@mpMaxLonF				= 240.
;	resS@mpCenterLonF			= 135. 
;	resS@cnLevelSelectionMode	= "ManualLevels"   


;	resS                     	= True
;	resS@gsnDraw 				= False			; don't draw
;	resS@gsnFrame				= False			; don't advance frame
;	resS@cnInfoLabelOn			= False 		; turn off cn info label
;	resS@cnFillOn				= True			; turn on color
;	resS@cnLinesOn				= True			; turn off contour lines
;	resS@cnLineColor			= "grey60"
;	resS@gsnSpreadColors		= True			; spread out color table
;	resS@gsnSpreadColorStart	= 2 
;	resS@gsnSpreadColorEnd		= -3 
;	resS@tmXBLabelsOn			= False
;	resS@lbOrientation			= "Vertical"	; vertical label bar
;	resS@tmXBLabelFontHeightF	= 0.017         ; change maj lat tm spacing
;	resS@tmYLLabelFontHeightF	= 0.017         ; change maj lat tm spacing
;	resS@mpMinLatF				= -30.
;	resS@mpMaxLatF				=  30.
;	resS@mpMinLonF 				=  30.
;	resS@mpMaxLonF				= 300.
;	resS@mpCenterLonF			= 165. 
;	resS@mpGridLatSpacingF		=  30.
;	resS@cnLevelSelectionMode	= "ManualLevels"   

	do s = 0,0 				; do for each season
			
		do v = 0,0
		;do v = 0,dimsizes(varName) -1
			fili_ctrl	= ctrlDir + "proc/" + ctrlName + progGen + ctrldateStr + "." + varName(v) + "." + seasonName(s) + ".nc"
			fctrl		= addfile(fili_ctrl,"r")
			fili_exp	= expDir + "proc/" + expName + progGen + expdateStr + "." + varName(v) + "." + seasonName(s) + ".nc"
			fexp		= addfile(fili_exp,"r")

			nVars		= 3


			;============ MEAN FIELD ===========================
			;----------- read in base plot mean
			tName				= varName(v) + "_mean"
			ctrl_mean			= fctrl->$tName$
			ctrl_mean			= smth9_Wrap(ctrl_mean, 0.50, 0.25, True)
			ctrl_mean@long_name	= "mean " + varID(v) + ", " + ctrlName
			ctrl_mean@units		= varUnits(v)
			exp_mean			= fexp->$tName$
			exp_mean			= smth9_Wrap(exp_mean, 0.50, 0.25, True)
			mean_diff			= exp_mean - ctrl_mean
			copy_VarMeta(exp_mean,mean_diff)
			mean_diff@long_name	= expName + " - " + ctrlName
			mean_diff@units		= varUnits(v)
			
			;----------- set up plot file
			wksType = "pdf"
			;wksName	= dirp + expName + "_minus_" + ctrlName + ".Rain_Z850_map." + locID(loc) + "." +seasonName(s)+".zonalAnom"
			wksName	= dirp + expName + "_minus_" + ctrlName + ".Mean." + varName(v) + "." +seasonName(s)
			print(wksName)
			wks = gsn_open_wks(wksType,wksName)		; open a ps file
			gsn_define_colormap(wks,"cmp_b2r")
			plot = new(2,graphic)                 	

			;------------ plot mean variable
			;res@tmXBLabelsOn		= True
			;res@cnFillPalette		= "MPL_rainbow"
			;res@gsnSpreadColors		= True			; spread out color table
			;res@gsnSpreadColorStart	= 2 
			;res@gsnSpreadColorEnd	= -3 
			res@cnMinLevelValF		=  MeanMinLev(v)
			res@cnMaxLevelValF		=  MeanMaxLev(v)
			res@cnLevelSpacingF		=  MeanInt(v)
			plot(0)					= gsn_csm_contour_map_ce(wks,ctrl_mean,res)

			;------------ plot difference of mean
			;resD@cnFillPalette		= "NCV_blu_red"
			;resD@gsnSpreadColors	= True			; spread out color table
			;resD@gsnSpreadColorStart= 2 
			;resD@gsnSpreadColorEnd	= -3 
			resD@cnMinLevelValF		=  DiffMMinLev(v)
			resD@cnMaxLevelValF		=  DiffMMaxLev(v)
			resD@cnLevelSpacingF	=  DiffMInt(v)
			plot(1)					= gsn_csm_contour_map_ce(wks,mean_diff,resD)

			;------------- create plot page
;			pStr		= (/"a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z" /)
;			nPanels		= nVars
;			pID			= new(nPanels,"string")
;			print("nPanels = "+nPanels)
;			do i=0,nPanels-1
;				pID(i)	= pStr(i)
;			end do
			;print(pID)
			resP					= True                   	; modify the panel plot
			resP@gsnFrame			= False                  	; don't advance panel plot
			resP@gsnPanelLabelBar	= False                  	; add common colorbar
			;resP@txString			= expName+" - " ctrlName + "  " seasonName(s); add common title
			resP@gsnPanelBottom		= 0.05                   	; add space at bottom
			resP@gsnPanelYWhiteSpacePercent = 6
;			resP@gsnPanelFigureStrings = pID      ; add letter labels to panels (# letters can be > # panels)
;			resP@gsnPanelFigureStringsFontHeightF	= 0.012
;			resP@gsnPanelFigureStringsPerimOn		= True
;			resP@amJust								= "TopLeft"
			gsn_panel(wks,plot,(/1,2/),resP)                	; now draw as one plot
			delete(plot)
		
			;============ STDEV FIELD ===========================
			tName				= varName(v) + "_stdev"
			ctrl_stdev			= fctrl->$tName$
			ctrl_stdev			= smth9_Wrap(ctrl_stdev, 0.50, 0.25, True)
			ctrl_stdev@long_name= "stdev " + varID(v) + ", " + ctrlName
			ctrl_stdev@units	= varUnits(v)
			exp_stdev			= fexp->$tName$
			exp_stdev			= smth9_Wrap(exp_stdev, 0.50, 0.25, True)
			stdev_diff			= exp_stdev - ctrl_stdev
			copy_VarMeta(exp_stdev,stdev_diff)
			stdev_diff@long_name= expName + " - " + ctrlName
			stdev_diff@units	= varUnits(v)
			stdev_diff			= runave_n_Wrap(smth9_Wrap(stdev_diff, 0.50, 0.25, True),7,-1,1)
				
			;----------- set up plot file
			wksType = "pdf"
			;wksName	= dirp + expName + "_minus_" + ctrlName + ".Rain_Z850_map." + locID(loc) + "." +seasonName(s)+".zonalAnom"
			wksName	= dirp + expName + "_minus_" + ctrlName + ".StDev." + varName(v) + "." +seasonName(s)
			print(wksName)
			wks = gsn_open_wks(wksType,wksName)		; open a ps file
			gsn_define_colormap(wks,"cmp_b2r")
			plot = new(2,graphic)                 	

			;------------ plot mean variable
			;res@tmXBLabelsOn		= True
			;res@cnFillPalette		= "MPL_rainbow"
			res@cnMinLevelValF		=  StdevMinLev(v)
			res@cnMaxLevelValF		=  StdevMaxLev(v)
			res@cnLevelSpacingF		=  StdevInt(v)
			plot(0)					= gsn_csm_contour_map_ce(wks,ctrl_stdev,res)

			;------------ plot difference of mean
			;resD@cnFillPalette		= "NCV_blu_red"
			resD@cnMinLevelValF		=  DiffSMinLev(v)
			resD@cnMaxLevelValF		=  DiffSMaxLev(v)
			resD@cnLevelSpacingF	=  DiffSInt(v)
			plot(1)					= gsn_csm_contour_map_ce(wks,stdev_diff,resD)

			;------------- create plot page
;			pStr		= (/"a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z" /)
;			nPanels		= nVars
;			pID			= new(nPanels,"string")
;			print("nPanels = "+nPanels)
;			do i=0,nPanels-1
;				pID(i)	= pStr(i)
;			end do
			;print(pID)
			resP					= True                   	; modify the panel plot
			resP@gsnFrame			= False                  	; don't advance panel plot
			resP@gsnPanelLabelBar	= False                  	; add common colorbar
			;resP@txString			= expName+" - " ctrlName + "  " seasonName(s); add common title
			resP@gsnPanelBottom		= 0.05                   	; add space at bottom
			resP@gsnPanelYWhiteSpacePercent = 6
;			resP@gsnPanelFigureStrings = pID      ; add letter labels to panels (# letters can be > # panels)
;			resP@gsnPanelFigureStringsFontHeightF	= 0.012
;			resP@gsnPanelFigureStringsPerimOn		= True
;			resP@amJust								= "TopLeft"
			gsn_panel(wks,plot,(/1,2/),resP)                	; now draw as one plot
			delete(plot)

		end do 			; variable loop

	end do				; season loop

end