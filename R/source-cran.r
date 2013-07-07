#' Package source: CRAN
#' 
#' @param type package type to try, \code{"binary"} or \code{"source"}.
#' @param repos URL to repository. If not set, will default to the Rstudio
#'   cloud mirror.
#' @export
#' @examples
#' cran("binary")
#' cran("source")
cran <- function(type = "binary", repos = getOption("repos")) {
  assert_that(is.string(type))
  
  type <- match.arg(type, c("binary", pkg_types))
  
  if (type == "binary") {
    type <- binary_type()
  }
  if (type == "source" && !has_dev_env()) {
    stop("Source type requested but development environment not found", 
         call. = FALSE)
  }
  assert_that(is.string(repos))
  
  if ("@CRAN@" %in% repos) {
    message("No default mirror specified: using Rstudio cloud mirror")
    repos <- "http://cran.rstudio.com"
  }
  
  url <- contrib.url(repos[[1]], type)
  source("cran", url = url)
}

#' @S3method print cran
print.cran <- function(x, ...) {
  cat("<Source> CRAN: ", x$url, "\n", sep = "")
}

binary_type <- function() {
  type <- .Platform$pkgType
  if (type == "source") {
    stop("Binary packages not available on your platform", call. = FALSE)    
  }
  type
}

has_dev_env <- function() {
  all(Sys.which(c("gcc", "ls")) != "")
}

pkg_types <- c("win.binary", "mac.binary", "source")

#' @S3method package_info cran
package_info.cran <- function(source, package) {
  packages <- packages_gz(source$url)
  info <- packages[packages$Package == package, ]
  if (nrow(info) != 1) return(NULL)
  
  as.list(info)
}

#' @importFrom digest digest
packages_gz <- function(url) {
  base_path <- file.path(tempdir(), digest(url))
  
  # Download complete .gz file if needed
  path_gz <- paste0(base_path, ".gz")
  if (!file.exists(path_gz)) {
    download.file(url, path_gz, quiet = TRUE)  
  }
  
  # Cache as rds file
  path_rds <- paste0(base_path, ".rds")
  if (!file.exists(path_rds)) {
    packages <- as.data.frame(read.dcf(path_gz), stringsAsFactors = FALSE)
    saveRDS(packages, path_rds)
    packages
  } else {
    readRDS(path_rds)
  }
}



#' @export
offline_packages <- function() {
  types <- c("source", "win.binary", "mac.binary")
  for (type in types) {
    url <- cran(type)$url
    dest <- paste0(tempdir(), "/", digest(url), ".gz")
    src <- system.file("extdata", paste0("packages-", type, ".gz"), package = "packman")
    
    file.copy(src, dest)
  }
}