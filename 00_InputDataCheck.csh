#!/bin/csh

# #---- L0:  Pre-processing (compute extra fields, anomaly time series) ------

foreach modelname ( ERAI ) # must match directories in FILEDIR

	setenv caseName $modelname
	source ./AirSea_definitions.sh # handle model-specific logic
	echo $modelname

 	ncl -Q ./AirSea_Diagnostics/make_L0.0_VarTest.ncl
	
	####-------------- LEVEL 0 PROCESSING:  CHECK FOR _FillValue
	#
	#==========================================================================
	#ncl -Q ./AirSea_Diagnostics/make_L0.0_FillValue_check.ncl <----- this may be obsolete see L0.0_VarTest.ncl
	#==========================================================================
	#
	#	note:  if _FillValue attributes are needed, edit and run make_L0.1_Add_FillValue.ncl as needed
	#	note:  if lat/lon units need correcting, do so using NCO or CDO operators


	#--------------------------------------------------------------------------
	#  if needed, add _FillValue attributes to variables.  check output
	#  of make_L0.0_FillValue_check.ncl before using.
	#
	#=====> edit before using:   ./AirSea_Diagnostics/make_L0.1_Add_FillValue.ncl
	#
	#
	# >>>>>>>>>>>>>>>> USER ENTERS VARIABLE NAMES NEEDING FILL VALUES <<<<<<<<<<<<<
 	#foreach varName ( PRECT U10 V10 LHFLX SHFLX FSNS FLNS QREFHT TREFHT TS PS U850 )
 	#	setenv inName $varName
	#==========================================================================
 	#	ncl -Q ./AirSea_Diagnostics/make_L0.1_Add_FillValue.ncl
	#==========================================================================
 	#end
	#
  	#foreach varName ( Vmse Vdmdt Vm_hadv Vudmdx Vvdmdy Vomegadmdp Vlw Vsw )
  	#	setenv inName $varName
  	#	ncl -Q ./AirSea_Diagnostics/make_L0.1_Add_FillValue.ncl
  	#end
	#==========================================================================

	####-------------- LEVEL 0 PROCESSING:  CHECK/CHANGE (IF NEEDED) SIGN OF SURFACE FLUXES
	#  # make_L0.2_FluxSignFix.ncl--- change sign of surface fluxes as follows:
	#		netSW > 0 	warms ocean (positive to ocean)
	#		netLW > 0 	warms atm (positive to atmosphere)
	#		LHFLX > 0	warms atm (positive to atmosphere)
	#		SHFLX > 0	warms atm (positvie to atmosphere)
	#==========================================================================
	#ncl -Q ./AirSea_Diagnostics/make_L0.2_FluxSignFix.ncl
	#==========================================================================

end # end loop over models
