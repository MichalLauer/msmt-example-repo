bind_rows_fast <- function(x) {
  if (!is.list(x)) {
    x <- list(x)
  }

  r <-
    x |>
    map(as.data.table) |>
    rbindlist(fill = TRUE) |>
    as_tibble()

  return(r)
}