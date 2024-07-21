library(glue)
library(purrr)
library(furrr)
library(stringr)
library(rvest)
library(httr)

download_data <- function(path = "data-downloaded", from = 2015, to = NULL,
                          report = NULL)  {

  # to <- to %||% 2023
  to <- if (is.null(to)) 2023 else to

  downloaded <-
    seq(from = from, to = to) |>
    future_map(\(year) .download_year(path=path, year=year, report=report)) |>
    reduce(c) |>
    na.omit()

  return(downloaded)
}

.download_year <- function(path, year, report) {
  base_url <- "https://dsia.msmt.cz/vystupy/region/vu_region"
  down_url <- "https://dsia.msmt.cz/vystupy/region"
  down_path <- glue("{path}/{year}")
  if (!dir.exists(down_path)) {
    dir.create(down_path, recursive = T)
  }

  links <-
    glue("{base_url}{year}.html") |>
    read_html() |>
    html_elements(css = "td a") |>
    html_attr("href") |>
    str_subset("\\.xlsx?$") |>
    (function(l) {
      if (is.null(report)) {
        return(l)
      } else {
        i <-
          l |>
          basename() |>
          str_extract("^.{3}") |>
          str_detect(report)

        return(l[i])
      }
    })()

  downloaded <-
    future_map_chr(links, .f = function(location) {
      url <- glue("{down_url}/{location}")
      dest <- glue("{down_path}/{str_remove(location, 'data/')}")

      if (file.exists(dest)) {
        return(dest)
      }

      req <- GET(url)

      if (status_code(req) == 200) {
        download.file(url = url, destfile = dest, mode = "wb", quiet = TRUE)
        return(dest)
      } else {
        cli::cli_alert_warning("'{location}' nelze stáhnout.")
        cli::cli_alert_warning("url: '{url}'.")
        cli::cli_alert_warning("error: '{http_status(req)$message}'.")
        return(NA)
      }
    })

  return(downloaded)
}