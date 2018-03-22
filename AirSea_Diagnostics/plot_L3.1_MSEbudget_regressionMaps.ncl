load "./Resources/contrib_AirSea.ncl"
;load "contrib_JJB.ncl"
  
begin
                           
	print("============= in plot_L3.1_MSEbudget_regressionMaps.ncl =============")   

	;-------------  Retrieve required environment variables
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
	lhName		= getenv("LHVARNAME")
	shName		= getenv("SHVARNAME")

	;------------- define seasons, variable names
	seasonName	= (/ "Nov-Apr", "May-Oct" /)
	baseVar		= (/ "Vmse", 	"Vdmdt" /)
	baseName	= (/ "MSE", 	"dMSE/dt" /)
	regVar		= (/ "Vlw", 	"Vomegadmdp", 	"Vm_hadv", 	"Vudmdx", 		"Vvdmdy", 		"LHFLX", 	"SHFLX", "Vsw"/)

	;----------- read in variable labels and units
	metafile	= "./Resources/variable_labels_units.txt"
	vName		= systemfunc("cut -d , -f1 "+metafile)
	label		= str_left_strip(systemfunc("cut -d , -f2 "+metafile))
	units		= str_left_strip(systemfunc("cut -d , -f3 "+metafile))
	

	do s = 0,1 						; do for each season

		;------------set up the plot
		wksType = pType
		wksName	= dirp + caseName + ".plot_L3.1_MSEbudget_regressionMap." + twStrt + "-" + twLast + "." + seasonName(s)
		wks = gsn_open_wks(wksType,wksName)		; open a ps file
		gsn_define_colormap(wks,"cmp_b2r")
		plot = new(16,graphic)                 	; create a plot array

		res							= True
		res@gsnDraw            		= False					; don't draw
		res@gsnFrame           		= False					; don't advance frame
		res@cnInfoLabelOn      		= False 				; turn off cn info label
		res@cnLinesOn       		= False					; turn off contour lines
		res@cnFillOn            	= True					; turn on color
		res@gsnSpreadColors     	= True					; spread out color table
		res@tmXBLabelsOn			= False
		res@gsnSpreadColorStart 	= 2 
		res@gsnSpreadColorEnd   	= -3 
		res@lbOrientation			= "Vertical"			; vertical label bar
		res@tmXBLabelFontHeightF	= 0.017					
		res@tmYLLabelFontHeightF	= 0.017					
		res@gsnPaperMargin			= 0.1
		res@mpMinLatF				= -30.
		res@mpMaxLatF				=  30.
		res@mpMinLonF 				=  30.
		res@mpMaxLonF				= 240.
		res@mpCenterLonF			= 135. 
		res@cnLevelSelectionMode =  "ExplicitLevels"   
						
		;------------- plot resources for overlaid significance
		resS						= True
		resS@gsnDraw				= False					; don't draw
		resS@gsnFrame				= False					; don't advance frame
		resS@cnInfoLabelOn			= False					; turn off cn info label
		resS@cnLinesOn				= True					; turn off contour lines
		resS@cnLineColor			= "grey61"				; turn off contour lines
		resS@tiXAxisString			= ""
		if (pType.eq."png") then
			resS@cnLineThicknessF	= 4						; thicker contours
		else
			resS@cnLineThicknessF	= 1.5					; thicker contours
		end if
		resS@cnLineLabelsOn			= False					; no line labels
		resS@cnLevelSelectionMode	= "ExplicitLevels"		; manually specify contour levels
		resS@cnLevels				= (/ 0,0.95,1.1 /)
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
		resS@cnFillPatterns			= (/ -1, 17, -1, -1 /)	; 3=slant lines, 17=stippling
		resS@cnFillScales     	 	= (/0.65,0.65/)			; line density
		resS@cnFillColor			= "grey61"
		resS@tiXAxisOn				= False
		resS@tiYAxisOn				= False
		resS@tiMainOn				= False
	
		do regV = 0,7					; do for each regressed variable
			do baseV = 0,1				; do for MSE and dMSE/dt
				Name1		= baseVar(baseV)
				Name2		= regVar(regV)
				fili		= caseName + ".make_L3.1_regression_map."+ twStrt + "-" + twLast + "." + Name1 + "." + Name2 + "." + seasonName(s) + ".nc"
				f			= addfile(diri + fili, "r")
				reg			= f->regData
				sig			= f->statSig
				
				;------------ turn on longitude labels for bottom panels
				if (regV.eq.7) then
					res@tmXBLabelsOn			= True
				end if

				;------------ assign label and units
				varID					= ind(vName.eq.regVar(regV))
				labelID					= label(varID)
				unitsID					= units(varID)
				mseID					= label(ind(vName.eq."Vmse"))
				dmdtID					= label(ind(vName.eq."Vdmdt"))

				;--------------- make friendly units
				if (baseVar(baseV).eq."Vmse") then		; adjust units
					;----------- MSE regressions
					reg				= reg * 100. * 86400.	; convert to % MSE per day
					reg@units		= "% " + mseID + " day~S2~-1"
					reg@long_name	=labelID
					res@cnLevels 	= fspan(-25.,25.,11)
					plot(regV*2 + baseV)=gsn_csm_contour_map_overlay(wks,reg,sig,res,resS)
				else
					;----------- dMSE/dt regressions
					reg			= reg * 100.			; convert to % dMSE/dt
					reg@units	= "% " + dmdtID
					reg@long_name=labelID
					if (regVar(regV).eq."Vm_hadv".or.regVar(regV).eq."Vudmdx".or.regVar(regV).eq."Vvdmdy") then
						res@cnLevels = fspan(-100.,100.,11)
					else
						res@cnLevels = fspan(-50.,50.,11)
					end if
					plot(regV*2 + baseV)= gsn_csm_contour_map_overlay(wks,reg,sig,res,resS)
				end if
			end do		; base variable
			
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
		gsn_panel(wks,plot,(/8,2/),resP)               ; now draw as one plot

		;------------- label columns
		txres               = True                     ; text mods desired
		txres@txFontHeightF = 0.012                    ; font smaller. default big
		gsn_text_ndc(wks,"regression onto " + mseID,0.28,0.944,txres) 
		gsn_text_ndc(wks,"regression onto " + dmdtID,0.69,0.944,txres) 

		if (figcap.eq."true") then
			gsn_text_ndc(wks,"[positive (negative) values support (oppose) positive MSE, dMSE/dt]",0.5,0.03,txres) 
		end if
		
		if (wksType.eq."png") then
			frame(wks)
			trimPNG(wksName)
		end if

	end	do		; for each season

end
	





