#!/bin/csh

# #		fixme: see if some of the regression steps (e.g., make_L1.4...) can be distributed across
# #				multiple processors, if available


#  	#--- User-defined logical variables to control which bits are executed.
#	#--- This is intended for convenient debugging and restarting of processing
#	#--- if needed.  Intentionally bypassing some of the "make" steps will 
#	#--- likely result in later "plot" errors.

	#--- Preconditioning steps:  make additional variables, anomaly time series
	#--- ========= > THESE STEPS SHOULD BE DONE ONLY ONCE!!! <=================
	#--- Once run, set the variables to "false."  
	#--- Other time spans can be analyzed or new analyses performed 
	#--- without regenerating these fields.

	set Make_AirSea_Vars			= "true"	# make_L1.1_airsea_vars.ncl
	set Make_Anomaly_Timeseries		= "true"	# make_L1.2a_background_anomaly_2Dfield.ncl
	set Make_SfcFlux_Components		= "true"	# make_L1.3_flux_components.ncl
	

	#============= LEVEL 1 DIAGNOSTICS:  MEAN, STDEV, RH-SST-WIND PDFs
	#--- Analysis steps:  perform analyses over user-specified time range
	#--- Select starting and ending date for analysis in airsea_definitions_DB.sh.  

	set Make_SeasonMean_u850		= "true"	# make_L1.3a_mean_u850.ncl
	set Make_Mean_Stdev_Maps		= "true"	# make_L1.4_mean_stdev_map.ncl
	set Make_FluxComp_Stdev_Maps	= "true"	# make_L1.5_stdev_map.ncl
	set Make_u850_PctWesterly_Maps	= "true"	# make_L1.6_U850_WesterlyPct.ncl
	set Make_RH_Wind_SST_PDF		= "true"	# make_L1.7_RH_byWindSST_PDF.ncl
	
	#--- Plotting steps:  plot fields computed above
	set Plot_Surface_Variables		= "true"	# plot_L1.1_SfcVariables_MeanStd.ncl
	set Plot_SfcEnergyBal_MeanStd	= "true"	# plot_L1.2_SfcEnergyBudget_MeanStd.ncl
	#set Plot_LHFluxComponent_Std	= "true"	# plot_L1.3_LHFluxComponent_Std.ncl
	#set Plot_SHFluxComponent_Std	= "true"	# plot_L1.3_SHFluxComponent_Std.ncl
	set Plot_LHFluxComponent_Diff	= "true"	# plot_L1.3_LHFluxComponent_Std_diff.ncl
	set Plot_SHFluxComponent_Diff	= "true"	# plot_L1.3_SHFluxComponent_Std_diff.ncl
	set Plot_LHComponent_Ratios		= "true"	# plot_L1.4_LHFluxComponent_StdevRatio.ncl
	set Plot_SHComponent_Ratios		= "true"	# plot_L1.4_SHFluxComponent_StdevRatio.ncl
	set Plot_RH_byWindSST_PDFs		= "true"	# plot_L1.5_RH_byWindSST_PDF.ncl
	set Plot_u850_PctWesterly		= "true"	# plot_L1.6_U850_WesterlyPct.ncl
	set Plot_MSE_dMSEdt_Mean_Std	= "true"	# plot_L1.7_MSE_dMSEdt_MeanStd.ncl
	
	#============= LEVEL 2 DIAGNOSTICS:  LAG REGRESSIONS, WHEELER-KILADIS PLOTS
	#--- Analysis steps:  perform analyses over user-specified time range
	#--- Select starting and ending date for analysis in airsea_definitions_DB.sh.  

	set Make_LagRegression_Prop		= "false"	# make_L2.1_regression_propagation.ncl
	set Make_LagRegression_NoProp	= "false"	# make_L2.2_regression_nopropagation.ncl
	set Make_WaveNumber_Frequency	= "false"	# make_L2.3_wkSpaceTime_AirSea.ncl
	set Make_WaveNumber_Ratio		= "false"	# make_L2.4_wkSpaceTime_Ratio.ncl

	#--- Plotting steps:  plot fields computed above
	set Plot_LHFluxComp_Prop		= "false"	# plot_L2.1_LHFluxComponent_propagation.ncl
	set Plot_SHFluxComp_Prop		= "false"	# plot_L2.1_SHFluxComponent_propagation.ncl
	set Plot_SfcEnergyBal_Prop		= "false"	# plot_L2.1_SfcEnergyBalance_propagation.ncl
	set Plot_MSEbudget_Prop			= "false"	# plot_L2.1_MSEbudget_propagation.ncl
	set Plot_LHFluxComp_NoProp		= "false"	# plot_L2.2_LHFluxComponent_nopropagation.ncl
	set Plot_SHFluxComp_NoProp		= "false"	# plot_L2.2_SHFluxComponent_nopropagation.ncl
	set Plot_SfcEnergyBal_NoProp	= "false"	# plot_L2.2_SfcEnergyBalance_nopropagation.ncl
	set Plot_MSEbudget_NoProp		= "false"	# plot_L2.2_MSEbudget_nopropagation.ncl
	set Plot_SSTEffect_NoProp		= "false"	# plot_L2.2_SSTEffect_nopropagation.ncl
	set Plot_SfcEnergyBal_IO		= "false"	# plot_L2.3_SfcEnergy_lags.ncl
	
	#============= LEVEL 3 DIAGNOSTICS:  LAG=0 MSE, dMSE/dT, dSST/dt REGRESSION MAPS
	#--- Analysis steps:  perform analyses over user-specified time range
	#--- Select starting and ending date for analysis in airsea_definitions_DB.sh.  
	set Make_MSERegress_AllPhases	= "false"	# make_L3.1_regressionMaps.ncl
	set Make_RainRegress_AllPhases	= "false"	# make_L3.1_regressionMaps.ncl
	set Make_MiscRegress_AllPhases	= "false"	# make_L3.1_regression_map.ncl
	set Make_MSE_PDFs				= "false"	# make_L3.2_MSE_PDF_lineplots.ncl
	set Make_Modified_Projection	= "false"	# make_L3.4_MSE_ModProjectionMaps.ncl

	#--- Plotting steps:  plot fields computed above
	set Plot_MSEBudget_RegMaps		= "false"	# plot_L3.1_MSEbudget_regressionMaps.ncl
	set Plot_FluxComp_RegMaps		= "false"	# plot_L3.2_MSE(dMSEdt)_LH(SH)FluxComp_regressions.ncl
	set Plot_dSSTdt_Qnet_RegMaps	= "false"	# plot_L3.3_WnetdSSTdt_regressionMaps.ncl
	set SSTeffect_RegMaps			= "false"	# plot_L3.4_SSTeffectSummary.ncl
	set Plot_MSE_PDFs				= "false"	# plot_L3.5_MSE_PDF_lineplots.ncl
	set Plot_MSE_ModProjectionMaps	= "false"	# plot_L3.6_MSE_ModProjectionMaps.ncl


;foreach modelname ( mi-ab598_cplfcst_ctl_day5 ) # must match $modelname in $FILEDIR
foreach modelname ( MetUM-GOML ) # must match $modelname in $FILEDIR
	setenv caseName $modelname
	source ./airsea_definitions_DB.sh # handle model-specific logic
	echo $modelname

	ncl -Q ./debug_MetUM_airseaVars.ncl

end # end loop over models


