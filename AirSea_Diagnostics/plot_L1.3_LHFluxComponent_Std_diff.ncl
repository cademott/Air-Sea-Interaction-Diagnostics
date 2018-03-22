load "./Resources/contrib_AirSea.ncl"

begin

	print("=============== in plot_L1.3_LHFluxComponent_Std_diff.ncl =================")

	;---------- read in environmental variables
	debug		= getenv("DEBUG")
	if (debug.eq."false") then
		err = NhlGetErrorObjectId()
		setvalues err
			"errLevel" : "Fatal"          ; only report Fatal errors
		end setvalues
	end if
	figcap		= getenv("FIGCAP")
	pType		= getenv("PTYPE")
	twStrt		= getenv("YMDSTRT")
	twLast		= getenv("YMDLAST")
	dateStr		= getenv("FILESUFFSTR")
	diri		= getenv("FILEDIR") + "/proc/"
	dirp		= getenv("FILEDIR") + "/plots/"
	caseName	= getenv("caseName")
	;ctable		= getenv("ctable")

	latSstr		= getenv("latSouth")
	latNstr		= getenv("latNorth")
	latS_globe	= stringtofloat(latSstr)
	latN_globe	= stringtofloat(latNstr)
	;----------- define latitude string
	if (latS_globe.lt.0) then
		southStr	= "S"
	else
		southStr	= "N"
	end if
	if (latN_globe.ge.0) then
		northStr	= "N"
	else
		northStr	= "S"
	end if	
	latbandStr	= abs(latS_globe) + southStr + "-" + abs(latN_globe) + northStr

	;------------- define season names
	seasonName 	= (/ "Nov-Apr", "May-Oct" /)

	;----------- note:  input variables and metadata for plotting
	;					routines use standard naming conventions
	varName		= (/ "LHFLX",	"comptotLH", 	"wdLH", 	"tdLH",	"ecLH",	 "Qair",	"Qsat",	 "delQ" /)

	;----------- read in variable labels and units
	metafile	= "./Resources/variable_labels_units.txt"
	vName		= systemfunc("cut -d , -f1 "+metafile)
	label		= str_left_strip(systemfunc("cut -d , -f2 "+metafile))
	units		= str_left_strip(systemfunc("cut -d , -f3 "+metafile))
	
	;----------- assign contour intervals
	cnMinStdev	= (/  0.,		 0.,			 0.,		  0.,	  0.,	  0.,		 0.,	  0.  /)
	cnMaxStdev	= (/ 50.,		50.,		 	50.,		 50.,	 50.,	  1.,		 1.,	  1.  /)
	cnSpcStdev	= (/  5.,	 	 5.,		 	 5.,		  5.,	  5.,	  0.1,		 0.1,	  0.1 /)
	cnMinDiff	= (/ -5.,	    -5.,		    -5.,		 -5.,	 -5.,	 -0.5,		-0.5,	 -0.5 /)
	cnMaxDiff	= -1. * cnMinDiff
	cnSpcDiff	= (/ 1.,		 1.,			 1.,		  1.,	  1.,	  0.1,		 0.1,	  0.1 /)
	progGen		= (/ 	".make_L1.4_mean_stdev_map.", \
						".make_L1.5_stdev_map.", \	
						".make_L1.5_stdev_map.", \	
						".make_L1.5_stdev_map.", \	
						".make_L1.5_stdev_map.", \	
						".make_L1.4_mean_stdev_map.", \	
						".make_L1.4_mean_stdev_map.", \	
						".make_L1.4_mean_stdev_map." /)

	;------------- plot resources for base plot
	res                     	= True
	res@gsnDraw 				= False			; don't draw
	res@gsnFrame				= False			; don't advance frame
	res@cnInfoLabelOn			= False 		; turn off cn info label
	res@cnFillOn				= True			; turn on color
	res@cnLinesOn				= True			; turn off contour lines
	res@cnSpanFillPalette		= False
	res@tmXBLabelsOn			= False
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
	res@cnFillColors			= ispan(2,124,11)

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
	do s = 0,1 					; do for each SST type (full or smoothed)
		;----------- set up plot file
		wksType = pType
		wksName	= dirp + caseName + ".plot_L1.3_LHFluxComponent_Std_diff."+ twStrt + "-" + twLast +"."+seasonName(s)
		wks = gsn_open_wks(wksType,wksName)		; open a ps file
		plot = new(16,graphic)                 	

		do v = 0,7			; do for each variable
		
			;------------ read in the data
			tName			= varName(v)
			fili			= diri + caseName + progGen(v) + twStrt + "-" + twLast + "." + tName + "." + seasonName(s) + ".nc"
			f				= addfile(fili,"r")
			tName			= tName + "_stdev"
			data_full		= f->$tName$
			if (v.eq.0.or.v.eq.5) then
				tName		= varName(v)
			else
				tName		= varName(v) + "_smSST"
			end if
			fili			= diri + caseName + progGen(v) + twStrt + "-" + twLast + "." + tName + "." + seasonName(s) + ".nc"
			f				= addfile(fili,"r")
			tName			= tName + "_stdev"
			data_sm			= f->$tName$

			;------------ define land mask
			if (s.eq.0.and.v.eq.0) then		; no _smSST for LHFLX, Qair
				lon		= f->lon
				lat		= f->lat			
				a    	= addfile("$NCARG_ROOT/lib/ncarg/data/cdf/landsea.nc","r")
				lsdata	= a->LSMASK
				lsm		= landsea_mask(lsdata,lat,lon)
			end if

			;------------ mask land
			data_full	= mask(smth9_Wrap(smth9_Wrap(data_full,.5,.25,True),.5,.25,True),lsm.ge.1,False)
			data_sm		= mask(smth9_Wrap(smth9_Wrap(data_sm,.5,.25,True),.5,.25,True),lsm.ge.1,False)
			
			;------------ force Q units to g/kg
			if (v.ge.5) then
				if (max(data_full).lt.0.1) then
					data_full		= data_full * 1000.
					data_full@units	= "g kg~S2~-1"
					data_sm			= data_sm * 1000.
					data_sm@units	= "g kg~S2~-1"
				end if
			end if
					
			;;------------- strip "Anomalies:  " prefix from panel label
			;------------- use standardized naming convention
			if (substring(data_full@long_name,0,min( (/10,strlen(data_full@long_name)-1 /) )).eq."Anomalies: ") then
				data_full@long_name	= varName(v)
				data_sm@long_name	= varName(v)
			end if

			;------------ turn on longitude labels for bottom panels
			if (v.eq.7) then
				res@tmXBLabelsOn			= True
				resD@tmXBLabelsOn			= True
			end if

			;------------ assign label and units
			varID					= ind(vName.eq.varName(v))
			labelID					= label(varID)
			unitsID					= units(varID)

			;------------ make panel plots
			res@cnMinLevelValF		= cnMinStdev(v)
			res@cnMaxLevelValF		= cnMaxStdev(v)
			res@cnLevelSpacingF		= cnSpcStdev(v) 
			data_full@long_name		= labelID
			data_full@units			= unitsID
			plot1					= gsn_csm_contour_map_ce(wks,data_full,res)

			;------------ reset color table anomaly fields
			resD@cnMinLevelValF		= cnMinDiff(v)
			resD@cnMaxLevelValF		= cnMaxDiff(v)
			resD@cnLevelSpacingF	= cnSpcDiff(v) 
			datap					= data_full-data_sm
			copy_VarMeta(data_full,datap)
			datap@long_name			= labelID
			datap@units				= unitsID
			plot2					= gsn_csm_contour_map_ce(wks,datap,resD)
			delete(datap)
		
			plot(v*2)	= plot1
			plot(v*2+1)	= plot2
			
			delete(plot1)
			delete(plot2)
			delete(res@cnMinLevelValF)
			delete(res@cnMaxLevelValF)
			delete(res@cnLevelSpacingF)

			nVars	= v+1 ; this keeps track of how total panels are being plotted

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
		;print(pID)
		resP					= True                   	; modify the panel plot
		resP@gsnFrame			= False                  	; don't advance panel plot
		resP@gsnPanelLabelBar	= False                  	; add common colorbar
		resP@txString			= caseName+" " + seasonName(s); add common title
		resP@gsnPanelBottom		= 0.05                   	; add space at bottom
		resP@gsnPanelYWhiteSpacePercent = 5
		resP@gsnPanelFigureStrings = pID      ; add letter labels to panels (# letters can be > # panels)
		resP@gsnPanelFigureStringsFontHeightF	= 0.012
		resP@gsnPanelFigureStringsPerimOn		= True
		resP@amJust								= "TopLeft"
		gsn_panel(wks,plot,(/8,2/),resP)                	; now draw as one plot

		;------------- label columns
		txres               	= True                     	; text mods desired
		txres@txFontHeightF		= 0.013                    	; font smaller. default big
		gsn_text_ndc(wks,"~F33~s ~F21~(full SST)",0.28,0.943,txres) 
		gsn_text_ndc(wks,"~F33~s ~F21~difference (full SST - smoothed SST)",0.68,0.943,txres) 

		if (wksType.eq."png") then
			frame(wks)
			trimPNG(wksName)
		end if

		res@tmXBLabelsOn	= False ; turn off longitude labels for next season
		resD@tmXBLabelsOn	= False ; turn off longitude labels for next season	
	
	end do 			; season loop

end
	





