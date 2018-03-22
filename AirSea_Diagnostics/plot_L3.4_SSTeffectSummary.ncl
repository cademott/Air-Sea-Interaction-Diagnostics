load "./Resources/contrib_AirSea.ncl"
  
begin
                           
	print("============= in plot_L3.4_SSTeffectSummary.ncl =============")   

	;----------- Retrieve required environment variables
	debug		= getenv("DEBUG")
	if (debug.eq."false") then
		err = NhlGetErrorObjectId()
		setvalues err
			"errLevel" : "Fatal"          ; only report Fatal errors
		end setvalues
	end if
	figcap		= getenv("FIGCAP")
	pType		= getenv("PTYPE")
	caseName	= getenv("caseName")
	diri		= getenv("FILEDIR")+"/proc/"
	dirp		= getenv("FILEDIR")+"/plots/"
	twStrt		= getenv("YMDSTRT")
	twLast		= getenv("YMDLAST")
	dateStr		= getenv("FILESUFFSTR")

	;------------- seasons
	seasonName	= (/ "Nov-Apr", "May-Oct" /)

	;----------- read in variable labels and units
	metafile	= "./Resources/variable_labels_units.txt"
	vName		= systemfunc("cut -d , -f1 "+metafile)
	label		= str_left_strip(systemfunc("cut -d , -f2 "+metafile))
	units		= str_left_strip(systemfunc("cut -d , -f3 "+metafile))
	mseID		= label(ind(vName.eq."Vmse"))
	dmdtID		= label(ind(vName.eq."Vdmdt"))
	
	do s = 0,1 						; do for each season
		;------------set up the plot
		wksType = pType
		wksName	= dirp + caseName + ".plot_L3.4_SSTeffectSummary." + twStrt + "-" + twLast + "." + seasonName(s)
		print("--------- making "+wksName)
		wks = gsn_open_wks(wksType,wksName)		; open a ps file
		gsn_define_colormap(wks,"cmp_b2r")
		plot = new(10,graphic)                 	; create a plot array

		;------------ create output file
		fMSE	= diri + caseName + ".plot_L3.4_SSTeffectSummary.MSE_SST_effect." + twStrt + "-" + twLast + "." + seasonName(s) + ".nc"
		system("rm -f " + fMSE)
		fdMSEdt	= diri + caseName + ".plot_L3.4_SSTeffectSummary.dMSEdt_SST_effect." + twStrt + "-" + twLast + "." + seasonName(s) + ".nc"
		system("rm -f " + fdMSEdt)

		res							= True
		res@gsnDraw					= False			; don't draw
		res@gsnFrame				= False			; don't advance frame
		res@cnInfoLabelOn			= False 		; turn off cn info label
		res@cnLinesOn				= False			; turn off contour lines
		res@cnFillOn				= True			; turn on color
		res@gsnSpreadColors			= True			; spread out color table
		res@tmXBLabelsOn			= False
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
	
		;============ MSE ===============
			Name1			= "Vmse"	

			;------------ LH flux -----------
			Name2			= "comptotLH"
			;------------ read in the data for full SST and smoothed SST regressions
			fili			= caseName + ".make_L3.1_regression_map." + twStrt + "-" + twLast + "." + Name1 + "." + Name2 + "." + seasonName(s) + ".nc"
			f				= addfile(diri + fili, "r")
			reg_full		= f->regData
			fili			= caseName + ".make_L3.1_regression_map." + twStrt + "-" + twLast + "." + Name1 + "." + Name2 + "_smSST." + seasonName(s) + ".nc"
			f				= addfile(diri + fili, "r")
			reg_sm			= f->regData

			;---------------- first time through, define land maks
			lon		= f->lon
			lat		= f->lat			
			a    	= addfile("$NCARG_ROOT/lib/ncarg/data/cdf/landsea.nc","r")
			lsdata	= a->LSMASK
			lsm		= landsea_mask(lsdata,lat,lon)

			;------------ make nice units, compute difference
			reg_full		= reg_full * 86400. * 100.
			reg_full@units	= "% " + mseID + " day~S2~-1"
			reg_sm			= reg_sm * 86400. * 100.
			mse_lh_diff		= reg_full - reg_sm
			copy_VarMeta(reg_full,mse_lh_diff)
			mse_lh_diff@long_name	= "LH SST effect"
			mse_lh_diff		= mask(mse_lh_diff,lsm.ge.1,False)

			;------------ SH flux -----------
			Name2			= "comptotSH"
			;------------ read in the data for full SST and smoothed SST regressions
			fili			= caseName + ".make_L3.1_regression_map." + twStrt + "-" + twLast + "." + Name1 + "." + Name2 + "." + seasonName(s) + ".nc"
			f				= addfile(diri + fili, "r")
			reg_full		= f->regData
			fili			= caseName + ".make_L3.1_regression_map." + twStrt + "-" + twLast + "." + Name1 + "." + Name2 + "_smSST." + seasonName(s) + ".nc"
			f				= addfile(diri + fili, "r")
			reg_sm			= f->regData
			;------------ make nice units, compute difference
			reg_full		= reg_full * 86400. * 100.
			reg_full@units	= "% " + mseID + " day~S2~-1"
			reg_sm			= reg_sm * 86400. * 100.
			mse_sh_diff		= reg_full - reg_sm
			copy_VarMeta(reg_full,mse_sh_diff)
			mse_sh_diff@long_name	= "SH SST effect"
			mse_sh_diff		= mask(mse_sh_diff,lsm.ge.1,False)

			;------------ MSE LH+SH SST effect
			mse_tot_diff	= mse_lh_diff + mse_sh_diff
			copy_VarMeta(mse_lh_diff,mse_tot_diff)
			mse_tot_diff@long_name	= "LH+SH SST effect"
			mse_tot_diff		= mask(mse_tot_diff,lsm.ge.1,False)
		
		;============ dMSE/dt ===============
			Name1			= "Vdmdt"	

			;------------ LH flux -----------
			Name2			= "comptotLH"
			;------------ read in the data for full SST and smoothed SST regressions
			fili			= caseName + ".make_L3.1_regression_map." + twStrt + "-" + twLast + "." + Name1 + "." + Name2 + "." + seasonName(s) + ".nc"
			f				= addfile(diri + fili, "r")
			reg_full		= f->regData
			fili			= caseName + ".make_L3.1_regression_map." + twStrt + "-" + twLast + "." + Name1 + "." + Name2 + "_smSST." + seasonName(s) + ".nc"
			f				= addfile(diri + fili, "r")
			reg_sm			= f->regData
			;------------ make nice units, compute difference
			reg_full		= reg_full * 100.
			reg_full@units	= "% " + dmdtID
			reg_sm			= reg_sm * 100.
			dmdt_lh_diff	= reg_full - reg_sm
			copy_VarMeta(reg_full,dmdt_lh_diff)
			dmdt_lh_diff@long_name	= "LH SST effect"
			dmdt_lh_diff		= mask(dmdt_lh_diff,lsm.ge.1,False)

			;------------ SH flux -----------
			Name2			= "comptotSH"
			;------------ read in the data for full SST and smoothed SST regressions
			fili			= caseName + ".make_L3.1_regression_map." + twStrt + "-" + twLast + "." + Name1 + "." + Name2 + "." + seasonName(s) + ".nc"
			f				= addfile(diri + fili, "r")
			reg_full		= f->regData
			fili			= caseName + ".make_L3.1_regression_map." + twStrt + "-" + twLast + "." + Name1 + "." + Name2 + "_smSST." + seasonName(s) + ".nc"
			f				= addfile(diri + fili, "r")
			reg_sm			= f->regData
			;------------ make nice units, compute difference
			reg_full		= reg_full * 100.
			reg_full@units	= "% " + dmdtID
			reg_sm			= reg_sm * 100.
			dmdt_sh_diff	= reg_full - reg_sm
			copy_VarMeta(reg_full,dmdt_sh_diff)
			dmdt_sh_diff@long_name	= "SH SST effect"
			dmdt_sh_diff		= mask(dmdt_sh_diff,lsm.ge.1,False)

			;------------ dMSE/dt LH+SH SST effect
			dmdt_tot_diff	= dmdt_lh_diff + dmdt_sh_diff
			copy_VarMeta(dmdt_sh_diff,dmdt_tot_diff)
			dmdt_tot_diff@long_name	= "LH+SH SST effect"
			dmdt_tot_diff		= mask(dmdt_tot_diff,lsm.ge.1,False)

			;------------ write SST effect to output file
			fo						= addfile(fMSE,"c")
			fo->MSE_SST_effect		= mse_tot_diff
			fo						= addfile(fdMSEdt,"c")
			fo->dMSEdt_SST_effect	= dmdt_tot_diff

		;------------ make plot panels
		res@cnLevels = fspan(-2.5,2.5,11)
		plot(0)	= gsn_csm_contour_map_ce(wks,mse_lh_diff,res)
		plot(2)	= gsn_csm_contour_map_ce(wks,mse_sh_diff,res)
		res@tmXBLabelsOn			= True
		plot(4)	= gsn_csm_contour_map_ce(wks,mse_tot_diff,res)
		res@tmXBLabelsOn			= False

		res@cnLevels 	= fspan(-10,10,11)
		plot(1)	= gsn_csm_contour_map_ce(wks,dmdt_lh_diff,res)
		plot(3)	= gsn_csm_contour_map_ce(wks,dmdt_sh_diff,res)
		res@tmXBLabelsOn			= True
		plot(5)	= gsn_csm_contour_map_ce(wks,dmdt_tot_diff,res)
			
	
		;------------- create plot page
		nVars		= 3
		pStr		= (/"a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z" /)
		nPanels		= nVars*2
		pID			= new(nPanels,"string")
		;print("nPanels = "+nPanels)
		do i=0,nPanels/2-1
			pID(i*2)	= pStr(i)
			pID(i*2+1)	= pStr(i+nPanels/2)
		end do
		resP                  = True                   ; modify the panel plot
		resP@gsnFrame         = False                  ; don't advance panel plot
		resP@gsnPanelLabelBar = False                  ; add common colorbar
		resP@txString         = caseName+" "+seasonName(s)	       ; add common title
		resP@gsnPanelBottom   = 0.05                   ; add space at bottom
		resP@gsnPanelYWhiteSpacePercent = 4
		resP@gsnPanelFigureStrings = pID      ; add letter labels to panels (# letters can be > # panels)
		resP@gsnPanelFigureStringsFontHeightF	= 0.012
		resP@gsnPanelFigureStringsPerimOn		= True
		resP@amJust								= "TopLeft"
		gsn_panel(wks,plot,(/5,2/),resP)               ; now draw as one plot

		;------------- label columns
		txres               = True                     ; text mods desired
		txres@txFontHeightF = 0.012                    ; font smaller. default big
		gsn_text_ndc(wks,"SST effect on " + mseID,0.23,0.85,txres) 
		gsn_text_ndc(wks,"SST effect on " + dmdtID,0.73,0.85,txres) 

		if (figcap.eq."true") then
			gsn_text_ndc(wks,"[positive (negative) values support (oppose) positive MSE, dMSE/dt]",0.5,0.375,txres) 
		end if
		
		if (wksType.eq."png") then
			frame(wks)
			trimPNG(wksName)
		end if

	end	do		; for each season

end
	





