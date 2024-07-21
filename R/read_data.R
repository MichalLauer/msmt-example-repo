read_data <- function(file) {
  sheets <- excel_sheets(file)

  data <-
    future_map(sheets, function(sheet) {
      read_excel(path = file,
                 sheet = sheet,
                 col_types = "text")
    }) |>
    map(as.data.table) |>
    rbindlist(fill = T) |>
    as_tibble()


  return(data)
}