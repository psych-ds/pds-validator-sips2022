get_pds_dir <- function(pds_dir) {
  pds_object = pds_dir
  pds_object$directory = pds_dir
  pds_object$json_file = list.files(pds_dir, pattern = "dataset_description.json")
  pds_object$data_files = list.files(paste0(pds_dir,"/data/"), 
                          recursive = TRUE)
  pds_object$csv_files = list.files(paste0(pds_dir,"/data/"), 
                         pattern = "*\\.csv$", 
                         recursive = TRUE)
  
  #Key_value pattern: Any non-stinky directory path, followed by (key-value_)*data.csv
  filename_pattern <- "^([A-z0-9]+\\/)*([A-z0-9]+\\-[A-z0-9]+)+\\_data\\.csv$"
  
  #Split CSV into matching and nonmatching filenames
  pds_object$matching_filenames = na.omit(str_extract(pds_object$csv_files, filename_pattern))
  pds_object$non_matching_filenames = setdiff(pds_object$csv_files, pds_object$matching_filenames)
  
  #For compliant filenames only, check validity of CSV files. 
  pds_object$matching_filepaths = paste0(pds_object$directory, 
                                         "/data/",
                                         pds_object$matching_filenames)
  
  return(pds_object)
}

get_pds_with_csv <- function(pds_dir) {  
  pds_object = get_pds_dir(pds_dir)
  
  for(mf in 1:length(pds_object$matching_filepaths)){
    this_header = read_delim(pds_object$matching_filepaths[mf],
                           col_names = TRUE, 
                           n_max = 1,
                           delim = ",",
                           progress = FALSE,
                           show_col_types = FALSE,
                           name_repair = "minimal")
    
    header_problems = if_else(nrow(problems(this_header)) == 0,
                            "\nSUCCESS: Parsed header (first row)",
                            "\nWARNING: Problem parsing header (first row)")
    header_valid = nrow(problems(this_header)) == 0
    
    this_body = read_delim(pds_object$matching_filepaths[mf],
                         col_names = FALSE, 
                         skip = 1,
                         n_max = 1,
                         delim = ",",
                         progress = FALSE,
                         show_col_types = FALSE)
    
    body_problems = if_else(nrow(problems(this_body)) == 0,
                            "\nSUCCESS: Parsed body (rows 2+) as table",
                            "\nWARNING: Problem parsing body (rows 2+) as table")
    body_valid = nrow(problems(this_body)) == 0
    
    structure_problems = if_else(length(this_header) == length(this_body),
                                 "\nSUCCESS: Number of header labels matches number of body columns",
                                 paste0("\nWARNING: Number of header labels does not match number of body columns:",
                                        "\n\t",
                                        length(this_header),
                                        " columns in header and ",
                                        length(this_body),
                                        " columns in body"))
    structure_valid = length(this_header) == length(this_body)
    
    names_valid_list = na.omit(str_extract(names(this_header), ".+")) #Get nonzero column names!
    names_valid_list = unique(names_valid_list) # Get unique column names!
    names_problems = if_else(length(names_valid_list) == length(names(this_header)),
                          "\nSUCCESS: Column names are unique and non-blank",
                          paste0("\nWARNING: Found non-unique or blank column names",
                          "\n\t Column names: '",
                          str_flatten(names(this_header), collapse = "', '"),
                          ","
                            ))
    names_valid = length(names_valid_list) == length(names(this_header))
    
    
    pds_object$csv_valid[mf] = header_valid & body_valid & names_valid & structure_valid
    
    pds_object$csv_names[mf] = names(this_header)
    
    pds_object$csv_report[mf] = paste0("\nValidating file...\n",
                                       pds_object$matching_filenames[mf],
                                       header_problems, 
                                       body_problems,
                                       names_problems,
                                       structure_problems,
                                       "\nFile validated: ",
                                       pds_object$csv_valid[mf],
                                       "\n\n")
  
  }
  return(pds_object)
}

get_pds_with_json <- function(pds_dir) {  
  pds_object = get_pds_dir(pds_dir)

  dataset_desc <- read_file(paste0(pds_dir, "/dataset_description.json"))
  pds_object$valid_dataset_json = FALSE
  pds_object$dataset_description <- parse_json(dataset_desc) #An error may occur here! Hacky handling, wow.
  pds_object$valid_dataset_json = TRUE
  pds_object$json_string = toJSON(pds_object$dataset_description)
  
  return(pds_object)

}

get_validated_names <- function(pds_object) {  
  all_names = c()
  for(mf in 1:length(pds_object$matching_filepaths)){
    if(pds_object$csv_valid[mf]){
      should_be_valid = read_delim(pds_object$matching_filepaths[mf],
                                   col_names = TRUE, 
                                   n_max = 10,
                                   delim = ",",
                                   progress = FALSE,
                                   show_col_types = FALSE,
                                   name_repair = "minimal")
      
     all_names = c(all_names, names(should_be_valid))
    }
  }
  return(unique(all_names))
}

