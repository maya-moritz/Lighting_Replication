/*******************************************************************************
*	Project: Philadelphia Lighting
*	File: Table_1_summary_stats.do
*	Script purpose: create summary statistics (Table 1)
*	Author: Maya Moritz with amendments from John MacDonald
*	Input: allall.dta from data_folder_processed
*	Output: Table 1, ${output_tables_folder}/Table_1_sum_stats.html
*******************************************************************************/
clear
eststo clear
cd ${data_folder_processed}

use "allall.dta", clear

*ever treated
* for ever treated:
gen treated = 0

* Check if lambda_cumr is ever greater than 0 for each spgrid_id
bysort spgrid_id: egen max_lambda = max(lambda_cumr)

* Update treated to 1 if max_lambda is greater than 0
replace treated = 1 if max_lambda > 0

* Drop the temporary variable
drop max_lambda

*using a mean of pre-period
estpost tabstat $outcomes , by(treated) ///
statistics(mean sd min max n) columns(statistics) listwise
esttab using "${output_tables_folder}/Table_1_sum_stats.html", replace noobs nonumber ///
              title("Table 1. Comparison of Areas by Lights Treatment") ///
              cells("mean(fmt(2)) sd(fmt(2)) min(fmt(1)) max(fmt(1)) count(fmt(0))") ///
    collabels("Mean" "St. Dev" "Min" "Max" "N=") ///
varlabels (lambda_totalr "Total Crimes" lambda_gunr "Gun Crimes" lambda_violentr "Violent Crimes" lambda_propertyr "Property Crimes" ///
           lambda_nuisancer "Nuisance Crimes" lambda_placebor "Financial Crimes") ///
                               note(Untreated have no lights installed between August 2023 and May 2024. N=hexagon*months)