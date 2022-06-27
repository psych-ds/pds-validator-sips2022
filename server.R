library(shiny)
library(shinyFiles)
library(fs)
library(tidyverse)
library(jsonlite)

source("common.R")

shinyServer(function(input, output, session) {
  volumes <- c(Home = fs::path_home(), "R Installation" = R.home(), getVolumes()())
  
  shinyDirChoose(input, "directory", 
                 roots = volumes,
                 session = session, allowDirCreate = FALSE)
  
  
  observe({
    cat("\ninput$directory value:\n\n")
    print(input$directory)
  })
  
  output$directorypath <- renderPrint({
    if (is.integer(input$directory)) {
      cat("No directory has been selected")
    } else {
      pds_dir = parseDirPath(volumes, input$directory)
      pds_object = get_pds_dir(pds_dir)
      print(pds_object$directory)
    }
  })
  
  output$dir_findjson <- renderPrint({
    if (is.integer(input$directory)) {
      cat("")
    } else {
      pds_dir = parseDirPath(volumes, input$directory)
      pds_object = get_pds_dir(pds_dir)
      
      #Check for dataset_description.json
      if(length(pds_object$json_file) < 1){
        cat("WARNING: No file named `dataset_description.json` in this folder")
        
      } else{
        cat('SUCCESS: Found dataset_description.json')
      }
  

    }
  })
  
  output$dir_finddata <- renderPrint({
    if (is.integer(input$directory)) {
      cat("")
    } else {
      pds_dir = parseDirPath(volumes, input$directory)
      pds_object = get_pds_dir(pds_dir)
      
      #Check for data subfolder
      if(length(pds_object$data_files) < 1){
        cat("WARNING: No data subfolder found")
        
      } else{
        cat("SUCCESS: Found data subfolder")
      }
    }
  })
  
  output$files_noncsv <- renderPrint({
    if (is.integer(input$directory)) {
      cat("")
    } else {
      pds_dir = parseDirPath(volumes, input$directory)
      pds_object = get_pds_dir(pds_dir)
      
      #CHeck for non-csv files
      if(length(pds_object$data_files) > length(pds_object$csv_files)){
        cat("WARNING: Found non-CSV files:\n\n")
        cat(setdiff(pds_object$data_files, pds_object$csv_files))
        
      } else{
        cat("SUCCESS: Only CSV files found")
      }
    }
    
  })
  
  
  output$csv_names <- renderPrint({
    if (is.integer(input$directory)) {
      cat("")
    } else {
      pds_dir = parseDirPath(volumes, input$directory)
      pds_object = get_pds_dir(pds_dir)
      
      if(length(pds_object$non_matching_filenames) > 0){
        cat("WARNING: The following CSV filenames don't match the Psych-DS pattern:\n\n")
        cat(pds_object$non_matching_filenames)
        
      } else{
        cat("SUCCESS: All CSV names follow the Psych-DS pattern")
      }
        
    }
    
  })
  
  output$testable_csv <- renderPrint({
    if (is.integer(input$directory)) {
      cat("")
    } else {
      pds_dir = parseDirPath(volumes, input$directory)
      pds_object = get_pds_dir(pds_dir)
      
      #List all filenames matching the full _data.csv pattern
      match_list = str_flatten(na.omit(pds_object$matching_filenames), collapse = "\n")
      
      cat(match_list)
    }
    
  })
  
  output$csv_valid <- renderPrint({
    if (is.integer(input$directory)) {
      cat("")
    } else {
      pds_dir = parseDirPath(volumes, input$directory)
      pds_object = get_pds_with_csv(pds_dir)
      cat(pds_object$csv_report)
    }
  })
    
  output$sanity_check <- renderPrint({
    if (is.integer(input$directory)) {
      cat("")
    } else {
      pds_dir = parseDirPath(volumes, input$directory)
      pds_object = get_pds_with_csv(pds_dir)
      n_valid_files = sum(pds_object$csv_valid)
      n_matching_filepaths = length(pds_object$matching_filepaths)
      n_nonmatching_csv = length(pds_object$non_matching_filenames)
      n_data_files = length(pds_object$data_files)
      
      cat(paste0("Successfully validated ", n_valid_files, " of ", 
                 n_matching_filepaths, " CSV files with valid filenames. \nData folder also contains: \n",
                 n_nonmatching_csv,
                 " CSV files with invalid filenames.\n", 
                 n_data_files - (n_matching_filepaths + n_nonmatching_csv), 
                 " non-CSV files found in the data folder.\n\n"))
      
      for(mf in 1:length(pds_object$matching_filepaths)){
        if(pds_object$csv_valid[mf]){
          cat(pds_object$matching_filenames[mf])
          cat("\n\n")
          should_be_valid = read_delim(pds_object$matching_filepaths[mf],
                                       col_names = TRUE, 
                                       n_max = 10,
                                       delim = ",",
                                       progress = FALSE)
          
          print(should_be_valid)
          cat("\n\n")
        } else {
          cat("")
        }
      }
    }
      
  })
  
  
  output$json_valid <- renderPrint({
    if (is.integer(input$directory)) {
      cat("")
    } else {
      pds_dir = parseDirPath(volumes, input$directory)
      pds_object = get_pds_with_json(pds_dir)
      
      cat(pds_object$valid_dataset_json)
    }
    
  })
  
  output$json_string <- renderPrint({
    if (is.integer(input$directory)) {
      cat("")
    } else {
      pds_dir = parseDirPath(volumes, input$directory)
      pds_object = get_pds_with_json(pds_dir)
      
      cat(pds_object$json_string)
    }
    
  })
  
  output$json_contents <- renderPrint({
    if (is.integer(input$directory)) {
      cat("")
    } else {
      pds_dir = parseDirPath(volumes, input$directory)
      pds_object = get_pds_with_json(pds_dir)
      
      if(pds_object$valid_dataset_json){
        variable_list = str_flatten(pds_object$dataset_description$variableMeasured, collapse = ", ")
        
        cat(paste0("Information about '",
                   pds_object$dataset_description$name,
                   "':\n",
                   "What is this dataset about? ",
                   pds_object$dataset_description$description,
                   "\n\n",
                   "Here is the list of variables in this dataset (according to the metadata file!!): \n",
                   variable_list))

      }
    }
    
  })
  
output$variable_report <- renderPrint({
    if (is.integer(input$directory)) {
      cat("")
    } else {
      pds_dir = parseDirPath(volumes, input$directory)
      pds_object_json = get_pds_with_json(pds_dir)
      pds_object_csv = get_pds_with_csv(pds_dir)
      
      json_variable_list = unlist(pds_object_json$dataset_description$variableMeasured)
      csv_variable_list = get_validated_names(pds_object_csv)
      
      cat("Variables listed in both places (Success!)\n")
      cat(intersect(csv_variable_list,json_variable_list))
      if(length(setdiff(json_variable_list, csv_variable_list))> 0){
        cat("\n\nVariables listed in the dataset description, but not found in any data file:\n")
        cat(setdiff(json_variable_list, csv_variable_list))
      }
      if(length(setdiff(csv_variable_list,json_variable_list))> 0){
        cat("\n\nVariables found in a validated data file, but not listed in the dataset description:\n")
        cat(setdiff(csv_variable_list,json_variable_list))
      }

      
    }
    
  })
  
  

  
})