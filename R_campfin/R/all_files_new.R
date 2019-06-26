all_files_new <- function(path = ".", pattern = NULL) {
  is_new <- Sys.Date() == as.Date(
    file.mtime(
      list.files(
        path = path,
        pattern = pattern,
        full.names = TRUE,
      )
    )
  )
  if (!is_empty(is_new)) {
    all(is_new)
  } else {
    !is_empty(is_new)
  }
}
