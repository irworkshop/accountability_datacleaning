all_files_new <- function(path = ".", pattern = NULL) {
  all(
    Sys.Date() ==
      as.Date(
        file.mtime(
          list.files(
            path = path,
            pattern = pattern,
            full.names = TRUE,
          )
        )
      )
  )
}
