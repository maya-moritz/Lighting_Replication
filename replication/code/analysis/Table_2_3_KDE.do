/*******************************************************************************
*	Project: Philadelphia Lighting
*	File: Table_2_3
*	Script purpose: create main tables and coefficient plots for KDE (tables 2 and 3)
*	Author: Maya Moritz
*	Input: data_folder_processed
*	Output: Table 2 and 3, ${output_tables_folder}/Table_2_3/
*******************************************************************************/
clear
cap mkdir ${output_tables_folder}/Table_2_3
eststo clear
cd ${data_folder_processed}

*run loop for all locations and all times as need all of those to make coefficient plots
foreach j in all outside inside {
	// Initialize to check if this is the first time period
local first_iteration 1
    foreach i in all day night {
use "`i'`j'.dta", clear

*Step 1: Calculate mean lights added per month in the post period, B
summarize lambda_cumr if lambda_cumr > 0

local mean_lights = r(mean)

di "`mean_lights'"

eststo clear
foreach x of global outcomes {
eststo: xtreg `x' lambda_cumr i.ym, fe i(spgrid_id) vce(cluster spgrid_id)
*estadd ysumm
*estimates store lambda_store
*estadd scalar lightchangemean = `mean_change_lambda_cumr': lambda_store
*Step 2. Calculate average dependent mean in the post period
*Step 3. Calculate (B*X)/(B*Xabs+Ypost) for coefficient and CI
summarize `x' if lambda_cumr > 0
estadd scalar ypost = r(mean)
*ypost is the mean monthly KDE of crimes after lights come in
estadd scalar lightchangemean = `mean_lights'
*light change mean and mean_lights is the mean monthly number of lights after lights come in
estadd scalar adjcoeff = (_b[lambda_cumr] * `mean_lights')/(abs(_b[lambda_cumr])+e(ypost))*100
estadd scalar adjCIlower = ((_b[lambda_cumr]- 1.96*_se[lambda_cumr]) * `mean_lights') / (abs((_b[lambda_cumr]- 1.96*_se[lambda_cumr])) + e(ypost))*100
estadd scalar adjCIupper = ((_b[lambda_cumr]+ 1.96*_se[lambda_cumr]) * `mean_lights') / (abs((_b[lambda_cumr]+ 1.96*_se[lambda_cumr])) + e(ypost))*100

estadd scalar AdjR2 = e(r2_a)
estadd scalar R2 = e(r2)

matrix percchange_`x' = (e(adjcoeff))

matrix CI_`x' = (e(adjCIlower)\ e(adjCIupper))

matrix colnames percchange_`x' = `x' 

matrix colnames CI_`x' = `x'


matrix rownames CI_`x' = ll95 ul95
}

 * Capitalize 'i' for the filename
local capitalized_i = upper(substr("`i'", 1, 1)) + lower(substr("`i'", 2, .))
local capitalized_j = upper(substr("`j'", 1, 1)) + lower(substr("`j'", 2, .))

esttab using "${output_tables_folder}/Table_2_3/kde_`i'`j'.html", ///
    keep(lambda_cumr) ///
    depvar se stats(ypost N lightchangemean adjCIlower adjcoeff adjCIupper R2 AdjR2, labels ("Monthly Mean Crime Post" "N" "Monthly Mean Lights Post" "Lower % CI" "% Crime Change" "Upper % CI" "R^{2}" "Adj. R^{2}")) ///
	varlabels (lambda_cumr "Cumulative Lights") ///
	varwidth(0) modelwidth(0) ///
	width(100%) ///
    label nonumber ///
    title("Changes in Lights on `capitalized_i' `capitalized_j' Crime ") ///
    mtitle("Total" "Gun" "Violent" "Property" "Nuisance" "Financial") ///
    note(Standard errors in parentheses; Hexagon and year-month fixed effects) ///
	replace

	}
}


