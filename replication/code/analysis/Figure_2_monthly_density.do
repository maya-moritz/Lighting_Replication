/*******************************************************************************
*	Project: Philadelphia Lighting
*	File: Figure_2_monthly_density.do
*	Script purpose: create monthly density of lights (Figure 2)
*	Author: Maya Moritz and John MacDonald
*	Input: "${data_folder_temp}/kde/lights/Kde_lights.dta" as well as mapping files
*	Output: Figure 2
*******************************************************************************/
clear
eststo clear
cd ${data_folder_processed}

use "${data_folder_temp}/kde/lights/Kde_lights.dta", clear	
	
	
by spgrid_id,: gen lambda_lights=sum(lambda)

keep if ym==763

collapse (mean) ndp lambda_lights, by(spgrid_id)

gen rate=round(lambda_lights*649519)

spmap rate using "${data_folder_raw}/mapping/PHL-GridCells.dta",  /// 
	id(spgrid_id) clnum(10) fcolor(Rainbow) ocolor(none ..) legend(subtitle(Per 1000m) size(medium) position(4)) ///
	title ("Monthly Density of Lights", size(*1.0))  ///
	note ("Source: Philadelphia Energy Authority, August 2023", size(small) position(6)) 

graph export "${output_figures_folder}/Figure_2/Fig_2_Panel_A.png", replace

clear
eststo clear
	
***map of lights**

use "${data_folder_temp}/kde/lights/Kde_lights.dta", clear

by spgrid_id,: gen lambda_lights=sum(lambda)

keep if ym==772

collapse (mean) ndp lambda_lights, by(spgrid_id)

gen rate=round(lambda_lights*649519)

spmap rate using "${data_folder_raw}/mapping/PHL-GridCells.dta",  /// 
	id(spgrid_id) clnum(10) fcolor(Rainbow) ocolor(none ..) legend(subtitle(Per 1000m) size(medium) position(4)) ///
	title ("Monthly Density of Lights", size(*1.0))  ///
	note ("Source: Philadelphia Energy Authority, May 2024", size(small) position(6)) 
	
graph export "${output_figures_folder}/Figure_2/Fig_2_Panel_B.png", replace
