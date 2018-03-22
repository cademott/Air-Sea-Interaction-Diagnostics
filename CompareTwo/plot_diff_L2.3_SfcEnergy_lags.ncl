;***********************************************************
; Compute : fixme
;
; 1.  do land and ocean separately
; 2.  do IO and WPAC ocean areas separately
;***********************************************************

load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"  
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"  
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl" 
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/diagnostics_cam.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/contrib/calendar_decode2.ncl"
load "/Users/mburt/NCL/Charlotte/AirSea/contrib_JJB.ncl"
load "/Users/mburt/NCL/Charlotte/AirSea/substring.ncl"

begin
  
print("")
print("============= in plot_diff_L2.3_SfcEnergy_lags.ncl =============")   

progGen		= ".make_L2.2_regression_nopropagation."


;------------- set dynamic variable names
	ctrlName	= getenv("CTRLCASE")
	ctrlDir		= getenv("CTRLDIR")
	expName		= getenv("EXPCASE")
	expDir		= getenv("EXPDIR")
	;varName		= getenv("inName")
	ctrldateStr	= getenv("CTRLDATESTR")
	expdateStr	= getenv("EXPDATESTR")

	diri		="/pond/demott/ECHAM-CPL/AirSea/proc/ECHAM-CPL_minus_ECHAM-A31/"
	dirp		=ctrlDir + "plots/"
	ctrlDir		= ctrlDir + "proc/"
	
;------------- define seasons
seasonName	= (/"Nov-Apr","May-Oct"/)

;------------- filename prefix

do s=0,1 
	;------------set up the plot
	wksType = "pdf"
		wksName= dirp + ctrlName + "_minus_"+ expName + ".plot_diff_L2.3_SfcEnergy_lags." + seasonName(s)
	print("--------- making "+wksName)
	wks = gsn_open_wks(wksType,wksName)		; open a ps file
	gsn_define_colormap(wks,"cmp_b2r")
	plot = new(1,graphic)					; create a plot array

	res					= True 				; plot mods desired
	res@gsnDraw			= False				; don't draw
	res@gsnFrame		= False				; don't advance frame
	;res@gsClipOn		= False				; don't clip lines
	res@tiXAxisString	= "lag (day)"		; x axis title
	;							lh   	 	sh     				sw    	 lw      qnet   zero   sst   
	res@xyLineColors      = (/"chartreuse4","darkolivegreen2","coral2","magenta","black","black","blue"/)  ; line colors
	res@xyLineThicknesses = (/2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0 /)        ; line thicknesses
	res@xyDashPatterns    = (/0.0, 0.0, 0.0, 0.0, 0,0, 0,0, 0.0, 0.0 /)        ; line patterns
	res@gsnXRefLine            = 0.
	res@gsnXRefLineColor       = "grey37"
	res@gsnXRefLineDashPattern = 0
	res@gsnXRefLineThicknessF  = 0.5

	res@gsnYRefLine            = 0.
	res@gsnYRefLineColor       = "grey37"
	res@gsnYRefLineDashPattern = 0
	res@gsnYRefLineThicknessF  = 0.5

	;res@xyMarkLineModes   = (/"MarkLines","MarkLines","MarkLines","MarkLines","MarkLines","MarkLines","MarkLines","MarkLines"/) ; markers?
	;res@xyMarkerColors    = res@xyLineColors    ; color
	;res@xyMarkers         = (/16,16,16,16,16,16,16,16/)          ; style

	; resources for "SST" variable
	resR                        = True                      
	;resR@xyMarkLineModes        = "MarkLines"                   ; dashed line for 2nd
	resR@trYMinF				= -0.2
	resR@trYMaxF				= 0.2
	;resR@xyMarkers        		= 16                   ; dashed line for 2nd
	resR@xyLineThicknesses      = 2                   ; thicker line
	resR@tiYAxisString 			= "K"   ; axis string
	;resR@xyMarkerColors			= "gray"
	resR@xyLineColors			= "blue"

	;------------- read in composite surface variables from "nopropagation" files 
	tName		= "LHFLX"
	fili		= diri +  ctrlName + "_minus_"+ expName + progGen + "PRECT." + tName + "." + seasonName(s) + ".nc"
	f1			= addfile(fili,"r")
	lh			= f1->$tName$(:,{80:90})

	tName		= "SHFLX"
	fili		= diri +  ctrlName + "_minus_"+ expName + progGen + "PRECT." + tName + "." + seasonName(s) + ".nc"
	f1			= addfile(fili,"r")
	sh			= f1->$tName$(:,{80:90})

	tName		= "LWsfc"
	fili		= diri +  ctrlName + "_minus_"+ expName + progGen + "PRECT." + tName + "." + seasonName(s) + ".nc"
	f1			= addfile(fili,"r")
	lw			= f1->$tName$(:,{80:90})

	tName		= "SWsfc"
	fili		= diri +  ctrlName + "_minus_"+ expName + progGen + "PRECT." + tName + "." + seasonName(s) + ".nc"
	f1			= addfile(fili,"r")
	sw			= f1->$tName$(:,{80:90})

	tName		= "Qnet"
	fili		= diri +  ctrlName + "_minus_"+ expName + progGen + "PRECT." + tName + "." + seasonName(s) + ".nc"
	f1			= addfile(fili,"r")
	qnet		= f1->$tName$(:,{80:90})

	tName		= "SST"
	fili		= diri +  ctrlName + "_minus_"+ expName + progGen + "PRECT." + tName + "." + seasonName(s) + ".nc"
	f1			= addfile(fili,"r")
	sst			= f1->$tName$(:,{80:90})
	rainsd		= f1->gridp_stdev({80:90})
	lag			= f1->lag
	
	
	zeros	= new(61,"integer",0)
	data_all = new((/6,dimsizes(lag)/),"float")
	data_all(0,:)=-2*dim_avg_n_Wrap(lh*conform_dims(dimsizes(lh),rainsd,1),1)
	data_all(1,:)=-2*dim_avg_n_Wrap(sh*conform_dims(dimsizes(lh),rainsd,1),1)
	data_all(2,:)=2*dim_avg_n_Wrap(sw*conform_dims(dimsizes(lh),rainsd,1),1)
	data_all(3,:)=-2*dim_avg_n_Wrap(lw*conform_dims(dimsizes(lh),rainsd,1),1)
	data_all(4,:)=2*dim_avg_n_Wrap(qnet*conform_dims(dimsizes(lh),rainsd,1),1)
	data_all(5,:)=zeros
	sst_lag		 =1.5*dim_avg_n_Wrap(sst*conform_dims(dimsizes(lh),rainsd,1),1)
	res@tiMainString	= "Surface Energy Budget" ; title
	res@tiYAxisString	= "W/m**2"			; y axis title
	res@trYMinF			= -40
	res@trYMaxF			= 40
	res@trXMinF			= -30
	res@trXMaxF			= 30
	plot(0) = gsn_csm_xy2(wks,lag,data_all,sst_lag,res,resR)          ; Draw an XY plot with 1 curve.
	delete(data_all)

	;------------- create plot page
	resP					= True                   ; modify the panel plot
	resP@gsnFrame			= False                  ; don't advance panel plot
	resP@gsnPanelLabelBar	= False                  ; add common colorbar
	resP@txString			= ctrlName + " - " + expName + "," + " "+ seasonName(s)
	resP@gsnPanelBottom		= 0.1                   ; add space at bottom
	gsn_panel(wks,plot,(/2,2/),resP)               ; now draw as one plot

	labels					= (/ "LH","SH","SW" /)
	labels					= labels(::-1)
	colors					= (/"chartreuse4","darkolivegreen2","coral2"/)
	colors					= colors(::-1)
	dashes					= (/ 0.0, 0.0, 0.0, 0.0 /)
	lgres					= True
	lgres@vpWidthF			= 0.15
	lgres@vpHeightF			= 0.1
	;lgres@lbLabelJust		= "CenterLeft"
	lgres@lgPerimOn			= False
	lgres@lgMonoLineColor	= False
	lgres@lgLineColors		= colors
	;lgres@lgMonoDashIndex	= False
	lgres@lgDashIndexes		= dashes 
	lgres@lgLineThicknessF	= 2.0
	gsn_legend_ndc(wks,3,labels,0.33,0.48,lgres)

	labels					= (/ "LW","Qnet","SST" /)
	labels					= labels(::-1)
	colors					= (/"magenta","black","blue"/)
	colors					= colors(::-1)
	lgres					= True
	lgres@vpWidthF			= 0.15
	lgres@vpHeightF			= 0.1
	;lgres@lbLabelJust		= "CenterLeft"
	lgres@lgPerimOn			= False
	lgres@lgMonoLineColor	= False
	lgres@lgLineColors		= colors
	;lgres@lgMonoDashIndex	= False
	lgres@lgDashIndexes		= dashes 
	lgres@lgLineThicknessF	= 2.0
	gsn_legend_ndc(wks,3,labels,0.50,0.48,lgres)



end do		; season loop

end













