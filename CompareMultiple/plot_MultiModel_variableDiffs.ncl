load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"   
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"    
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"    
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/diagnostics_cam.ncl"    
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"

begin
	caseName	= (/"SPCCSM",\
					"SPCAM3_mon",\
					"MetUM-GOML",\
					"MetUM-ACM",\
					"ECHAM-CPL",\
					"ECHAM-A31",\
					"CNRM-CM",\
					"CNRM-ACM" /)
	diri		= (/"/volumes/Rocstor/Model_output/SPCAM3/sp-ccsm_MJODIABATICHEATING/MJO_wave_convection_diagnostics/",\
					"/volumes/Rocstor/Model_output/SPCAM3/spcam_monthlySSTs_spec/MJO_wave_convection_diagnostics/",\
					"/volumes/lava/Model_output/MetUM/GOML/MJO_wave_convection_diagnostics/",\
					"/volumes/lava/Model_output/MetUM/ACM/MJO_wave_convection_diagnostics/",\
					"/pond/demott/ECHAM-CPL/MJO_wave_convection_diagnostics/",\
					"/pond/demott/ECHAM-A31/MJO_wave_convection_diagnostics/" ,\
					"/volumes/Rocstor/Model_output/CNRM-CM/MJO_wave_convection_diagnostics/",\
					"/volumes/Rocstor/Model_output/CNRM-ACM/MJO_wave_convection_diagnostics/" /)
	dirp		= "/Users/demott/Projects/Coup_Uncoup/"
	;varDim		= (/  3,   			3,				3,			3,		2,				2,			2,			2,				2,				2,					2,			2,			2,			2,			2,				2    /)

	;===== 2D variable meta data
	varName2	= (/	"SPD",\
						"LHFLX",\
						"SHFLX",\
						"delQ",\
						"delT",\
						"SFCP",\
						"Vdmdt",\
						"Vm_hadv",\
						"Vudmdx",\
						"Vvdmdy",\
						"Vomegadmdp",\
						"Vlw",\
						"SST",\
						"PW",\
						"Z" /)
						
	smooth2		= (/ 	"false",\
						"true",\
						"true",\
						"true",\
						"true",\
						"false",\
						"false",\
						"true",\
						"true",\
						"true",\
						"true",\
						"false",\
						"false",\
						"false",\
						"false" /)
						
	lagday2		= (/ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 /)

	varLabel2	= (/ 	"|~F14~V~F21~|~B3~ref",\										; Sfc |V|
						"~F14~LH",\														; LHFLX
						"~F14~SH",\														; SHFLX
						"~F8~D~F14~q",\													; delta-q
						"~F8~D~F14~T",\													; delta-T
						"~F14~P~F21~~B3~sfc",\											; Psfc
						"~F34~6~F18~O~F14~m~F18~P~F21~/~F34~6~F14~t",\					; dmdt
						"-~F18~O~F14~V~F18~ D ~F34~Q~F14~m~F18~P",\			; HADV
						"-~F18~O~F14~u~F18~ D ~F34~6~F14~m~F21~/~F34~6~F14~x~F18~P", \	; uHADV
						"-~F18~O~F14~v~F18~ D ~F34~6~F14~m~F21~/~F34~6~F14~y~F18~P", \	; vHADV
						"-~F18~O~F8~w~F18~ D ~F34~6~F14~m~F21~/~F34~6~F14~p~F18~P",\	; omegadmdp
						"~F18~O~F14~LW~F18~P",\											; LW
						"~F14~SST",\													; SST
						"~F14~PW",\														; PW
						"~F14~Z~F21~~B3~850~F21" /)									; Z850

	varUnits2	= (/ 	"m s~S2~-1",\		; sfc |V|
					 	"W m~S2~-2",\		; LHFLX
					 	"W m~S2~-2",\		; SHFLX
					 	"g kg~S2~-1",\		; delta-q
					 	"K",\				; delta-T
					 	"hPa",\				; Psfc
					 	"W m~S2~-2",\		; dmdt
					 	"W m~S2~-2",\		; m_HADV
					 	"W m~S2~-2",\		; uHADV
					 	"W m~S2~-2",\		; vHADV
					 	"W m~S2~-2",\		; omegadmdp
					 	"W m~S2~-2",\		; LW
					 	"K",\				; SST
					 	"kg m~S2~-2",\		; PW
					 	"m"/)				; Z850
					 	
	cnMinData2	= (/ 	 -5.,\				; sfc |V|
					 	 -5.,\				; LHFLX
					 	 -0.5,\				; SHFLX
					 	 -0.25,\			; delta-q
					 	 -0.1,\				; delta-T
					 	-20.,\				; Psfc
					 	 -5.,\				; dmdt
					 	 -5.,\				; m_HADV
					 	 -5.,\				; uHADV
					 	 -5.,\				; vHADV
					 	 -5.,\				; omegadmdp
					 	 -5.,\				; LW
					 	  -.125,\			; SST
					 	 -1.,\				; PW
					 	 -1.25 /)			; Z850

	cnSpcData2	= (/	1.0,\		; sfc |V|
						1.0,\		; LHFLX
						0.1,\		; SHFLX
						0.05,\		; delta-q
						0.02,\		; delta-T
						4.0,\		; Psfc
						1.0,\		; dmdt
						1.0,\		; m_HADV
						1.0,\		; uHADV
						1.0,\		; vHADV
						1.0,\		; omegadmdp
						1.0,\		; Vlw
						0.025,\		; SST
						0.2,\		; PW
						0.25 /)		; Z850

	;===== 3D variable meta data
	varName3	= (/	"U",\
						"V",\
				 		"OMEGA",\
				 		"Z" /)

	lagday3		= (/ 0, 0, 0, 5 /)

	varLabel3	= (/	"~F14~U~F21~~B3~850",\		; U850
						"~F14~V~F21~~B3~850",\		; V850
						"~F8~w~F21~~B3~850",\		; omega850
						"~F14~Z~F21~~B3~850" /)		; Z850

	varUnits3	= (/	"m s~S2~-1",\				; U850
					 	"m s~S2~-1",\				; V850
					 	"mb day~S2~-1",\			; omega850
					 	"m" /)						; Z850				 	

	cnMinData3	= (/	-2.5,\						; U850
					 	 -0.625,\					; V850
					 	-10.,\						; omega850
					 	 -5. /)						; Z850

	cnSpcData3	= (/	0.5,\						; U850
						0.125,\						; V850
						2.,\						; omega850
						1. /)						; Z850	
						
	cnMinRain	= -1.5
	cnMaxRain	=  1.5
	cnSpcRain	=  0.3

	;----------- set up plot file
	res                     	= True
	res@gsnDraw 				= False			; don't draw
	res@gsnFrame				= False			; don't advance frame
	res@cnInfoLabelOn			= False 		; turn off cn info label
	res@cnFillOn				= True			; turn on color
	res@cnLinesOn				= True			; turn off contour lines
	res@cnLineColor				= "grey60"
	res@gsnContourZeroLineThicknessF= 0
	res@gsnSpreadColors			= True			; spread out color table
	res@gsnSpreadColorStart		= 2 
	res@gsnSpreadColorEnd		= -3 
	res@tmXBLabelsOn			= False
	res@tmXBLabelFontHeightF	= 0.017         ; change maj lat tm spacing
	res@tmYLLabelFontHeightF	= 0.017         ; change maj lat tm spacing
	res@mpMinLatF				= -30.
	res@mpMaxLatF				=  30.
	res@mpMinLonF 				=  30.
	res@mpMaxLonF				= 240.
	res@mpCenterLonF			= 135. 
	res@cnLevelSelectionMode	= "ManualLevels"   
	res@cnFillPalette			= "BlueWhiteOrangeRed"
	res@cnFillColors			= tointeger(fspan(20,234,12))
	res@gsnAddCyclic			= False
	res@gsnAddCyclic			= False
	res@lbLabelBarOn			= False

	;------------- rainfall overlay plot resources 
	Rres                     	= True
	Rres@gsnDraw				= False
	Rres@gsnFrame				= False
	Rres@cnFillOn				= False			; turn off color
	Rres@cnLinesOn				= True			; turn on contour lines
	Rres@cnLineColor			= "Black"
	Rres@cnLineThicknessF		= 2.
	Rres@cnInfoLabelOn			= False
	Rres@cnLevelSelectionMode	= "ManualLevels"   
	Rres@tiXAxisOn				= False
	Rres@tiYAxisOn				= False
	Rres@tiMainOn				= False
	Rres@gsnContourNegLineDashPattern	= 1
	Rres@gsnContourZeroLineThicknessF	= 0
	Rres@cnMinLevelValF			= cnMinRain
	Rres@cnMaxLevelValF			= cnMaxRain
	Rres@cnLevelSpacingF		= cnSpcRain 
	Rres@gsnAddCyclic			= False
		

	do lagday = -10,10,5
	;do lagday = 25,25
	print("lagday = " + lagday)
	
	;------------- plot resources for map marker
	polyres					= True
	polyres@gsMarkerIndex	= 16
	polyres@gsMarkerSizeF	= 10.
	polyres@gsMarkerColor	= "orangered"	

	;----- 2D variable plots
	;do v=1,dimsizes(varName2)-1
	do v=14,14
		print("varName = " + varName2(v))
		
		;----- set up plot file
		wksType 			= "pdf"
		wksName				= dirp + "multi_model." + varName2(v) + "_diff.lag" + lagday
		wks 				= gsn_open_wks(wksType,wksName)		; open a ps file
		plot				= new(12,graphic)

		res@cnMinLevelValF	= cnMinData2(v)
		res@cnMaxLevelValF	= -1. * cnMinData2(v)
		res@cnLevelSpacingF	= cnSpcData2(v)		

		;----- read in data and make some nice plots
		do c=0,dimsizes(caseName)-2,2
			;----- read coupled model rainfall
			fili			= caseName(c) + ".PRECT.PRECT.15S-15N_hw10_regressions_90E.Nov-Apr.nc"
			fr				= addfile(diri(c) + fili,"r")
			rain_c			= dim_avg_n_Wrap(fr->PRECT_reg_90E({lagday-2:lagday+2},:,{30:240}),0)
			eqrain			= dim_avg_n_Wrap(rain_c({-10:10},:),0)
			maxlon			= rain_c&lon(ind(eqrain.eq.max(eqrain)))
			print("maxlon = "+maxlon)
			
			;----- read uncoupled model rainfall
			fili			= caseName(c+1) + ".PRECT.PRECT.15S-15N_hw10_regressions_90E.Nov-Apr.nc"
			fr				= addfile(diri(c+1) + fili,"r")
			rain_uc			= dim_avg_n_Wrap(fr->PRECT_reg_90E({lagday-2:lagday+2},:,{30:240}),0)
			sd_uc			= fr->rain_stdev

			;----- read coupled model variable
			fili			= caseName(c) + ".PRECT." + varName2(v) + ".15S-15N_hw10_regressions_90E.Nov-Apr.nc"
			f				= addfile(diri(c) + fili,"r")
			tName			= varName2(v) + "_reg_90E"
			if (varName2(v).eq."Z") then
				if (caseName(c).eq."ECHAM-CPL".or.caseName(c).eq."ECHAM-A31") then
					plevel	= 85000
				else
					plevel	= 850
				end if
				data_c		= dim_avg_n_Wrap(f->$tName$({lagday-2:lagday+2},{plevel},:,{30:240}),0)
			else
				data_c		= dim_avg_n_Wrap(f->$tName$({lagday-2:lagday+2},:,{30:240}),0)
			end if
			
			;----- read uncoupled model variable
			fili			= caseName(c+1) + ".PRECT." + varName2(v) + ".15S-15N_hw10_regressions_90E.Nov-Apr.nc"
			f				= addfile(diri(c+1) + fili,"r")
			tName			= varName2(v) + "_reg_90E"
			if (varName2(v).eq."Z") then
				data_uc		= dim_avg_n_Wrap(f->$tName$({lagday-2:lagday+2},{plevel},:,{30:240}),0)
			else
				data_uc		= dim_avg_n_Wrap(f->$tName$({lagday-2:lagday+2},:,{30:240}),0)
			end if

			if (varName2(v).eq."delQ") then
				data_c		= data_c * 1000.
				data_uc		= data_uc * 1000.
			end if
			;printMinMax(data,True)
			
			;----- generate differences
			prain			= rain_c - rain_uc
			copy_VarMeta(rain_c,prain)
			;if (smooth2(v).eq."true") then
				data_c		= smth9_Wrap(data_c,0.5,0.25,True)
				data_uc		= smth9_Wrap(data_uc,0.5,0.25,True)
				pdata		= data_c - data_uc
				copy_VarMeta(data_c,pdata)
			;else
			;	pdata		= data_c - data_uc
			;	copy_VarMeta(data_c,pdata)
			;end if
			pdata@long_name	= caseName(c) + " - " + caseName(c+1)
			pdata@units		= varLabel2(v)
			pdata&lon@units	= str_lower(data_c&lon@units)
			pdata&lat@units	= str_lower(data_c&lat@units)
			prain&lon@units	= str_lower(rain_c&lon@units)
			prain&lat@units	= str_lower(rain_c&lat@units)
			if (c.eq.4) then
				res@tmXBLabelsOn			= True
			end if
			bplot			= gsn_csm_contour_map_overlay(wks,pdata,smth9_Wrap(prain,0.5,0.25,True),res,Rres)
			if (c.eq.0) then
				dum0		= gsn_add_polymarker(wks,bplot,maxlon,0,polyres)
				dum			= new (4,typeof(dum0))
				delete(dum0)
			end if
			dum(c/2)		= gsn_add_polymarker(wks,bplot,maxlon,0,polyres)
			plot(c/2)		= bplot

			;----- clean up
			delete(rain_c)
			delete(rain_uc)
			delete(prain)
			delete(data_c)
			delete(data_uc)
			delete(pdata)
			delete(eqrain)
		end do ; case loop

		pStr		= (/"a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z" /)
		nPanels		= 10
		pID			= new(nPanels,"string")
		pID			= pStr(0:nPanels-1)
		resP					= True                  		; modify the panel plot
		resP@gsnPanelBottom						= 0.05			; add space at bottom
		resP@gsnPanelYWhiteSpacePercent 		= 4
		resP@gsnPanelFigureStrings 				= pID      
		resP@gsnPanelFigureStringsFontHeightF	= 0.015
		resP@gsnPanelFigureStringsPerimOn		= True
		resP@amJust								= "TopLeft"
		resP@gsnPanelLabelBar					= True
		resP@lbAutoManage          				= False			; we control label bar
		resP@lbTitleString    					= varUnits2(v)	; title string
		resP@lbTitlePosition  					= "Right"		; title position
		resP@lbTitleFontHeightF					= .012 			; make title smaller
		resP@lbTitleDirection 					= "Across"		; title direction
		resP@lbLabelFontHeightF					= .009
		resP@lbOrientation         				= "Horizontal"	; ncl default is vertical
		resP@pmLabelBarWidthF     				= 0.4			; default is shorter
		resP@pmLabelBarHeightF     				= 0.04			; default is taller
		resP@lbLabelFontHeightF    				= .01			; default is HUGE
		gsn_panel(wks,plot,(/4,1/),resP)						; now draw as one plot
	end do ; variable loop
	
	end do ; lag day

end

