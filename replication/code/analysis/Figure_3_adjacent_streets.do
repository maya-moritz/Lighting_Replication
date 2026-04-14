/*******************************************************************************
*	Project: Philadelphia Lighting
*	File: Figure_3_adjacent_streets.do
*	Script purpose: create adjacent streets graph (Figure 3)
*	Author: Maya Moritz and John MacDonald
*	Input: "${data_folder_processed}/adjacent_nonadjacent_street_sample.dta" and mapping files
*	Output: 
*******************************************************************************/
clear
eststo clear

use "${data_folder_processed}/adjacent_nonadjacent_street_sample.dta", clear

rename seg_id SEG_ID
collapse level_of_treat, by(SEG_ID) 

merge m:1 SEG_ID using "${data_folder_raw_mapping}/streets/Street_Centerline.dta", generate(merge_street)

gen level_of_treat_1 = level_of_treat + 1
replace level_of_treat_1 = 1 if missing(level_of_treat)


* 2. Define a value label that maps numbers → text
label define treat_lbl 1 "no lights" 2 "adjacent" 3 "lights", replace
label values level_of_treat_1 treat_lbl

* 3. Now draw the map
spmap level_of_treat_1 using "${data_folder_temp}/streets/Street_Centerline_coord.dta", id(_ID) ///
    fcolor("white" "green" "red") ocolor("grey" "green" "red") ///
    osize(vvthin) ///
    note("Source: Philadelphia Energy Authority Lights on Street Center Lines, August 2023-May 2024", size(2.5)) ///
    legend(pos(6) ring(0) region(fcolor(white) lcolor(grey))) ///
    clmethod(unique) clbreaks(1 2 3)
	
graph export "${output_figures_folder}/Figure_3/Fig_3_streetmap.png", replace