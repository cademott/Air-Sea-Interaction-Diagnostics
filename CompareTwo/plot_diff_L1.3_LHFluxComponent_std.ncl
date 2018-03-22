load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"   
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"    
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"    
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/diagnostics_cam.ncl"    
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"
load "./Resources/contrib_AirSea.ncl"

begin

	print("=============== in plot_diff_L1.3_LHFluxComponent_std.ncl =================")
	
	
	progGenU850		= ".make_L1.3a_mean_u850."
	progGenVar	 	= ".make_L1.5_stdev_map."

	;------------- set dynamic variable names
	debug			= getenv("DEBUG")
	if (debug.eq."false") then
		err = NhlGetErrorObjectId()
		setvalues err
			"errLevel" : "Fatal"          ; only report Fatal errors
		end setvalues
	end if
	figcap			= getenv("FIGCAP")
	CTRLNAME		= getenv("CTRLCASE")
	CTRLDIR			= getenv("CTRLDIR")
	EXPNAME			= getenv("EXPCASE")
	EXPDIR			= getenv("EXPDIR")
	dirp			= getenv("PLOTDIR")
	pType			= getenv("PTYPE")
	u850_overlay	= getenv("u850_overlay")	
	diri			= EXPDIR + "proc/" + EXPNAME + "_minus_" + CTRLNAME + "/" 
	print("dirp = " + dirp)
	
	
	;------------- define season names
	seasonName 	= (/ "Nov-Apr", "May-Oct" /)

	;----------- note:  input variables and metadata for plotting
		;					routines use standard naming conventions
	varName		= (/ "comptotLH", 	"wdLH", "tdLH",	"ecLH" /)
	
	;----------- read in variable labels and units
	metafile	= "./Resources/variable_labels_units.txt"
	vName_label	= systemfunc("cut -d , -f1 "+metafile)
	label		= str_left_strip(systemfunc("cut -d , -f2 "+metafile))
	units		= str_left_strip(systemfunc("cut -d , -f3 "+metafile))

	;----------- read in the contour intervals for stdev fields
	metafile			= "./CompareMultiple/contours_Season_DiffStDev_Maps.txt"
	vName_ciStDev		= systemfunc("cut -d , -f1 "+metafile)
	cnMin_ciStDev		= tofloat(systemfunc("cut -d , -f2 "+metafile)) 
	cnMax_ciStDev		= tofloat(systemfunc("cut -d , -f3 "+metafile)) 
	cnInt_ciStDev		= tofloat(systemfunc("cut -d , -f4 "+metafile)) 
	
	
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
	res@cnFillPalette			= "BlueWhiteOrangeRed"
	res@cnFillColors			= tointeger(fspan(20,234,12))
	res@gsnContourZeroLineThicknessF	= 0


	do s = 0,1 					; do for each SST type (full or smoothed)
	;----------- set up plot file -- CTRL MINUS EXPERIMENT
		wksType = pType
		wksName= dirp + EXPNAME + "_minus_"+ CTRLNAME + ".plot_diff_L1.3_LHFluxComponent_std." + seasonName(s)
		
		wks = gsn_open_wks(wksType,wksName)		; open a ps file
		plot = new(10,graphic)       
		
		do v = 0,3			; do for each variable
		
			;-------------read in the data -- created with CDO
			tName			= varName(v)
			fili_prefix 	= diri + EXPNAME + "_minus_" + CTRLNAME + progGenVar
			fili_suffix		= "." + seasonName(s) + ".nc"
			fili			= fili_prefix + varName(v) + fili_suffix
			f				= addfile(fili,"r")
			tName			= tName + "_stdev"
			data_full		= f->$tName$
			
			;------------ define land mask
			if (s.eq.0.and.v.eq.0) then		; no _smSST for LHFLX, Qair
				lon		= f->lon
				lat		= f->lat			
				a    	= addfile("$NCARG_ROOT/lib/ncarg/data/cdf/landsea.nc","r")
				lsdata	= a->LSMASK
				lsm		= landsea_mask(lsdata,lat,lon)
			end if

			;------------ mask land
			data_full	= mask(smth9_Wrap(smth9_Wrap(data_full,.5,-.25,True),.5,.25,True),lsm.ge.1,False)
			
			;------------ force Q units to g/kg
			;if (v.ge.5) then
			;	if (max(data_full).lt.0.1) then
			;		data_full		= data_full * 1000.
			;	end if
			;end if
					
			;------------ turn on longitude labels for bottom panels
			if (v.eq.3) then
				res@tmXBLabelsOn			= True
				;resD@tmXBLabelsOn			= True
			end if

			;------------ make panel plots
			res@cnMinLevelValF		= cnMin_ciStDev(ind(vName_ciStDev.eq.varName(v)))
			res@cnMaxLevelValF		= cnMax_ciStDev(ind(vName_ciStDev.eq.varName(v)))
			res@cnLevelSpacingF	= cnInt_ciStDev(ind(vName_ciStDev.eq.varName(v))) 
			data_full@long_name	= label(ind(vName_label.eq.varName(v)))
			data_full@units		= units(ind(vName_label.eq.varName(v)))
			plot1					= gsn_csm_contour_map_ce(wks,data_full,res)
		
			plot(v)	= plot1
			
			delete(plot1)
			delete(res@cnMinLevelValF)
			delete(res@cnMaxLevelValF)
			delete(res@cnLevelSpacingF)

			nVars	= v+1 ; this keeps track of how total panels are being plotted

		end do			; variable loop

		;------------- create plot page
		pStr		= (/"a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z" /)
		nPanels		= nVars*2
		;pID			= new(nPanels,"string")
		pID			= pStr
		;print("nPanels = "+nPanels)
		;do i=0,nPanels/2-1
		;	pID(i*2)	= pStr(i)
		;	pID(i*2+1)	= pStr(i+nPanels/2)
		;end do
		resP					= True                   	; modify the panel plot
			resP@gsnFrame			= False                  	; don't advance panel plot
		resP@gsnPanelLabelBar	= False                  	; add common colorbar
		resP@txString			= EXPNAME + " - " + CTRLNAME + "," + " "+ seasonName(s); add common title
		resP@gsnPanelBottom		= 0.05                   	; add space at bottom
		resP@gsnPanelYWhiteSpacePercent = 6
		resP@gsnPanelFigureStrings = pID      ; add letter labels to panels (# letters can be > # panels)
		resP@gsnPanelFigureStringsFontHeightF	= 0.012
		resP@gsnPanelFigureStringsPerimOn		= True
		resP@amJust								= "TopLeft"
		gsn_panel(wks,plot,(/8,1/),resP)                	; now draw as one plot
		;------------- label columns
		txres               	= True                     	; text mods desired
		txres@txFontHeightF		= 0.013                    	; font smaller. default big
		gsn_text_ndc(wks,"~F33~s ~F21~(full SST)",0.49,0.94,txres) 
	    
		res@tmXBLabelsOn	= False ; turn off longitude labels for next season
		
		if (wksType.eq."png") then
			frame(wks)
			trimPNG(wksName)
		end if
		
		print("output file = " + wksName)

	end do 			; season loop

end