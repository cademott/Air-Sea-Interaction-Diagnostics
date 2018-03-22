load "./Resources/contrib_AirSea.ncl"
;load "contrib_JJB.ncl"
  
begin
                           
	print("============= in plot_L3.3_QnetdSSTdt_regressionMaps.ncl =============")   

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

	;; one-time use code for overlaying deBoyer Montegut MDL climatology
	;;------------ mean mixed layer depth
	;dirm		= "/Users/demott/disk2/Data/MLD/"
	;film		= "mld_DReqDTm02_c1m_reg2.0.nc"
	;f			= addfile(dirm+film,"r")
	;mld			= f->mld
	;n2aind		= (/ 0, 1, 2, 3, 10, 11 /)
	;m2oind		= (/ 4, 5, 6, 7, 8, 9 /)
	;mld_season	= mld(0:1,:,:)		; quickly define mean array
	;mld_season(0,:,:)	= dim_avg_n_Wrap(mld(n2aind,:,:),0)
	;mld_season(1,:,:)	= dim_avg_n_Wrap(mld(m2oind,:,:),0)
	;mld1d		= ndtooned(mld_season)
	;land		= ind(mld1d.eq.1E09)
	;mld1d(land)	= mld@missing_value
	;mld_season	= onedtond(mld1d,dimsizes(mld_season))
	;mld_season@long_name=" "

	;------------- define seasons, variable names
	seasonName	= (/ "Nov-Apr", "May-Oct" /)

	do s = 0,1 						; do for each season

		;------------set up the plot
		wksType = pType
		wksName	= dirp + caseName + ".plot_L3.3_Qnet_dSSTdt_regressionMap." + twStrt + "-" + twLast + "." + seasonName(s)
		baseName	= wksName
		wks = gsn_open_wks(wksType,wksName)		; open a ps file
		gsn_define_colormap(wks,"cmp_b2r")
		plot = new(1,graphic)                 	; create a plot array

		res							= True
		res@cnInfoLabelOn      		= False 		; turn off cn info label
		res@cnLinesOn       		= False			; turn off contour lines
		res@cnFillOn            	= True			; turn on color
		res@gsnSpreadColors     	= True			; spread out color table
		res@gsnSpreadColorStart 	= 2 
		res@gsnSpreadColorEnd   	= -3 
		res@lbOrientation			= "Vertical"	; vertical label bar
		res@tmXBLabelFontHeightF	= 0.017			; change maj lat tm spacing
		res@tmYLLabelFontHeightF	= 0.017			; change maj lat tm spacing
		res@mpMinLatF				= -30.
		res@mpMaxLatF				=  30.
		res@mpMinLonF 				=  30.
		res@mpMaxLonF				= 240.
		res@mpCenterLonF			= 135. 
		res@cnLevelSelectionMode =  "ExplicitLevels"   
		res@cnLevels 				= fspan(-0.1,0.1,11)
	
		;; resources for overlaying MLD (currently not operational)
		;resM						= True
		;resM@cnInfoLabelOn			= False
		;resM@cnLinesOn				= True
		;resM@cnFillOn				= False
		;resM@cnLevelSelectionMode	= "ExplicitLevels"   
		;resM@cnLevels 				= fspan(15,115,11)
		;resM@cnLineLabelBackgroundColor = "white"
		;resM@cnLineLabelDensityF		= 1.9
		;resM@cnLineLabelFontHeightF		= 0.007
		;resM@cnLineLabelInterval		= 1
		;resM@cnMonoLevelFlag			= False


		Name1		= "Qnet"
		Name2		= "dSSTdt"
		fili		= caseName + ".make_L3.1_regression_map."+ twStrt + "-" + twLast + "." + Name1 + "." + Name2 + "." + seasonName(s) + ".nc"
		f			= addfile(diri + fili, "r")
		reg			= f->regData
		corr		= f->corrData
		
		;------------ mask land
		if (s.eq.0) then
			lon		= f->lon
			lat		= f->lat			
			a    	= addfile("$NCARG_ROOT/lib/ncarg/data/cdf/landsea.nc","r")
			lsdata	= a->LSMASK
			lsm		= landsea_mask(lsdata,lat,lon)
		end if
		reg			= mask(reg,lsm.ge.1,False)
		;printVarSummary(reg)

		;--------------- make friendly units
		reg					= reg * 100. 		; convert to [K/day]/[100 W/m**2]
		reg@units			= "[K day~S~-1~N~] / [100 W m~S~-2~N~]"
		;reg@long_name		= "dSST/dt, mean MLD"
		reg@long_name		= "dSST/dt"
	
		;------------- create plot page
		resP					= True                   ; modify the panel plot
		resP@gsnFrame			= False                  ; don't advance panel plot

		;------------- create plot page
		txres               	= True                     ; text mods desired
		txres@txFontHeightF 	= 0.03                    ; font smaller. default big
		;res@txString			= caseName+" "+seasonName(s)	       ; add common title
		title					= caseName+" "+seasonName(s)
		gsn_text_ndc(wks,title,0.47,0.71,txres)
		plot(0)					= gsn_csm_contour_map(wks,reg,res)

		; command for overlaying MLD climatology (currently not operational)
		;plot					= gsn_csm_contour_map_overlay(wks,reg,smth9_Wrap(mld_season(s,:,:),0.5,0.05,True),res,resM)

		gsn_panel(wks,plot,(/1,1/),resP)               ; now draw as one plot
		;print("baseName = " + baseName)
		if (wksType.eq."png") then
			frame(wks)
			; see http://www.ncl.ucar.edu/FAQ/#o_formats_006 (search for ".000001")
			system("rm " + baseName + ".000002.png")
			system("mv " + baseName + ".000001.png " + baseName + ".png")
			trimPNG(wksName)
		end if
		
		delete(plot)

	end	do		; for each season

end
	





