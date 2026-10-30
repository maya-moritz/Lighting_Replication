# Table_1_summary_stats.r
#
#
# An R translation for Table_1_summary_stats.do.
#

###########
# Set up. #
###########
# ----
if( !exists( "countoutcomes" ) ) source( "master.R" )

# Load data
# df <- readr::read_csv( file.path( data_folder_processed, "allall.csv") )
df <- haven::read_dta( file = file.path( data_folder_processed, "allall.dta") )

# Add a variable indicating whether the location had lights installed.
df <-
  df %>%
  dplyr::group_by( spgrid_id ) %>%
  dplyr::mutate(
    treated = 
      dplyr::if_else(
        max( lambda_cumr, na.rm = TRUE ) > 0
        ,"Light upgrades"
        ,"No upgrades"
      )
  ) %>%
  dplyr::ungroup()
# ----

###################
# Make the table. #
###################
# ----
  
# Make table as dataframe.
table1_temp <-
  df %>%
  dplyr::select( treated, all_of( outcomes ) ) %>%
  tidyr::pivot_longer(
    cols = all_of( outcomes ),
    names_to = "variable",
    values_to = "value"
  ) 
table_1 <-
  dplyr::bind_rows(
    table1_temp %>% 
    dplyr::group_by( treated, variable ) %>%
    dplyr::summarise(
      Mean = mean( value, na.rm = TRUE) ,
      `St. Dev` = sd( value, na.rm = TRUE ),
      Min = min( value, na.rm = TRUE ),
      Max = max( value, na.rm = TRUE ),
      N = sum( !is.na( value ) ),
      .groups = "drop"
    ) %>%
    dplyr::ungroup() 
  
    ,table1_temp %>%
      dplyr::group_by( variable ) %>%
      dplyr::summarise(
        Mean = mean( value, na.rm = TRUE) ,
        `St. Dev` = sd( value, na.rm = TRUE ),
        Min = min( value, na.rm = TRUE ),
        Max = max( value, na.rm = TRUE ),
        N = sum( !is.na( value ) ),
        .groups = "drop"
      ) %>%
      dplyr::ungroup() %>%
      dplyr::mutate( treated = "Entire sample" )
    ) %>%
  dplyr::mutate(
    variable = labels[ variable ]
    ,variable = factor( variable, levels = as.vector( labels ) )
    ,treated = factor( treated, levels = c( "No upgrades", "Light upgrades", "Entire sample" ) )
    ) %>%
  dplyr::arrange( treated, variable )

# Save table as CSV.
write.csv( table1, file.path( output_tables_folder, "Table_1_sum_stats.csv" ) )
rm( table1_temp )

# Format as gt table.
gt_table <-
  table_1 %>%
  gt::gt( groupname_col = "treated" ) %>%
  gt::fmt_number(
    columns = c( Mean, `St. Dev` ),
    decimals = 2
  ) %>%
  gt::fmt_number(
    columns = c( Min, Max ),
    decimals = 1
  ) %>%
  gt::cols_align(
    align = "left"
    ,columns = variable
  ) %>%
  gt::tab_header(
    title = "Table 1. Comparison of Areas by Lights Treatment"
  ) %>%
  gt::tab_source_note(
    source_note = "Untreated areas have no lights installed between August 2023 
    and May 2024. N = hexagon × months."
  )

# Save table as HTML.
gt::gtsave( gt_table, file.path( output_tables_folder ,"/Table_1_sum_stats.html" ) )
# ----