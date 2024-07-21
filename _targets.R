library(targets)
library(tarchetypes)

invisible(lapply(X = list.files(path = "R/", full.names = T), FUN = source))
plan(multisession, workers = availableCores() - 1)

tar_option_set(
  packages = c("dplyr", "rvest", "stringr", "purrr", "furrr", "glue", "readxl",
               "data.table"),
  resources = tar_resources(
    parquet = tar_resources_parquet()
  )
)

file_paths <- download_data(from = 2016, to = 2020, report = "(M08)|(M03)")
reports <- c("M08", "M03")

tgt_raw_single <-
  tar_map(
    values = list(
      file_path = file_paths,
      names = tools::file_path_sans_ext(basename(file_paths))
    ),
    tar_file(path, file_path),
    tar_target(raw, read_data(path)),
    names = names,
    unlist = T
  )

tgt_raw <-
  future_map(reports, function(report) {
    id <- glue("raw_{report}")
    names <- tar_select_names(tgt_raw_single, starts_with(id))
    targets <- tgt_raw_single[names]

    tar_combine_raw(
      id,
      targets,
      command = expression( map(list(!!!.x), as.data.table)|> rbindlist(fill = TRUE) )
    )
  })

list(
  tgt_raw_single,
  tgt_raw
)
