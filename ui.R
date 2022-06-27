library(shiny)
library(shinyFiles)
library(stringr)

source("common.R")

if (require(bslib)) {
  theme <- bslib::bs_theme(version = 4)
} else {
  theme <- NULL
}

fluidPage(
  theme = theme, 
  headerPanel(
    "Psych-DS Directory Checker"
  ),
  sidebarLayout(
    sidebarPanel(
      tags$p(HTML("<i>Hint: Use the <b>left</b> column of the menu that pops up to find your project folder! The right column in the dialog window isn't clickable.</i>")),
      shinyDirButton("directory", "Choose directory to validate", "Please select a folder"),
      tags$hr(),
      tags$p(HTML("To download datasets to test out this tool, go <a href ='https://github.com/psych-ds/example-datasets'>here</a>.")),
      tags$p(HTML("<a href = 'https://github.com/psych-ds/example-datasets/tree/master/template-dataset'>This</a> is a template project that passes validation but has very little content. It's a good place to start if you want to create your own directory with some structure to start you off.")),
      tags$p(HTML("<a href = 'https://github.com/psych-ds/example-datasets/tree/master/informative-mistakes-dataset'>This</a> is a project folder with some intentional, hopefully informative, mistakes in it.")),
      ),
  
    mainPanel(
      tags$p(HTML("This is a preliminary tool for <a href='https://psych-ds.github.io/'>Psych-DS</a>, created for the <a href='https://docs.google.com/document/d/1K7WFndgkXZBqDuWWqBU0ZakgbS_NErl0zVyMApCwDjk/edit#'>2022 SIPS hackathon</a>. It is a super preliminary prototype! Known limitations include: 
                  <ul>
                  <li>Not tested on datasets with large or numerous data files</li>
                  <li>No support for sidecar JSON files</li>
                  <li>No support for rich variableMeasured values - names/strings only</li>
                  </ul>")),
      tags$p(HTML("<b>HOW TO USE</b>: After following <a href='https://docs.google.com/document/d/1k3ZzAF8vrJeIcMN3q5g_l7WJtoybokvq5ueYVH0dcC8/edit#heading=h.w84ev4cs0qo7'>these instructions to create a Psych-DS directory</a> on your computer, select your project folder in the sidebar to check whether it meets the Psych-DS specification. Output will appear below. Start from the first check, and keep modifying your project directory until all checks pass.")),
      tags$p(HTML("Please share feedback about this tool in the How-To google doc!")),
      tags$hr(),

      tags$h4("Psych-DS Directory Structure"),
      tags$p("Selected directory:"),
      verbatimTextOutput("directorypath"),
      tags$p("The Psych-DS directory should contain a 'dataset_description.json' file and a subfolder named 'data':"),
      verbatimTextOutput("dir_findjson"),
      verbatimTextOutput("dir_finddata"),
      tags$hr(),
      
      tags$p("Psych-DS expects to find only CSV files inside the data/ folder. You may include subfolders inside the data folder; files anywhere inside data/ will be searched."),
      verbatimTextOutput("files_noncsv"),
      
      tags$p("Check the naming structure of all CSV files. The expected pattern is 'key-value_key-value_data.csv', e.g. 'study-marbletest_sub-15_data.csv'"),
      verbatimTextOutput("csv_names"),
      
      tags$p("The remaining CSV files will be validated against the rest of the Psych-DS specification."),
      verbatimTextOutput("testable_csv"),
      tags$hr(),
      
      tags$h4("Psych-DS File Structure"),
      tags$p("This app implements limited file validation, and many edge cases have not been tested. For now, the app verifies whether the file is a parse-able CSV with unique, non-blank column names in the first row of the file."),
      verbatimTextOutput("csv_valid"),
      
      tags$p("This shiny app is an EARLY PROTOTYPE! Make sure to inspect your data files visually. This tool should be able to read in and display any CSV files that passed validation above: "),
      verbatimTextOutput("sanity_check"),
      tags$hr(),
      
      tags$h4("Psych-DS Metadata structure"),
      
      tags$p(HTML("If you are happy with the structure of your data files, it's time to check the metadata.")),
      tags$p(HTML("Machine-readable metadata is what makes Psych-DS a powerful tool for FAIR data sharing[LINK]. This tool uses only some of the potential of JSON-LD metadata, kust to demonstrate the advantages of a machine-readable specification!")),
      
      tags$p("First, check whether we can read & parse the JSON file: "),
      verbatimTextOutput("json_valid"),
      
      tags$p(HTML("Your dataset_description.json file needs to be not just any legal JSON object, but a <a href = 'https://schema.org/Dataset'>Schema.org Dataset</a>. To find out if your JSON file meets those requirements, copy the text below and paste it into the 'code snippet' box at <a href = 'https://validator.schema.org/'>this link.</a>")),
      verbatimTextOutput("json_string"),
      
      tags$p(HTML("<i>(Note: A limitation of this tool is that we can only take advantage of string values for variableMeasured. You may see weird results below if you use PropertyValue objects.)</i>" )),
      
      tags$p("If your file validates as a Schema.org Dataset, the Psych-DS validator should be able to interpret the information inside!"),
      verbatimTextOutput("json_contents"),
      
      tags$p("The final requirement of Psych-DS implemented here is for the metadata you provide to correctly correspond to the data in the data/ folder. For now, we just check whether the variables listed in the metadata match those in your data file: "),
      
      verbatimTextOutput("variable_report"),
      
      tags$p(HTML("This is the end of the Psych-DS checker prototype! Thanks for trying it out and please share your results and any questions in the <a href = 'https://docs.google.com/document/d/1k3ZzAF8vrJeIcMN3q5g_l7WJtoybokvq5ueYVH0dcC8/edit#heading=h.w84ev4cs0qo7'>How-To google doc</a>."))
      
    )
  )
)