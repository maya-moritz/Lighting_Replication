/*******************************************************************************
*	Project: Philadelphia Lighting
*	File: Appendix_Table_3_region
*	Script purpose: create Appendix Table 3, maion results with region time FE
*	Author: Maya Moritz
*	Input: ${data_folder_processed}
*	Output: "${output_tables_folder}/Appendix/Table_A3/regionymfe_kde_`i'.html"
*******************************************************************************/
cap mkdir ${output_tables_folder}/Appendix/Table_A3/
clear
eststo clear
cd ${data_folder_processed}

    foreach i in all day night {
use "`i'all.dta", clear


keep if ym < 772 & ym > 737

//gen regionym = region * ym


*Step 1: Calculate mean lights added per month in the post period, B
summarize lambda_cumr if lambda_cumr > 0

local mean_lights = r(mean)

di "`mean_lights'"

eststo clear

foreach x of global outcomes {

*original from John conversation: region-ym fixed effects: this one is correct:
//eststo: xtreg `x' lambda_cumr i.regionym, fe i(spgrid_id) vce(cluster spgrid_id)
//Change to:
eststo: xtreg `x' lambda_cumr i.ym#c.region if ym<773, fe i(spgrid_id) cluster(spgrid_id)

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

esttab using "${output_tables_folder}/Appendix/Table_A3/regionymfe_kde_`i'.html", ///
    keep(lambda_cumr) ///
    depvar se stats(ypost N lightchangemean adjCIlower adjcoeff adjCIupper R2 AdjR2, labels ("Monthly Mean Crime Post" "N" "Monthly Mean Lights Post" "Lower % CI" "% Crime Change" "Upper % CI" "R^{2}" "Adj. R^{2}")) ///
	varlabels (lambda_cumr "Cumulative Lights") ///
	varwidth(0) modelwidth(0) ///
	width(100%) ///
    label nonumber ///
    title("Changes in Lights on `capitalized_i' Crime with Region-Year-Month Fixed Effects") ///
    mtitle("Total" "Gun" "Violent" "Property" "Nuisance" "Financial") ///
    note(Standard errors in parentheses; Hexagon and year-month fixed effects as well as region-year-month fixed effects. Data utilized is from July 2022 through April 2024) ///
	replace

	}
