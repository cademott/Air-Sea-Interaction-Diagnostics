load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"   
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"    
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"    
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/diagnostics_cam.ncl"    
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"

begin

	print("=============== in plot_L1.1_SfcVariables_MeanStd.ncl =================")

	;------------- set dynamic variable names
	ctrlName	= "SPCCSM"
	ctrlDir		= "/volumes/Rocstor/Model_output/SPCAM3/sp-ccsm_MJODIABATICHEATING/AirSeaDiagnostics/"
	ctrldateStr	= "40101-231231"
	expName		= "SPCAM3_mon"
	expDir		= "/volumes/Rocstor/Model_output/SPCAM3/spcam_monthlySSTs_spec/rerun/daily/AirSea/"
	expdateStr	= "10917-141017"
	lonName		= "lon"

;	ctrlName	= "MetUM-GOML"
;	ctrlDir		= "/volumes/lava/Model_output/MetUM/GOML/AirSea/"
;	ctrldateStr	= "19820101-20061230"
;	expName		= "MetUM-ACM"
;	expDir		= "/volumes/lava/Model_output/MetUM/ACM/AirSea/"
;	expdateStr	= "19820101-20061230"
;	lonName		= "lon"

;	ctrlName	= "CNRM-CM"
;	ctrlDir		= "/volumes/Rocstor/Model_output/CNRM-CM/AirSea/"
;	ctrldateStr	= "19910101-20101231"
;	expName		= "CNRM-ACM"
;	expDir		= "/volumes/Rocstor/Model_output/CNRM-ACM/AirSea/"
;	expdateStr	= "19910101-20101231"
;	lonName		= "lon"

	dirp		= ctrlDir + "plots/"

	;------------- define season names
	seasonName 	= (/ "Nov-Apr", "May-Oct" /)
	
	;------------- define base point locations
	locID		= (/ "90E","150E" /)

;	varName		= (/ "Vdmdt","Vm_hadv","Vomegadmdp","Vlw","Vsw","LHFLX","SHFLX" /)
;	varID		= (/ "dm/dt","HADV","VADV","LW","SW","LH+SH","SHFLX" /)

	varName		= (/ "Vdmdt","Vm_hadv","Vudmdx","Vvdmdy" /)
	varID		= (/ "dm/dt","HADV","uHADV", "vHADV" /)

	
	do s=0,0	; season loop

		do loc = 0,0			; do for each variable
		
			print(" ")
			print("locID = "+locID(loc))

			;------------set up the plots
			wksType 	= "pdf"
			wksName		= dirp + ctrlName + "." + expName + ".MSEbudget_v_longitude.uvHADV." + locID(loc) + "." + seasonName(s)
			print("--------- making "+wksName)
			wks 		= gsn_open_wks(wksType,wksName)		; open a pdf file
			gsn_define_colormap(wks,"cmp_b2r")
			plot 		= new(2*dimsizes(varName),graphic)	

			wksType 	= "pdf"
			wksName		= dirp + expName + "_minus_" + expName + ".MSEbudget_v_longitude.uvHADV." + locID(loc) + "." + seasonName(s)
			print("--------- making "+wksName)
			wksdiff 	= gsn_open_wks(wksType,wksName)		; open a pdf file
			gsn_define_colormap(wks,"cmp_b2r")
			plot 		= new(2*dimsizes(varName),graphic)	
			plotdiff	= new(1,graphic)			; create a plot array

			res						= True 			; plot mods desired
			res@gsnDraw				= False			; don't draw
			res@gsnFrame			= False			; don't advance frame
			res@tiXAxisString		= "longitude"	; x axis title
			res@tiYAxisString		= "[W/m**2] / [mm/day]"	; x axis title
			res@xyLineColors      	= (/ "blue","red" /)  ; line colors
			res@xyLineThicknesses 	= (/2.0, 2.0, 2.0, 2.0, 2.0, 2.0 /)        ; line thicknesses
			res@trYMinF				= -6
			res@trYMaxF				=  6
			res@trXMinF				=  30
			res@trXMaxF				= 240
			res@vpWidthF			= 0.8
			res@vpHeightF			= 0.4
			res@gsnXRefLine         = 90.
			res@gsnYRefLine			= 0.
			res@xyDashPatterns    	= (/0.0,0.0/)        ; line patterns

			resD					= True 			; plot mods desired
			resD@gsnDraw			= False			; don't draw
			resD@gsnFrame			= False			; don't advance frame
			resD@tiXAxisString		= "longitude"	; x axis title
			resD@tiYAxisString		= "[W/m**2] / [mm/day]"	; x axis title
			resD@xyLineColors      	= (/ "black","blue","red","orange","pink","chartreuse2" /)  ; line colors
			resD@xyLineThicknesses 	= (/5,3,3,3,3,3 /)        ; line thicknesses
			resD@trYMinF			= -3
			resD@trYMaxF			=  3
			resD@trXMinF			=  30
			resD@trXMaxF			= 240
			resD@vpWidthF			= 0.8
			resD@vpHeightF			= 0.4
			resD@gsnXRefLine        = 90.
			resD@gsnYRefLine		= 0.
			resD@xyDashPatterns    	= (/0.0,0.0,0,0,0,0,0/)        ; line patterns

			;----------- read in CTRL and EXP MSE budget terms (Vmse,Vdmdt,Vm_hadv,Vomegadmdp,Vlw,Vsw,LHFLX,SHFLX)
			;do v=0,dimsizes(varName)-2
			do v=0,dimsizes(varName)-1
				fili_ctrl	= ctrlDir + "proc/" + ctrlName + ".make_L2.1_regression_propagation." + ctrldateStr + ".PRECT." + varName(v) + "." + seasonName(s) + ".nc"
				fctrl		= addfile(fili_ctrl,"r")
				fili_exp	= expDir + "proc/" + expName + ".make_L2.1_regression_propagation." + expdateStr + ".PRECT." + varName(v) + "." + seasonName(s) + ".nc"
				fexp		= addfile(fili_exp,"r")

				tName				= varName(v)
				temp_ctrl			= fctrl->$tName$(loc,{-2:2},:,:)
				if (varName(v).eq."LHFLX") then		; combine LH and SH
					fili_ctrl	= ctrlDir + "proc/" + ctrlName + ".make_L2.1_regression_propagation." + ctrldateStr + ".PRECT." + varName(v+1) + "." + seasonName(s) + ".nc"
					fctrl		= addfile(fili_ctrl,"r")
					sh			= fctrl->SHFLX(loc,{-2:2},:,:)
					temp_ctrl	= temp_ctrl + sh
					copy_VarMeta(sh,temp_ctrl)
				end if
					
				temp_exp			= fexp->$tName$(loc,{-2:2},:,:)
				if (varName(v).eq."LHFLX") then		; combine LH and SH
					fili_exp	= expDir + "proc/" + expName + ".make_L2.1_regression_propagation." + expdateStr + ".PRECT." + varName(v+1) + "." + seasonName(s) + ".nc"
					fexp		= addfile(fili_exp,"r")
					sh			= fexp->SHFLX(loc,{-2:2},:,:)
					temp_exp	= temp_exp + sh
					copy_VarMeta(sh,temp_exp)
				end if
				data_ctrl			= dim_avg_n_Wrap(rm_single_dims(temp_ctrl),0)
				data_exp			= dim_avg_n_Wrap(rm_single_dims(temp_exp),0)
				if (v.eq.0) then
					data_all 		= new((/2*dimsizes(varName),dimsizes(data_ctrl&$lonName$)/),"float")
					data_diff		= new((/dimsizes(varName),dimsizes(data_ctrl&$lonName$)/),"float")
				end if
				
				if (v.ge.1) then
					navg				= 7
				else
					navg				= 1
				end if
				data_all(v*2,:)		= runave_Wrap(data_ctrl,navg,-1)
				data_all(v*2+1,:)	= runave_Wrap(data_exp,navg,-1)
				data_diff(v,:)		= runave_Wrap(data_exp,navg,-1) - runave_Wrap(data_ctrl,navg,-1)
				plot(v) 			= gsn_csm_xy(wks,data_ctrl&$lonName$,data_all(v*2:v*2+1,:),res)
			end do
			plotdiff				= gsn_csm_xy(wksdiff,data_ctrl&$lonName$,data_diff,resD)

			;------------- create plot page for individual MSE budget terms
			nPanels		= dimsizes(varName)
			pID			= new(nPanels,"string")
			print("nPanels = "+nPanels)
			do i=0,nPanels-1
				pID(i)	= varID(i)
			end do

			resP					= True					; modify the panel plot
			resP@gsnFrame			= False					; don't advance panel plot
			resP@gsnPanelLabelBar	= False					; add common colorbar
			resP@txString			= "MSE budget regressed onto "+locID(loc) + " rainfall"	; add common title
			resP@gsnPanelBottom		= 0.1					; add space at bottom
			resP@gsnPanelYWhiteSpacePercent = 6
			resP@gsnPanelXWhiteSpacePercent = 3
			resP@gsnPanelFigureStrings = pID      ; add letter labels to panels (# letters can be > # panels)
			resP@gsnPanelFigureStringsFontHeightF	= 0.008
			resP@gsnPanelFigureStringsPerimOn		= True
			resP@amJust								= "TopLeft"
			gsn_panel(wks,plot,(/4,2/),resP)				; now draw as one plot

			labels					= (/ expName,ctrlName /)
			;labels					= labels(::-1)
			colors					= (/"red","blue"/)
			;colors					= colors(::-1)
			lgres					= True
			lgres@vpWidthF			= 0.17
			lgres@vpHeightF			= 0.07
			lgres@lgLabelFontHeightF= 0.1
			lgres@lgPerimOn			= False
			lgres@lgMonoLineColor	= False
			lgres@lgLineColors		= colors
			lgres@lgDashIndexes		= (/0.0,0.0/)
			;lgres@lgMonoDashIndex	= False
			;lgres@lgDashIndexes		= dashes
			lgres@lgLineThicknessF	= 2.0
			gsn_legend_ndc(wks,2,labels,0.28,0.43,lgres)
			delete(resP)
			delete(lgres)
			delete(plot)
			delete(labels)
			delete(colors)



			;------------- create plot page for MSE budget term differences
			resP					= True					; modify the panel plot
			resP@gsnFrame			= False					; don't advance panel plot
			resP@gsnPanelLabelBar	= False					; add common colorbar
			resP@txString			= expName + " - " + ctrlName + " MSE budget terms"	; add common title
			resP@gsnPanelBottom		= 0.1					; add space at bottom
			resP@gsnPanelYWhiteSpacePercent = 6
			resP@gsnPanelXWhiteSpacePercent = 3
			gsn_panel(wksdiff,plotdiff,(/1,2/),resP)				; now draw as one plot

			;labels					= varID(0:5)
			labels					= varID(0:3)
			labels					= labels(::-1)
			;colors					= resD@xyLineColors(0:5)
			colors					= resD@xyLineColors(0:3)
			colors					= colors(::-1)
			lgres					= True
			lgres@vpWidthF			= 0.17
			lgres@vpHeightF			= 0.17
			lgres@lgLabelFontHeightF= 0.05
			lgres@lgPerimOn			= False
			lgres@lgMonoLineColor	= False
			lgres@lgLineColors		= colors
			lgres@lgDashIndexes		= (/0,0,0,0,0,0,0/)
			lgres@lgLineThicknessF	= 3.0
			;gsn_legend_ndc(wksdiff,6,labels,0.48,0.39,lgres)
			gsn_legend_ndc(wksdiff,4,labels,0.48,0.39,lgres)
			
			delete(plotdiff)
			delete(lgres)
			delete(resP)
			delete(labels)
			delete(colors)
		end do ; location loop


	end do 	; season loop

end
