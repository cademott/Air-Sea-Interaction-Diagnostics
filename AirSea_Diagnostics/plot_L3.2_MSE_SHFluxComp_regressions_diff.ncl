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
	pType		= getenv("PTYPE")
	caseName	= getenv("caseName")
	diri		= getenv("FILEDIR")+"/proc/"
	dirp		= getenv("FILEDIR")+"/plots/"
	twStrt		= getenv("YMDSTRT")
	twLast		= getenv("YMDLAST")
	dateStr		= getenv("FILESUFFSTR")

	;------------- seasons
	seasonName	= (/ "Nov-Apr", "May-Oct" /)
	baseVar		= (/ "Vmse",	"Vdmdt",	"Vomegadmdp"/)
	baseName	= (/ "MSE",		"dMSE/dt",	"VADV" /)
	regVar		= (/ "SHFLX", "comptotSH",			"wdSH", 			"tdSH",				"ecSH" /) 

	;----------- read in variable labels and units
	metafile	= "./Resources/variable_labels_units.txt"
	vName		= systemfunc("cut -d , -f1 "+metafile)
	label		= str_left_strip(systemfunc("cut -d , -f2 "+metafile))
	units		= str_left_strip(systemfunc("cut -d , -f3 "+metafile))

	do s = 0,1 						; do for each season
		;------------set up the plot
		wksType = pType
		wksName	= dirp + caseName + ".plot_L3.2_MSE_SHFluxComp_regressions." + twStrt + "-" + twLast + "." + seasonName(s)
		print("--------- making "+wksName)
		wks = gsn_open_wks(wksType,wksName)		; open a ps file
		gsn_define_colormap(wks,"cmp_b2r")
		plot = new(10,graphic)		; 2 columns

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
	
		;------------- plot resources for overlaid significance
		resS						= True
		resS@gsnDraw				= False		; don't draw
		resS@gsnFrame				= False		; don't advance frame
		resS@cnInfoLabelOn			= False		; turn off cn info label
		resS@cnLinesOn				= True		; turn off contour lines
		resS@cnLineColor			= "grey61"		; turn off contour lines
		resS@tiXAxisString			= ""
		if (pType.eq."png") then
			resS@cnLineThicknessF	= 4						; thicker contours
		else
			resS@cnLineThicknessF	= 1.5					; thicker contours
		end if
		resS@cnLineLabelsOn			= False		; no line labels
		resS@cnLevelSelectionMode	= "ExplicitLevels"	; manually specify contour levels
		resS@cnInfoLabelOn			= False					; turn off info label box
		resS@cnLineLabelsOn			= False					; no lables on line
		resS@cnFillOn				= True					; fill contour intervals
		resS@cnMonoFillColor		= True					; default color is fground [black]
		resS@cnMonoFillPattern		= False					; want multiple patterns 
		resS@cnMonoFillScale		= False					; want patterns w/ diff densities 
		resS@cnMonoFillPattern		= False        			; Use multiple fill patterns
		if (pType.eq."png") then
			resS@cnFillDotSizeF	= 0.002
		else
			resS@cnFillDotSizeF	= 0.0
		end if
		resS@cnFillPatterns			= (/ -1, 17, -1, -1 /)	; 3=slant lines; 17 = stippling
		resS@cnFillScales     	 	= (/0.65,0.65/)			; line density
		resS@cnFillColor			= "grey61"
		resS@tiXAxisOn				= False
		resS@tiYAxisOn				= False
		resS@tiMainOn				= False

		Name1						= "Vmse"
		do regV = 0,4					; do for each regressed variable

			Name2			= regVar(regV)
			;------------ read in the data for full SST and smoothed SST regressions
			fili			= caseName + ".make_L3.1_regression_map."+ twStrt + "-" + twLast + "." + Name1 + "." + Name2 + "." + seasonName(s) + ".nc"
			f				= addfile(diri + fili, "r")
			reg_full		= f->regData
			sig_full		= f->statSig
			SE_full			= f->stderrData
		
			if (regV.ge.1) then
				fili		= caseName + ".make_L3.1_regression_map."+ twStrt + "-" + twLast + "." + Name1 + "." + Name2 + "_smSST." + seasonName(s) + ".nc"
			end if
			f				= addfile(diri + fili, "r")
			reg_sm			= f->regData
			sig_sm			= f->statSig
			SE_sm			= f->stderrData
			ess_full		= f->essData

			;------------ define land mask
			if (s.eq.0.and.regV.eq.0) then
				lon		= f->lon
				lat		= f->lat			
				a    	= addfile("$NCARG_ROOT/lib/ncarg/data/cdf/landsea.nc","r")
				lsdata	= a->LSMASK
				lsm		= landsea_mask(lsdata,lat,lon)
			end if

			;------------ compute SE limits; 95% of points fall between +/- 1.96SE for normal distributions
			reg_full_pSE	= reg_full + 1.96 * SE_full 
			reg_full_mSE	= reg_full - 1.96 * SE_full
			reg_sm_pSE		= reg_sm + 1.96 * SE_sm 
			reg_sm_mSE		= reg_sm - 1.96 * SE_sm
			ess_sm			= f->essData

			;------------ assign label and units
			varID					= ind(vName.eq.regVar(regV))
			labelID					= label(varID)
			unitsID					= units(varID)
			mseID					= label(ind(vName.eq."Vmse"))
			dmdtID					= label(ind(vName.eq."Vdmdt"))

			;------------ make nice units, compute difference
			reg_full		= reg_full * 86400. * 100.
			reg_full@long_name = labelID
			reg_full@units	= "% " + mseID + " day~S2~-1"
			reg_full_pSE	= reg_full_pSE * 86400. * 100.
			reg_full_mSE	= reg_full_mSE * 86400. * 100.

			reg_sm			= reg_sm * 86400. * 100.
			reg_sm@units	= "% " + mseID + " day~S2~-1"
			reg_sm_pSE		= reg_sm_pSE * 86400. * 100.
			reg_sm_mSE		= reg_sm_mSE * 86400. * 100.

			reg_diff		= reg_full - reg_sm
			copy_VarMeta(reg_full,reg_diff)
		
			sig_diff		= reg_diff	; quickly define
			sig_diff		= 0.0		; no significance

			;------------ difference of regression coefficient testing
			;print("variable = "+Name2)
			progGen			= ".make_L1.5_stdev_map."
			if (regV.eq.0) then
				sfile			= caseName + ".make_L1.4_mean_stdev_map." + twStrt + "-" + twLast + "." + regVar(regV) + "." + seasonName(s) + ".nc"
			else
				sfile			= caseName + progGen + twStrt + "-" + twLast + "." + regVar(regV) + "." + seasonName(s) + ".nc"
			end if
			ss				= addfile(diri+sfile,"r")
			sName			= regVar(regV)+"_stdev"
			sd_full			= ss->$sName$
			if (regV.ge.1)
				sfile			= caseName + progGen + twStrt + "-" + twLast + "." + regVar(regV) + "_smSST." + seasonName(s) + ".nc"
				ss				= addfile(diri+sfile,"r")
				sName			= regVar(regV)+"_smSST_stdev"
			end if
			sd_sm			= ss->$sName$

			;;======== original (slow; assumes constant nSamples)
			;nSamples		= 5000./70. ; hard-coded, assumes about 3 MJO events per season
			;SEpooled		= sqrt(sd_full^2./nSamples + sd_sm^2./nSamples)
			;dof				= SEpooled^2. / [ (sd_full^2./nSamples)^2./(nSamples-1) + (sd_sm^2./nSamples)^2./(nSamples-1) ]
			;tval_diff		= reg_diff / SEpooled
			;sig_diff		= 1.-student_t(tval_diff,dof)
			
			;======== current (faster; uses equiv_sample_size for nSamples)
			SEpooled		= sqrt(sd_full^2./ess_full + sd_sm^2./ess_sm)
			dof				= SEpooled^2. / [ (sd_full^2./ess_full)^2./(ess_full-1) + (sd_sm^2./ess_sm)^2./(ess_sm-1) ]
			tval_diff		= abs(reg_diff) / SEpooled
			p05				= tval_diff
			p05				= 0.025 ; quickly define p=0.05 for two-sided probability
			tval05			= cdft_t(p05,dof) ; <------ much faster using this approach
			tval05_1d		= ndtooned(tval05)
			tdiff_1d		= ndtooned(tval_diff)
			sig1d			= ndtooned(sig_diff)
			sig				= ind(abs(tval05_1d).lt.tdiff_1d)
			if (any(.not.ismissing(sig))) then
				sig1d(sig) = 1.0
			end if
			delete(sig)
			sig_diff		= onedtond(sig1d,dimsizes(sig_diff))
			
			;======== strict:  only significant where +/- 1.96*SE do not overlap			
			;if (regV.ge.1) then
			;	;======== latest:  use std err of reg. coeff to quickly test significance
			;	reg_diff1d		= ndtooned(reg_diff)
			;	reg_full_pSE1d	= ndtooned(reg_full_pSE)
			;	reg_full_mSE1d	= ndtooned(reg_full_mSE)
			;	reg_sm_pSE1d	= ndtooned(reg_sm_pSE)
			;	reg_sm_mSE1d	= ndtooned(reg_sm_mSE)
			;	sig_diff1d		= ndtooned(sig_diff)
			;
			;	;-------- case where full > sm
			;	pos			= ind(reg_diff1d.gt.0)
			;	sigTrue		= ind(reg_full_mSE1d(pos).gt.reg_sm_pSE1d(pos))
			;	if (any(.not.ismissing(sigTrue))) then
			;		sig_diff1d(pos(sigTrue))	= 1.0
			;	end if
			;	delete(sigTrue)
			;	delete(pos)
			;	;-------- case where full < sm
			;	neg			= ind(reg_diff1d.lt.0)
			;	sigTrue		= ind(reg_full_pSE1d(neg).lt.reg_sm_mSE1d(neg))
			;	if (any(.not.ismissing(sigTrue))) then
			;		sig_diff1d(neg(sigTrue))	= 1.0
			;	end if
			;	delete(sigTrue)
			;	delete(neg)
			;	sig_diff	= onedtond(sig_diff1d,dimsizes(sig_diff))
			;	delete([/sig_diff1d,reg_diff1d,reg_full_pSE1d,reg_full_mSE1d,reg_sm_pSE1d,reg_sm_mSE1d/])
			;	;delete(sig_diff1d)
			;	;delete(reg_diff1d)
			;	;delete(reg_full_pSE1d)
			;end if
			
			copy_VarMeta(sig_full,sig_diff)
			;printMinMax(sig_diff,True)
					
						

			;------------ turn on longitude labels for bottom panels
			if (regV.eq.4) then
				res@tmXBLabelsOn			= True
			end if

			;------------ make plot panels
			res@cnLevels 	= fspan(-2.5,2.5,11)
			resS@cnLevels	= (/ 0,0.95,1.1 /)
			if (all(sig_full.eq.0)) then ; force one pt <> 0 to force stippling overlay 
				sig_full(0,0) = 0.1 
			end if
			plot(regV*2)	= gsn_csm_contour_map_overlay(wks,reg_full,sig_full,res,resS)

			res@cnLevels 	= fspan(-1.,1.,11)
			resS@cnLevels	= (/ 0,0.05,1.1 /)
			reg_diff	= mask(reg_diff,lsm.ge.1,False)
			sig_diff	= mask(sig_diff,lsm.ge.1,False)			
			if (all(sig_diff.eq.0)) then ; force one pt <> 0 to force stippling overlay 
				sig_diff(0,0) = 0.1
			end if
			plot(regV*2+1)	= gsn_csm_contour_map_overlay(wks,reg_diff,sig_diff,res,resS)
			
			nVars	= regV+1 ; this keeps track of how total panels are being plotted

		end do			; variable loop

		;------------- create plot page
		pStr		= (/"a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z" /)
		nPanels		= nVars*2
		pID			= new(nPanels,"string")
		print("nPanels = "+nPanels)
		do i=0,nPanels/2-1
			pID(i*2)	= pStr(i)
			pID(i*2+1)	= pStr(i+nPanels/2)
		end do
		resP					= True                   	; modify the panel plot
		resP@gsnFrame			= False                  	; don't advance panel plot
		resP@gsnPanelLabelBar	= False                  	; add common colorbar
		resP@txString			= caseName+" " + seasonName(s); add common title
		resP@gsnPanelBottom		= 0.05                   	; add space at bottom
		resP@gsnPanelYWhiteSpacePercent = 6
		resP@gsnPanelFigureStrings = pID      ; add letter labels to panels (# letters can be > # panels)
		resP@gsnPanelFigureStringsFontHeightF	= 0.012
		resP@gsnPanelFigureStringsPerimOn		= True
		resP@amJust								= "TopLeft"
		gsn_panel(wks,plot,(/5,2/),resP)               ; now draw as one plot

		;------------- label columns
		txres               = True                     ; text mods desired
		txres@txFontHeightF = 0.013                    ; font smaller. default big
		gsn_text_ndc(wks,"full SST",0.23,0.865,txres) 
		gsn_text_ndc(wks,"difference (full SST - smoothed SST)",0.73,0.865,txres) 
		
		if (wksType.eq."png") then
			frame(wks)
			trimPNG(wksName)
		end if

	end	do		; for each season

end
	





