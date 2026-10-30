# Table_4_street_analysis.r
#
#
# An R translation for Table_4_street_analysis.do.
#


##########
# Setup. #
##########
# ----
# Name a vector of variables that will be used in this analysis.
vars <- c( "total_crime", "gun", "violent", "property", "nuisance", "financial" )

# Load data.
df <-
  # readr::read_csv(
  haven::read_dta(
    file.path(
      data_folder_processed
      # ,"adjacent_nonadjacent_street_sample.csv"
      ,"adjacent_nonadjacent_street_sample.dta"
      )
    ) %>%
  dplyr::filter( level_of_treat < 2 )

# Replace missing day/night crime counts with 0 when total_crime == 0.
for ( i_var in vars ) {
  
  day_var <- paste0( i_var, "_day" )
  day_buffer_var <- paste0( i_var, "_day_buffer" )
  night_var <- paste0( i_var, "_night" )
  night_buffer_var <- paste0( i_var, "_night_buffer" )
  
  df <-
    df %>%
    dplyr::mutate(
      !!day_var :=
        dplyr::if_else( total_crime == 0, 0, .data[[ day_var ]] )

      ,!!day_buffer_var :=
        dplyr::if_else( total_crime == 0, 0, .data[[ day_buffer_var ]] )

      ,!!night_var :=
        dplyr::if_else( total_crime == 0, 0, .data[[ night_var ]] )

      ,!!night_buffer_var :=
        dplyr::if_else( total_crime == 0, 0, .data[[ night_buffer_var ]] )
    )
}

# Remove any rows where the day or night counts of crime are missing, and 
# remove any rows referring to dates outside the observation window.
analysis_df <-
  df %>%
  dplyr::filter(
    !is.na( level_of_treat )
    ,ym < 773
    )
# ----

###############
# Fit models. #
###############
# ----

# The all-data data set.
models_all <-
  purrr::map(
    vars
    ,~ fixest::fepois(
      as.formula( paste0( .x, " ~ adj_lights | seg_id + ym" ) )
      ,data = analysis_df
      ,vcov = ~seg_id
      )
    ) %>%
    set_names( vars )

# Day time data set.
models_day <-
  purrr::map(
    paste0( vars, "_day")
    ,~ fixest::fepois(
      as.formula( paste0( .x, " ~ adj_lights | seg_id + ym" ) )
      ,data = analysis_df
      ,vcov = "hetero"
    )
  ) %>%
  set_names( paste0( vars, "_day") )

# Night time data set.
models_night <-
  purrr::map(
    paste0( vars, "_night")
    ,~ fixest::fepois(
      as.formula( paste0( .x, " ~ adj_lights | seg_id + ym" ) )
      ,data = analysis_df
      ,vcov = "hetero"
    )
  ) %>%
  set_names( paste0( vars, "_night") )
# ----

#######################
# Export HTML tables. #
#######################
# ----

# Save table as CSV.
table4 <- 
  dplyr::bind_rows(
    
    purrr::map(
      .x = models_all
      ,~data.frame(
        Coeff = exp( coef( .x ) )
        ,SE = .x$se[[1]]
        ,`Ave. Dep` =mean( dplyr::pull( analysis_df[ fixest::obs( .x ), names( fixest::fixest_data( .x ) )[[3]] ] ) )
        ,N = nobs( .x )
        )
      ) %>%
      dplyr::bind_rows() %>%
      t() %>%
      as.data.frame() %>%
      tibble::rownames_to_column() %>%
      dplyr::mutate( dataset = "Lights" )
    
    ,purrr::map(
      .x = models_day
      ,~data.frame(
        Coeff = exp( coef( .x ) )
        ,SE = .x$se[[1]]
        ,`Ave. Dep` =mean( dplyr::pull( analysis_df[ fixest::obs( .x ), names( fixest::fixest_data( .x ) )[[3]] ] ) )
        ,N = nobs( .x )
      )
      ) %>%
      dplyr::bind_rows() %>%
      t()%>%
      as.data.frame()%>%
      tibble::rownames_to_column() %>%
      dplyr::mutate( dataset = "Day: Lights" )
    
    ,purrr::map(
      .x = models_night
      ,~data.frame(
        Coeff = exp( coef( .x ) )
        ,SE = .x$se[[1]]
        ,`Ave. Dep` =mean( dplyr::pull( analysis_df[ fixest::obs( .x ), names( fixest::fixest_data( .x ) )[[3]] ] ) )
        ,N = nobs( .x )
      )
      ) %>%
      dplyr::bind_rows() %>%
      t() %>%
      as.data.frame()%>%
      tibble::rownames_to_column() %>%
      dplyr::mutate( dataset = "Night: Lights" ) 
  
  )  %>%
    `colnames<-`( c( "term", vars, "dataset" ) ) %>%
  dplyr::relocate( dataset, .before = term )

write.csv( table4, file.path( output_tables_folder, "Table_4_street_analysis.csv" ) )

# Format as gt table.
my_rows <- c( 0, 4, 8 )
gt_table4 <-
  table4 %>%
  gt::gt( groupname_col = "dataset" ) %>%
  gt::cols_align(
    align = "left"
    ,columns = term
  ) %>%
  gt::fmt( fns = function(x) { round( x, 3 ) } ,columns = where( is.numeric ) ,rows = 1+my_rows ) %>%
  gt::fmt( fns = function(x) { round( x, 5 ) } ,columns = where( is.numeric ) ,rows = 2+my_rows ) %>%
  gt::fmt( fns = function(x) { round( x, 4 ) } ,columns = where( is.numeric ) ,rows = 3+my_rows ) %>%
  gt::fmt( fns = function(x) { round( x, 0 ) } ,columns = where( is.numeric ) ,rows = 4+my_rows ) %>%
  gt::tab_header(
    title = "Table 4. Effects of changes in lights on crime in adjacent versus nonadjacent street segments. All."
  ) %>%
  gt::tab_source_note(
    source_note = "Block and year-month fixed effects."
  )
rm(my_rows)
# Save table as HTML.
gt::gtsave( gt_table4, file.path( output_tables_folder ,"/Table_4_street_analysis.html" ) )



# ----