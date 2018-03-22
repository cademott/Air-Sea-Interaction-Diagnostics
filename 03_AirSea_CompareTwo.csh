#!/bin/csh

	setenv	PTYPE 			png			# png or pdf plots
	setenv	DEBUG 			"false"		# "false" suppresses non-fatal NCL warning messages
	setenv 	u850_overlay	"false"
	setenv	FIGCAP			"false"

	#=========== This block should point to the COUPLED simulation, or an EXPERIMENT
	setenv 	EXPCASE 		"SPCCSM"
	setenv 	modelname 		$EXPCASE
	source 	./AirSea_definitions.sh # handle model-specific logic
	setenv 	EXPDIR 			$FILEDIR/
	setenv 	EXPDATESTR 		$FILESUFFSTR

	#=========== This block should point to the UNCOUPLED simulation, or the CONTROL, or the OBS
	setenv 	CTRLCASE 		"ERAI"
	setenv 	modelname 		$CTRLCASE
	source 	./AirSea_definitions.sh # handle model-specific logic
	setenv 	CTRLDIR 		$FILEDIR/
	setenv 	CTRLDATESTR 	$FILESUFFSTR
	
	setenv 	PLOTDIR			$EXPDIR"plots/"$EXPCASE"_minus_"$CTRLCASE"/"
	echo   	$PLOTDIR		
	mkdir -p $PLOTDIR

	echo $CTRLCASE
	echo $EXPCASE
	echo $PLOTDIR
	
	#============= LEVEL 1 DIAGNOSTICS:  MEAN, STDEV, RH-SST-WIND PDFs
  	set Plot_Surface_Variables_diff	= "false"	# plot_diff_L1.1_MeanStd.ncl
 	set Plot_SfcEnergyBal_MeanStd	= "false"	# plot_diff_L1.2_SfcEnergyBudget_MeanStd.ncl
 	set Plot_LHFluxComponent_Std	= "false"	# plot_diff_L1.3_LHFluxComponent_Std.ncl
 	set Plot_SHFluxComponent_Std	= "false"	# plot_diff_L1.3_SHFluxComponent_Std.ncl
 	set Plot_u850_PctWesterly		= "false"	# plot_diff_L1.6_diff_U850_WesterlyPct.ncl
 	set Plot_RH_byWindSST_PDFs		= "false"	# plot_diff_L1.7_diff_RH_byWindSST_PDF.ncl
 	
	#============= LEVEL 2 DIAGNOSTICS:  LAG REGRESSIONS
 	#set Plot_LHFluxComp_Prop		= "true"	# plot_diff_L2.1_LHFluxComponent_propagation.ncl
 	#set Plot_SHFluxComp_Prop		= "false"	# plot_diff_L2.1_SHFluxComponent_propagation.ncl
 	#set Plot_SfcEnergyBal_Prop		= "false"	# plot_diff_L2.1_SfcEnergyBalance_propagation.ncl
 	#set Plot_MSEbudget_Prop			= "false"	# plot_diff_L2.1_MSEbudget_propagation.ncl
 	set Plot_LHFluxComp_NoProp		= "false"	# plot_diff_L2.2_LHFluxComponent_nopropagation.ncl
 	set Plot_SHFluxComp_NoProp		= "true"	# plot_diff_L2.2_SHFluxComponent_nopropagation.ncl
 	set Plot_SfcEnergyBal_NoProp	= "false"	# plot_diff_L2.2_SfcEnergyBalance_nopropagation.ncl
 	set Plot_MSEbudget_NoProp		= "false"	# plot_diff_L2.2_MSEbudget_nopropagation.ncl
 	set Plot_SSTEffect_NoProp		= "false"	# plot_diff_L2.2_SSTEffect_nopropagation.ncl
 	set Plot_SfcEnergyBal_IO		= "false"	# plot_diff_L2.3_SfcEnergy_lags.ncl
 	
# 	#============= LEVEL 3 DIAGNOSTICS:  LAG=0 MSE, dMSE/dT, dSST/dt REGRESSION MAPS
 	set Plot_MSEBudget_RegMaps		= "false"	# plot_diff_L3.1_MSEbudget_regressionMaps.ncl
 	#set Plot_FluxComp_RegMaps		= "false"	# plot_L3.2_MSE(dMSEdt)_LH(SH)FluxComp_regressions.ncl
 	#set Plot_dSSTdt_Qnet_RegMaps	= "false"	# plot_L3.3_WnetdSSTdt_regressionMaps.ncl
 	#set SSTeffect_RegMaps			= "false"	# plot_L3.4_SSTeffectSummary.ncl
 	#set Plot_MSE_PDFs				= "false"	# plot_L3.5_MSE_PDF_lineplots.ncl
 	#set Plot_MSE_ModProjectionMaps	= "false"	# plot_L3.6_MSE_ModProjectionMaps.ncl

# 	#--------------------------------------------------------------------------
	if ($Plot_Surface_Variables_diff == "true") then
		ncl -Q ./CompareTwo/plot_diff_L1.1_MeanStd_Maps.ncl
	endif

	#  # plot L1.2: -------------- Surface energy budget term maps
	if ($Plot_SfcEnergyBal_MeanStd == "true") then
		ncl -Q ./CompareTwo/plot_diff_L1.2_SfcEnergyBudget_MeanStd_Maps.ncl
	endif

	#  # plot L1.3: -------------- Latent heat flux component maps
	if ($Plot_LHFluxComponent_Std == "true") then
		ncl -Q ./CompareTwo/plot_diff_L1.3_LHFluxComponent_Std.ncl
	endif

	#  # plot L1.3: -------------- Sensible heat flux component maps
	if ($Plot_SHFluxComponent_Std == "true") then
		ncl -Q ./CompareTwo/plot_diff_L1.3_SHFluxComponent_Std.ncl
	endif

	#  # plot L1.6: -------------- Sensible heat flux component maps
	if ($Plot_u850_PctWesterly == "true") then
		ncl -Q ./CompareTwo/plot_diff_L1.6_U850_WesterlyPct.ncl
	endif

	#  # plot L1.5: -------------- RH_byWindSST_PDF
	if ($Plot_RH_byWindSST_PDFs == "true") then
		ncl -Q ./CompareTwo/plot_diff_L1.7_RH_byWindSST_PDF.ncl
	endif


	####-------------- LEVEL 2 PROCESSING:  LAG REGRESSIONS, WHEELER-KILADIS PLOTS
	#=============================================================================
	
	#	# plot L2.1:  -------------- LHFluxComponent_nopropagation
	if ($Plot_LHFluxComp_NoProp == "true") then
		ncl -Q ./CompareTwo/plot_diff_L2.2_LHFluxComponent_nopropagation.ncl
	endif
	
	if ($Plot_SHFluxComp_NoProp == "true") then
		ncl -Q ./CompareTwo/plot_diff_L2.2_SHFluxComponent_nopropagation.ncl
	endif
	
 	
# 	####-------------- LEVEL 3 PROCESSING:  LAG=0 MSE REGRESSION MAPS
# 	#--------------------------------------------------------------------------
# 	#  # plot L3.1: -------------- MSE budget term regressions onto MSE, dMSE/dt
	if ($Plot_MSEBudget_RegMaps == "true") then	
		ncl -Q plot_diff_L3.1_MSEbudget_regressionMaps.ncl
	endif
# 
# 	#  # plot L3.2: -------------- Flux Components regressed onto MSE
# 	if ($Plot_FluxComp_RegMaps == "true") then	
# 		ncl -Q plot_L3.2_MSE_LHFluxComp_regressions_diff.ncl
# 		ncl -Q plot_L3.2_MSE_SHFluxComp_regressions_diff.ncl
# 		ncl -Q plot_L3.2_dMSEdt_LHFluxComp_regressions_diff.ncl
# 		ncl -Q plot_L3.2_dMSEdt_SHFluxComp_regressions_diff.ncl
# 	endif
# 
# 	#  # plot L3.3: -------------- dSST/dt regressed onto Qnet
# 	if ($Plot_dSSTdt_Qnet_RegMaps == "true") then	
# 		ncl -Q plot_L3.3_QnetdSSTdt_regressionMaps.ncl
# 	endif
# 
# 	#  # plot L3.4: -------------- SST effect on MSE, dMSE/dt
# 	if ($SSTeffect_RegMaps == "true") then	
# 		ncl -Q plot_L3.4_SSTeffectSummary.ncl
# 	endif
# 
# 	#  # plot L3.5: -------------- MSE binned averages (MSE tendency terms)
# 	if ($Plot_MSE_PDFs == "true") then	
# 		ncl -Q plot_L3.5_MSE_PDF_lineplots.ncl
# 	endif
# 
# 	#  # plot L3.5: -------------- MSE binned averages (MSE tendency terms)
# 	if ($Plot_MSE_ModProjectionMaps == "true") then	
# 		ncl -Q plot_L3.6_MSE_ModProjectionMaps.ncl
# 	endif
# 
# 	date



