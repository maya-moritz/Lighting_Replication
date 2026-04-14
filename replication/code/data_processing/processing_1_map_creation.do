/*******************************************************************************
*	Project: Philadelphia Lighting
*	File: processing_1_map_creation.do
*	Script purpose: Create mapping files
*	Input: ${data_folder_raw_mapping}/City_Limits/City_Limits.shp
*			${data_folder_raw_mapping}/Phila_Region_wgs84.shp
*	Output: ${data_folder_raw_mapping}/PHL-GridPoints.dta
*			${data_folder_raw_mapping}/PHL-GridCells.dta
*			${data_folder_raw_mapping}/Region_mercator.dta
*	Author: John MacDonald, reformatted by Maya Moritz
*******************************************************************************/
cd "${data_folder_raw}"
*make a shapefile for city

shp2dta using "${data_folder_raw_mapping}/City_Limits/City_Limits.shp", database("${data_folder_raw_mapping}/City_Limits/City_Limits.dta") coordinates ("${data_folder_raw_mapping}/City_Limits/City_Limits_coord.dta") replace

*reproject to web_mercator coordinates*
use "${data_folder_raw_mapping}/City_Limits/City_Limits_coord.dta", clear
geo2xy _Y _X, replace project(mercator)
save "${data_folder_raw_mapping}/City_Limits/City_Limits_mercator.dta", replace

set more off, perm
*this command creates a grid map from the projection of City LImits*
spgrid using "${data_folder_raw_mapping}/City_Limits/City_Limits_mercator.dta",   ///
        resolution(w1000) unit(meters)             ///
        cells("${data_folder_raw_mapping}/PHL-GridCells.dta")                 ///
        points("${data_folder_raw_mapping}/PHL-GridPoints.dta")               ///
        replace compress dots
*this maps what the grid looks like*	

**now the Philadelphia region projection

shp2dta using "${data_folder_raw_mapping}/Phila_Region_wgs84.shp", database("${data_folder_raw_mapping}/Region.dta") coordinates ("${data_folder_raw_mapping}/Region_coord.dta") replace
use "${data_folder_raw_mapping}/Region_coord.dta", clear
geo2xy _Y _X, replace project(mercator)
save "${data_folder_raw_mapping}/Region_mercator.dta", replace

use "${data_folder_raw_mapping}/PHL-GridPoints.dta", clear
spmap using "${data_folder_raw_mapping}/PHL-GridCells.dta", id(spgrid_id)  