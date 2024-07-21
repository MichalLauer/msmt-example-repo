read_data <- function(file) {
  sheets <- excel_sheets(file)

  data <-
    future_map(sheets, function(sheet) {
      read_excel(path = file,
                 sheet = sheet,
                 col_types = "text")
    }) |>
    bind_rows_fast()


  return(data)
}