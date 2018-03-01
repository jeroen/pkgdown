#' @importFrom magrittr %>%
#' @importFrom roxygen2 roxygenise
#' @importFrom R6 R6Class
#' @import rlang
NULL

inst_path <- function() {
  if (is.null(pkgload::dev_meta("pkgdown"))) {
    # pkgdown is probably installed
    system.file(package = "pkgdown")
  } else {
    # pkgdown was probably loaded with devtools
    file.path(getNamespaceInfo("pkgdown", "path"), "inst")
  }
}

set_contains <- function(haystack, needles) {
  all(needles %in% haystack)
}

mkdir <- function(..., quiet = FALSE) {
  path <- file.path(...)

  if (!file.exists(path)) {
    if (!quiet)
      cat_line("Creating '", path, "/'")
    dir.create(path, recursive = TRUE, showWarnings = FALSE)
  }
}

out_path <- function(path, ...) {
  if (is.null(path)) {
    ""
  } else {
    file.path(path, ...)
  }

}

is_dir <- function(x) file.info(x)$isdir

split_at_linebreaks <- function(text) {
  if (length(text) < 1)
    return(character())
  trimws(strsplit(text, "\\n\\s*\\n")[[1]])
}

up_path <- function(depth) {
  paste(rep.int("../", depth), collapse = "")
}

print_yaml <- function(x) {
  structure(x, class = "print_yaml")
}
#' @export
print.print_yaml <- function(x, ...) {
  cat(yaml::as.yaml(x), "\n", sep = "")
}

copy_dir <- function(from, to, exclude_matching = NULL) {

  from_dirs <- list.dirs(from, full.names = FALSE, recursive = TRUE)
  from_dirs <- from_dirs[from_dirs != '']

  if (!is.null(exclude_matching)) {
    exclude <- grepl(exclude_matching, from_dirs)
    from_dirs <- from_dirs[!exclude]
  }

  to_dirs <- file.path(to, from_dirs)
  purrr::walk(to_dirs, mkdir)

  from_files <- list.files(from, recursive = TRUE, full.names = TRUE)
  from_files_rel <- list.files(from, recursive = TRUE)

  if (!is.null(exclude_matching)) {
    exclude <- grepl(exclude_matching, from_files_rel)

    from_files <- from_files[!exclude]
    from_files_rel <- from_files_rel[!exclude]
  }

  to_paths <- file.path(to, from_files_rel)
  file.copy(from_files, to_paths, overwrite = TRUE)
}


find_first_existing <- function(path, ...) {
  paths <- file.path(path, c(...))
  for (path in paths) {
    if (file.exists(path))
      return(path)
  }

  NULL
}

#' Compute relative path
#'
#' @param path Relative path
#' @param base Base path
#' @param windows Whether the operating system is Windows. Default value is to
#'   check the user's system information.
#' @export
#' @examples
#' rel_path("a/b", base = "here")
#' rel_path("/a/b", base = "here")
rel_path <- function(path, base = ".", windows = on_windows()) {
  if (is_absolute_path(path)) {
    path
  } else {
    if (base != ".") {
      path <- file.path(base, path)
    }
    # normalizePath() on Windows expands to absolute paths,
    # so strip normalized base from normalized path
    if (windows) {
      parent_full <- normalizePath(".", mustWork = FALSE, winslash = "/")
      path_full <- normalizePath(path, mustWork = FALSE, winslash = "/")
      gsub(paste0(parent_full, "/"), "", path_full, fixed = TRUE)
    } else {
      normalizePath(path, mustWork = FALSE)
    }
  }
}

on_windows <- function() {
  Sys.info()["sysname"] == "Windows"
}

is_absolute_path <- function(path) {
  grepl("^(/|[A-Za-z]:|\\\\|~)", path)
}

package_path <- function(package, path) {
  if (!requireNamespace(package, quietly = TRUE)) {
    stop(package, " is not installed", call. = FALSE)
  }

  pkg_path <- system.file("pkgdown", path, package = package)
  if (pkg_path == "") {
    stop(package, " does not contain 'inst/pkgdown/", path, "'", call. = FALSE)
  }

  pkg_path

}

out_of_date <- function(source, target) {
  if (!file.exists(target))
    return(TRUE)

  if (!file.exists(source)) {
    stop("'", source, "' does not exist", call. = FALSE)
  }

  file.info(source)$mtime > file.info(target)$mtime
}


read_file <- function(path) {
  lines <- readLines(path, warn = FALSE)
  paste0(lines, "\n", collapse = "")
}

write_yaml <- function(x, path) {
  write_utf8(yaml::as.yaml(x), "\n", path = path, sep = "")
}

invert_index <- function(x) {
  stopifnot(is.list(x))

  if (length(x) == 0)
    return(list())

  key <- rep(names(x), purrr::map_int(x, length))
  val <- unlist(x, use.names = FALSE)

  split(key, val)
}

a <- function(text, href) {
  ifelse(is.na(href), text, paste0("<a href='", href, "'>", text, "</a>"))
}

write_utf8 <- function(..., path, sep = "") {
  file <- file(path, open = "w", encoding = "UTF-8")
  on.exit(close(file))
  cat(..., file = file, sep = sep)
}

# Used for testing
#' @keywords internal
#' @importFrom MASS addterm
#' @export
MASS::addterm

rstudio_save_all <- function() {
  if (rstudioapi::hasFun("documentSaveAll")) {
    rstudioapi::documentSaveAll()
  }
}

cat_line <- function(...) {
  cat(..., "\n", sep = "")
}

rule <- function(...) cli::cat_rule(..., col = "green")

list_with_heading <- function(bullets, heading) {
  if (length(bullets) == 0)
    return(character())

  paste0(
    "<h2>", heading, "</h2>",
    "<ul class='list-unstyled'>\n",
    paste0("<li>", bullets, "</li>\n", collapse = ""),
    "</ul>\n"
  )
}
