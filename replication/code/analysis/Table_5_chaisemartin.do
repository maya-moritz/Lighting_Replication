/*******************************************************************************
*	Project: Philadelphia Lighting
*	File: Table_5_chaisemartin
*	Script purpose: Table 5 (de Chaisemartin and D'Haultfœuille (2020) analyses)
*	Author: Maya Moritz
*	Input:  files in ${data_folder_processed}
*	Output: ${output_tables_folder}/Table_5/
*******************************************************************************/
clear
cd ${data_folder_processed}
cap mkdir ${output_tables_folder}/Table_5_chaisemartin

foreach j in all outside inside{
    foreach i in all day night {
		*can add day night
		eststo clear
use "`i'`j'.dta", clear

foreach x of global outcomes{
local capitalized_i = upper(substr("`i'", 1, 1)) + lower(substr("`i'", 2, .))
local capitalized_j = upper(substr("`j'", 1, 1)) + lower(substr("`j'", 2, .))
local capitalized_x = upper(substr("`x'", 8, 1)) + lower(substr("`x'", 9, length("`x'") - 9))
eststo: did_multiplegt_dyn `x' spgrid_id ym lambda_cumr, effects(8) placebo(8) cluster(spgrid_id) graph_off 
estadd scalar N = e(N_avg_total_effect)

}
	esttab using "${output_tables_folder}/Table_5_chaisemartin/chaisemartin_`i'`j'.html", ///
    keep(Av_tot_eff) ///
	coef(Av_tot_eff "Average Total Effect") ///
	depvar se stats(N, labels ("Observations")) ///
    label nonumber ///
    title("Changes in Lights on KDE `i' `j' Crime Using de Chaisemartin and D'Haultfœuille (2020)") ///
    mtitle("Total" "Gun" "Violent" "Property" "Nuisance" "Placebo") ///
    note(Standard errors in parentheses; Hexagon and year-month fixed effects) ///
    replace
	
}
}