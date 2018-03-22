load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/diagnostics_cam.ncl"
load "/Users/demott/Dropbox/ncl/wkSpaceTime_plot.ncl"
load "substring.ncl"

begin

	print("=============== in plot_diff_L2.4_wkSpaceTime.ncl =================")
	
	progGenU850	= ".make_L1.3a_mean_u850."
	progGenVa	= ".make_L1.4_mean_stdev_map."

	;------------- set dynamic variable names
	CTRLNAME	= getenv("CTRLCASE")
	CTRLDIR		= getenv("CTRLDIR")
	CTRLDATESTR	= getenv("CTRLDATESTR")
	EXPNAME		= getenv("EXPCASE")
	EXPDIR		= getenv("EXPDIR")
	EXPDATESTR	= getenv("EXPDATESTR")
	varName		= getenv("inName")
	;dirp		= CTRLDIR + "plots"
	dirp		= "/Users/demott/Projects/Coup_Uncoup/"
	caseName	= CTRLNAME + " vs " + EXPNAME
	
	diri		= CTRLDIR + "proc/" + CTRLNAME + "_minus_" + EXPNAME + "/"
	fili		= diri + CTRLNAME + "_vs_" + EXPNAME + "." + varName + ".wkSpaceTime.nc"
	f			= addfile(fili,"r")
	tName		= varName + "_raw_ratio_SYM"
	data		= f->$tName$
	
	opt      		= True
	opt@pltType		= "pdf"
	opt@netCDF		= True
	opt@dirNetCDF	= dirp
	;opt@filNetCDF	= pfile
	opt@cnLinesOn	= False		; turn off contour lines
	opt@pltTitle	= caseName + ": " + varName
	opt@levels		= (/ 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1., 1.1, 1.2, 1.4, 1.7, 2.0, 2.4, 2.8 /)

	
	SymAsym			= "Sym"
	wkSpaceTime_plot (data,dirp,caseName,varName,SymAsym,opt)
	
end
	
	
	