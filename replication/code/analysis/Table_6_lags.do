/*******************************************************************************
*	Project: Philadelphia Lighting
*	File: Table_6_lags
*	Script purpose: create Table 6 (lags)
*	Author: Maya Moritz
*	Input:  "allall.dta" in ${data_folder_processed}
*	Output: ${output_tables_folder}/Table_6_lags_kde.html"
*******************************************************************************/

clear
eststo clear
cd ${data_folder_processed}

use "allall.dta", clear
xtset spgrid_id ym

foreach y of global outcomes {
    eststo: xtreg `y' lambda_cumr L(1/3).`y' i.ym if ym<773, fe i(spgrid_id) robust
	estadd ysumm
}

esttab using "${output_tables_folder}/Table_6_lags_kde.html", keep(lambda_cumr) depvar se stats(ymean N, labels ("Ave. Dep" "N")) label  ///
nonumber title("Changes in Lights on Crime") mtitle("Total" "Gun" "Violent" "Property" "Nuisance" "Financial") ///
    note(Standard errors in parentheses; Hexagon and year-month fixed effects) ///
    replace



