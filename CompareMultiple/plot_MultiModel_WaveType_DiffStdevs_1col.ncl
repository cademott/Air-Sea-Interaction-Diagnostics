load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"   
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"    
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"    
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/diagnostics_cam.ncl"    
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"

begin

	print("=============== in plot_MultiModel_Means_1col.ncl =================")

	;------------- define season names
	seasonName 	= (/ "Nov-Apr", "May-Oct" /)

	;------------- get global environmental variables
	nCases		= toint(getenv("nCases"))
	dirp		= getenv("dirp")	
	varName		= getenv("varName")	
	PanelStrt	= getenv("panelLabStrt")
	waveType	= getenv("waveType")
	plusOne		= getenv("plusOne")
	print("plusOne = " + plusOne)
	print(typeof(plusOne))
	print("PanelStrt="+PanelStrt)	
	print("nCases = " + nCases)
	print("varName = " + varName)

	;------------- set up plot panels, contours, labels, units
	;plot 		= new(nCases*2,graphic)   	; double the number to utilize left-column only
	plot 		= new(nCases,graphic)   	; double the number to utilize left-column only
	metafile	= "contours_Season_DiffStdev_Maps.txt"
	vName		= systemfunc("cut -d , -f1 "+metafile)
	cnMin		= tofloat(systemfunc("cut -d , -f2 "+metafile)) 
	cnMax		= tofloat(systemfunc("cut -d , -f3 "+metafile)) 
	cnInt		= tofloat(systemfunc("cut -d , -f4 "+metafile)) 
	label		= str_left_strip(systemfunc("cut -d , -f5 "+metafile))
	units		= str_left_strip(systemfunc("cut -d , -f6 "+metafile))
	landmask	= str_left_strip(systemfunc("cut -d , -f7 "+metafile))
	varID		= ind(vName.eq.varName)
	print("cmin = " + cnMin(varID))
	print("cmax = " + cnMax(varID))
	print("cint = " + cnInt(varID))
	;print(label)
	;print(units)
	;print(strlen(label))
		              	
	;------------- plot resources for base plot
	res                     	= True
	res@gsnDraw 				= False			; don't draw
	res@gsnFrame				= False			; don't advance frame
	res@cnLineLabelsOn			= False
	res@cnInfoLabelOn			= False 		; turn off cn info label
	res@cnFillOn				= True			; turn on color
	res@cnLinesOn				= True			; turn off contour lines
	res@cnLineColor				= "grey60"
	res@gsnSpreadColors			= True			; spread out color table
	res@gsnSpreadColorStart		= 2 
	res@gsnSpreadColorEnd		= -3 
	res@tmXBLabelsOn			= False
	res@tmXBLabelFontHeightF	= 0.019         ; change maj lat tm spacing
	res@tmYLLabelFontHeightF	= 0.019         ; change maj lat tm spacing
	res@mpMinLatF				= -30.
	res@mpMaxLatF				=  30.
	res@mpMinLonF 				=  30.
	res@mpMaxLonF				= 240.
	res@mpCenterLonF			= 135. 
	res@cnLevelSelectionMode	= "ManualLevels"   
	res@lbLabelBarOn			= False
	res@gsnContourZeroLineThicknessF	= 0

	do s = 0,1 				; do for each season

		;----------- set up plot file
		wksType = "pdf"
		wksName	= dirp + "MultiModel_" + waveType + "_DiffStDev_1col." + varName + "." + seasonName(s)
		print("plot file = " + wksName)
		wks = gsn_open_wks(wksType,wksName)		; open a ps file
		gsn_define_colormap(wks,"MPL_rainbow")

		do n=0,nCases-1
				
			;------------- get case-specific environmental variables
			MODNAME		= "MODNAME"	+ tostring(n)
			MODDIR		= "MODDIR" + tostring(n)
			MODDATES	= "MODDATES"+ tostring(n)
			caseName	= getenv(MODNAME)
			diri		= getenv(MODDIR)
			dateRange	= getenv(MODDATES)		
			;panelLabel	= getenv(PanelLabel)
			panelLabel	= str_sub_str(caseName,"_minus_"," - ")
			;print("panelLabel = " + panelLabel)
			;print("caseName = " + caseName)
							
			;------------ read in the data
			fili_prefix		= diri + caseName + ".make_L1.10_WaveType_stdev_map."
			if (varName.eq."PW") then
				fili_prefix	= diri + caseName + ".make_2D_SeasonMeanMaps."
			end if
			;fili_prefix		= diri + caseName + ".make_L1.4_mean_stdev_map."
			fili_suffix		= "." + waveType + "_filtered." + seasonName(s) + ".nc"
			fili			= fili_prefix + varName + fili_suffix
			f				= addfile(fili,"r")
			tName			= waveType + "_stdev"
			data			= f->$tName$

			;------------ define land mask
			if (landmask(varID).eq."mask") then
				lon		= f->lon
				lat		= f->lat			
				a    	= addfile("$NCARG_ROOT/lib/ncarg/data/cdf/landsea.nc","r")
				lsdata	= a->LSMASK
				lsm		= landsea_mask(lsdata,lat,lon)
				data	= mask(data,lsm.ge.1,False)
				delete(lat)
				delete(lon)
				delete(lsm)
			end if
		
			;------------ turn on longitude labels for bottom panels
			if (n.eq.nCases-1) then
				res@tmXBLabelsOn			= True
			end if

			;------------ define color table
			if (varName.eq."PRECT") then
				res@cnFillPalette			= "precip_diff_12lev"
				res@cnFillColors			= (/ 2,3,4,5,6,8,8,10,11,12,13,14 /) - 2
			else
				res@cnFillPalette			= "BlueWhiteOrangeRed"
				res@cnFillColors			= tointeger(fspan(20,234,12))
			end if

			;------------ make panel plots
			if (waveType.eq."ER") then
				cnFactor			= 0.2
			else
				cnFactor			= 0.5
			end if
			res@cnMinLevelValF		= cnMin(varID) * cnFactor
			res@cnMaxLevelValF		= cnMax(varID) * cnFactor
			res@cnLevelSpacingF		= cnInt(varID) * cnFactor
			data@long_name			= panelLabel
			data@units				= units(varID)	
			plot(n)	= gsn_csm_contour_map_ce(wks,data,res)

			delete(data)
			
		end do
		
		;------------- create plot page
		pStr		= (/"a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z" /)
;		nPanels		= nCases*2
;		pID			= new(nPanels,"string")
;		print("nPanels = "+nPanels)
;		do i=0,nPanels/2-1
;			pID(i*2)	= pStr(i)
;			pID(i*2+1)	= pStr(i+nPanels/2)
;		end do
		;print(typeof(PanelStrt))
		pID										= pStr(tointeger(PanelStrt)::)
		resP									= True                   	; modify the panel plot
		resP@gsnFrame							= False                  	; don't advance panel plot
		resP@gsnPanelMainString					= "~F33~s ~F21~(" + waveType + " " + label(varID) + "), " + seasonName(s); add common title
		resP@gsnPanelBottom						= 0.05                   	; add space at bottom
		resP@gsnPanelYWhiteSpacePercent 		= 4
		resP@gsnPanelFigureStrings 				= pID      
		resP@gsnPanelFigureStringsFontHeightF	= 0.015
		resP@gsnPanelFigureStringsPerimOn		= True
		resP@amJust								= "TopLeft"
		resP@gsnPanelLabelBar					= True
		resP@lbLabelFontHeightF					= .009
		resP@lbAutoManage          				= False             ; we control label bar
		resP@lbOrientation         				= "Horizontal"      ; ncl default is vertical
		resP@pmLabelBarWidthF     				= 0.4               ; default is shorter
		resP@pmLabelBarHeightF     				= 0.04              ; default is taller
		resP@lbLabelFontHeightF    				= .01               ; default is HUGE
		if (plusOne.eq."True") then
			nPanels	= nCases + 1
		end if
		gsn_panel(wks,plot,(/nPanels,1/),resP)                		; now draw as one plot


		res@tmXBLabelsOn	= False ; turn off longitude labels for next season
		
	end do				; season loop

end