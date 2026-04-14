/*******************************************************************************
*	Project: Philadelphia Lighting
*	File: Appendix_Table_1_counts
*	Script purpose: run appendix table 1 (main results with counts)
*	Author: Maya Moritz
*	Input: ${data_folder_processed}
*	Output: "${output_tables_folder}/Appendix/Table_A1/counts_`i'`j'.html
*******************************************************************************/
clear
cd ${data_folder_processed}
cap mkdir ${output_tables_folder}/Appendix
cap mkdir ${output_tables_folder}/Appendix/Table_A1/
*Set local, just need counts here

local crimetypes total gun violent property nuisance placebo

foreach j in all outside inside {
	// Initialize to check if this is the first time period
local first_iteration 1
    foreach i in all day night {
use "`i'`j'.dta", clear

summarize lights_sum if lights_sum > 0

local mean_lights = r(mean)

di `mean_lights'

eststo clear
foreach x of local crimetypes{
replace `x' = 0 if missing(`x')
	**use the non-fixed effects version of nbreg because xtnbreg doesn't actually use fixed effects*
eststo: xtreg `x' lights_sum i.ym if ym<773, fe i(spgrid_id) vce(cluster spgrid_id)
*i.spgrid_id was in there but all omitted due to collinearity
estadd ysumm
*estimates store lambda_store
*estadd scalar lightchangemean = `mean_change_lambda_cumr': lambda_store
*Step 2. Calculate average dependent mean in the post period
*Step 3. Calculate (B*X)/(B*Xabs+Ypost) for coefficient and CI
summarize `x' if lights_cum > 0
estadd scalar ypost = r(mean)
estadd scalar lightchangemean = `mean_lights'
estadd scalar adjcoeff = (_b[lights_sum] * `mean_lights')/(abs(_b[lights_sum])+e(ypost))*100
estadd scalar adjCIlower = ((_b[lights_sum]- 1.96*_se[lights_sum]) * `mean_lights') / (abs((_b[lights_sum]- 1.96*_se[lights_sum])) + e(ypost))*100
estadd scalar adjCIupper = ((_b[lights_sum]+ 1.96*_se[lights_sum]) * `mean_lights') / (abs((_b[lights_sum]+ 1.96*_se[lights_sum])) + e(ypost))*100
estadd scalar AdjR2 = e(r2_a)
estadd scalar R2 = e(r2)

}

esttab using "${output_tables_folder}/Appendix/Table_A1/counts_`i'`j'.html", ///
    keep(lights_sum) ///
    depvar se stats(ypost N lightchangemean adjCIlower adjcoeff adjCIupper R2 AdjR2, labels ("Monthly Mean Crime Post" "N" "Monthly Mean Lights Post" "Lower % CI" "% Crime Change" "Upper % CI" "R^{2}" "Adj. R^{2}")) ///
	varlabels (lights_sum "Cumulative Lights") ///
	varwidth(0) modelwidth(0) ///
	width(100%) ///
    label nonumber ///
    title("Changes in Lights on `i' `j' Crime ") ///
    mtitle("Total" "Gun" "Violent" "Property" "Nuisance" "Financial") ///
    note(Standard errors in parentheses; Hexagon and year-month fixed effects) ///
	replace

}
}
