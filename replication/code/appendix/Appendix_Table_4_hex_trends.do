/*******************************************************************************
*	Project: Philadelphia Lighting
*	File: Appendix_Table_4_hex_trends
*	Script purpose: create Appendix Table 4, main results with hexagon linear time 
					trends
*	Author: Maya Moritz
*	Input: ${data_folder_processed}
*	Output: "${output_tables_folder}/Appendix/Table_A4/hextrends_`i'.html"
*******************************************************************************/
cap mkdir ${output_tables_folder}/Appendix/Table_A4/
clear
eststo clear
cd ${data_folder_processed}
	
	
foreach j in all {
	// Initialize to check if this is the first time period
local first_iteration 1
    foreach i in all day night {
use "`i'`j'.dta", clear


keep if ym < 772 & ym > 737


bysort spgrid_id (ym): gen trend = _n

gen trend_spgrid = trend * spgrid_id  // interaction term (manual method)


*Step 1: Calculate mean lights added per month in the post period, B
summarize lambda_cumr if lambda_cumr > 0

local mean_lights = r(mean)

di "`mean_lights'"

eststo clear
foreach x of global outcomes {
tsset spgrid_id ym

eststo: reghdfe `x' lambda_cumr trend if trend<24, absorb(spgrid_id trend_spgrid) vce(cluster spgrid_id)
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

matrix percchange_`x' = (e(adjcoeff))

matrix CI_`x' = (e(adjCIlower)\ e(adjCIupper))

matrix colnames percchange_`x' = `x' 

matrix colnames CI_`x' = `x'


matrix rownames CI_`x' = ll95 ul95

}

 * Capitalize 'i' for the filename
local capitalized_i = upper(substr("`i'", 1, 1)) + lower(substr("`i'", 2, .))
local capitalized_j = upper(substr("`j'", 1, 1)) + lower(substr("`j'", 2, .))

esttab using "${output_tables_folder}/Appendix/Table_A4/hextrends_`i'`j'.html", ///
    keep(lambda_cumr) ///
    depvar se stats(ypost N lightchangemean adjCIlower adjcoeff adjCIupper, labels ("Monthly Mean Crime Post" "N" "Monthly Mean Lights Post" "Lower 5%" "% Crime Change" "Upper 95%")) ///
	varlabels (lambda_cumr "Cumulative Lights") ///
	varwidth(0) modelwidth(0) ///
	width(100%) ///
    label nonumber ///
    title("Changes in Lights on `capitalized_i' Crime with Hexagon-Specific Time Trends") ///
    mtitle("Total" "Gun" "Violent" "Property" "Nuisance" "Financial") ///
    note(Standard errors in parentheses; Hexagon and year-month fixed effects as well as hexagon-specific time trends included. Data utilized is from July 2022 through April 2024) ///
	replace
	}
}