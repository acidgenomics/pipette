#' Import
#'
#' Read file by extension into R.
#'
#' [import()] supports automatic loading of common file types, by wrapping
#' popular importer functions. It intentionally designed to be simple, with few
#' arguments. Remote URLs and compressed files are supported. If you need more
#' complex import settings, just call the wrapped importer directly instead.
#'
#' @section Row and column names:
#'
#' **Row names.** Row name handling has become an inconsistent mess in R because
#' of differential support in base R, tidyverse, data.table, and Bioconductor.
#' To maintain sanity, [import()] attempts to handle row names automatically.
#' The function checks for a `rowname` column in delimited data, and moves these
#' values into the object's row names, if supported by the return type (e.g.
#' `data.frame`, `DataFrame`). Note that `tbl_df` (tibble) and `data.table`
#' intentionally do not support row names. When returning in this format, no
#' attempt to assign the `rowname` column into the return object's row names is
#' made. Note that [import()] is strict about this matching and only checks for
#' a `rowname` column, similar to the default syntax recommended in
#' [tibble::rownames_to_column()]. To disable this behavior, set
#' `rownames = FALSE`, and no attempt will be made to set the row names.
#'
#' **Column names.** [import()] assumes that delimited files always contain
#' column names. If you are working with a file that doesn't contain column
#' names, either set `colnames = FALSE` or pass the names in as a `character`
#' vector. It's strongly recommended to always define column names in a
#' supported file type.
#'
#' @section Data frame return:
#'
#' By default, [import()] returns a standard `data.frame` for delimited/column
#' formatted data. However, any of these desired output formats can be set
#' globally using `options(acid.data.frame = "data.frame")`.
#'
#' Supported return types:
#'
#' - `data.frame`: Base R default. Generally recommended.
#'   - S3 class.
#'   - Allows rownames, but they're required and can't be set `NULL`.
#'   - See `help(topic = "data.frame", package = "base")` for details.
#' - `DataFrame`: Recommended when working with Bioconductor packages.
#'   - S4 class.
#'   - Allows rownames, but they're optional and can be set `NULL`.
#'   - See `help(topic = "DataFrame", package = "S4Vectors")` for details.
#' - `tbl_df` (`tibble`): Recommended when working with tidyverse packages.
#'   - S3 class; inherits `data.frame`.
#'   - Does not allow rownames.
#'   - See `help(topic = "tibble", package = "tibble")` for details.
#' - `data.table`: Recommended when working with the data.table package.
#'   - S3 class; inherits `data.frame`.
#'   - Does not allow rownames.
#'   - See `help(topic = "data.table", package = "data.table")` for details.
#'
#' Note that `stringsAsFactors` is always disabled for import.
#'
#' @section Matrix Market Exchange (MTX):
#'
#' Reading a Matrix Market Exchange file requires `ROWNAMES` and `COLNAMES`
#' sidecar files containing the corresponding row and column names of the sparse
#' matrix.
#'
#' @section General feature format (GFF, GTF):
#'
#' The GFF (General Feature Format) format consists of one line per feature,
#' each containing 9 columns of data, plus optional track definition lines. The
#' GTF (General Transfer Format) is identical to GFF version 2.
#'
#' [basejump][] exports the specialized `makeGRangesFromGFF()` function that
#' makes GFF loading simple.
#'
#' See also:
#'
#' - [Ensembl spec](http://www.ensembl.org/info/website/upload/gff.html)
#' - [GENCODE spec](http://www.gencodegenes.org/gencodeformat.html)
#'
#' [basejump]: https://basejump.acidgenomics.com/
#'
#' @section Gene sets (GMT, GMX):
#'
#' Refer to the Broad Institute [GSEA wiki][] for details.
#'
#' [GSEA wiki]: https://goo.gl/3ZkDPb
#'
#' @section bcbio count matrix:
#'
#' [bcbio][] count matrix and related sidecar files are natively supported.
#'
#' - `COUNTS`: Counts table (e.g. RNA-seq aligned counts).
#' - `COLNAMES`: Sidecar file containing column names.
#' - `ROWNAMES`: Sidecar file containing row names.
#'
#' [bcbio]: https://bcbio-nextgen.readthedocs.io/
#'
#' @section Denylisted extensions:
#'
#' These file formats are intentionally not supported:
#' `DOC`, `DOCX`, `PDF`, `PPT`, `PPTX`.
#'
#' @export
#' @note Updated 2021-03-04.
#'
#' @inheritParams AcidRoxygen::params
#' @param format `character(1)`.
#'   An optional file format type, which can be used to override the file format
#'   inferred from `file`. Only recommended for file and URL paths that don't
#'   contain an extension.
#' @param rownames `logical(1)`.
#'   Automatically assign row names, if `rowname` column is defined.
#'   Applies to file types that return `data.frame` only.
#' @param colnames `logical(1)` or `character`.
#'   Automatically assign column names, using the first header row.
#'   Applies to file types that return `data.frame` only.
#'   Pass in a `character` vector to define the column names manually.
#' @param sheet `character(1)` or `integer(1)`.
#'   *Applies to Excel Workbook, Google Sheet, or GraphPad Prism file.*
#'   Sheet to read. Either a string (the name of a sheet), or an integer (the
#'   position of the sheet). Defaults to the first sheet.
#' @param comment `character(1)`.
#'   Comment character to detect at beginning of line, which will skip when
#'   parsing file. Use `""` to disable interpretation of comments, which is
#'   particularly
#'   useful when parsing lines.
#'   *Applies to plain text delimited and source code lines only.*
#' @param skip `integer(1)`.
#'   *Applies to delimited file (CSV, TSV), Excel Workbook, or lines.*
#'   Number of lines to skip.
#' @param nMax `integer(1)` or `Inf`.
#'   Maximum number of lines to parse.
#'   *Applies to plain text delimited, Excel, and source code lines only.*
#' @param makeNames `function`.
#'   Apply syntactic naming function to (column) names.
#'   *Does not apply to import of R data files.*
#'
#' @return Varies, depending on the file type (format):
#'
#' - **Plain text delimited** (`CSV`, `TSV`, `TXT`): `data.frame`.\cr
#'   Data separated by commas, tabs, or visual spaces.\cr
#'   Note that TXT structure is amgibuous and actively discouraged.\cr
#'   Refer to `Data frame return` section for details on how to change the
#'   default return type to `DataFrame`, `tbl_df` or `data.table`.\cr
#'   Imported by [vroom::vroom()].
#' - **Excel workbook** (`XLSB`, `XLSX`): `data.frame`.\cr
#'   Resave in plain text delimited format instead, if possible.\cr
#'   Imported by [readxl::read_excel()].
#' - **Legacy Excel workbook (pre-2007)** (`XLS`): `data.frame`.\cr
#'   Resave in plain text delimited format instead, if possible.\cr
#'   Note that import of files in this format is slow.\cr
#'   Imported by [readxl::read_excel()].
#' - **GraphPad Prism project** (`PZFX`): `data.frame`.\cr
#'   Experimental. Consider resaving in CSV format instead.\cr
#'   Imported by [pzfx::read_pzfx()].
#' - **General feature format** (`GFF`, `GFF1`, `GFF2`, `GFF3`, `GTF`):
#'   `GRanges`.\cr
#'   Imported by [rtracklayer::import()].
#' - **MatrixMarket exchange sparse matrix** (`MTX`): `sparseMatrix`.\cr
#'   Imported by [Matrix::readMM()].
#' - **Gene sets (for GSEA)** (`GMT`, `GMX`): `character`.
#' - **Browser extensible data** (`BED`, `BED15`, `BEDGRAPH`, `BEDPE`):
#'   `GRanges`.\cr
#'   Imported by [rtracklayer::import()].
#' - **ChIP-seq peaks** (`BROADPEAK`, `NARROWPEAK`): `GRanges`.\cr
#'   Imported by [rtracklayer::import()].
#' - **Wiggle track format** (`BIGWIG`, `BW`, `WIG`): `GRanges`.\cr
#'   Imported by [rtracklayer::import()].
#' - **JSON serialization data** (`JSON`): `list`.\cr
#'   Imported by [jsonlite::read_json()].
#' - **YAML serialization data** (`YAML`, `YML`): `list`.\cr
#'   Imported by [yaml::yaml.load_file()].
#' - **Lines** (`LOG`, `MD`, `PY`, `R`, `RMD`, `SH`): `character`.
#'   Source code or log files.\cr
#'   Imported by [`vroom_lines()`][vroom::vroom_lines].
#' - **R data serialized** (`RDS`): *variable*.\cr
#'   Currently recommend over RDA, if possible.\cr
#'   Imported by [`readRDS()`][base::readRDS].
#' - **R data** (`RDA`, `RDATA`): *variable*.\cr
#'   Must contain a single object.
#'   Doesn't require internal object name to match, unlike [loadData()].\cr
#'   Imported by [`load()`][base::load].
#' - **Infrequently used rio-compatible formats** (`ARFF`, `DBF`, `DIF`, `DTA`,
#'   `MAT`, `MTP`, `ODS`, `POR`, `SAS7BDAT`, `SAV`, `SYD`, `REC`, `XPT`):
#'   *variable*.\cr
#'   Imported by [rio::import()].
#'
#' @seealso
#' Packages:
#'
#' - [data.table](http://r-datatable.com/).
#' - [readr](http://readr.tidyverse.org).
#' - [readxl](http://readxl.tidyverse.org).
#' - [rio](https://cran.r-project.org/package=rio).
#' - [rtracklayer](http://bioconductor.org/packages/rtracklayer/).
#' - [vroom](https://vroom.r-lib.org).
#'
#' Import functions:
#'
#' - `data.table::fread()`.
#' - `readr::read_csv()`.
#' - `rio::import()`.
#' - `rtracklayer::import()`.
#' - `utils::read.table()`.
#' - `vroom::vroom()`.
#'
#' @examples
#' file <- system.file("extdata/example.csv", package = "pipette")
#'
#' ## Row and column names enabled.
#' x <- import(file)
#' print(head(x))
#'
#' ## Row and column names disabled.
#' x <- import(file, rownames = FALSE, colnames = FALSE)
#' print(head(x))
import <- function(
    file,
    format = "auto",
    rownames = TRUE,
    colnames = TRUE,
    sheet = 1L,
    comment = "",
    skip = 0L,
    nMax = Inf,
    makeNames,
    metadata,
    quiet
) {
    ## We're supporting remote files, so don't check using `isAFile()` here.
    assert(
        isAFile(file) || isAURL(file),
        isFlag(rownames),
        isFlag(colnames) || isCharacter(colnames),
        isString(format),
        isScalar(sheet),
        is.character(comment) && length(comment) <= 1L,
        isInt(skip), isNonNegative(skip),
        isPositive(nMax),
        is.function(makeNames),
        isFlag(metadata),
        isFlag(quiet)
    )
    format <- tolower(format)
    ## Allow Google Sheets import using rio, by matching the URL.
    ## Otherwise, coerce the file extension to uppercase, for easy matching.
    if (identical(format, "auto") || identical(format, "none")) {
        ext <- str_match(basename(file), extPattern)[1L, 2L]
        if (is.na(ext)) {
            stop(paste(
                "'file' argument does not contain file type extension.",
                "Set the file format manually using the 'format' argument.",
                "Refer to 'pipette::import()' documentation for details.",
                sep = "\n"
            ))
        }
    } else {
        ext <- format
    }
    ext <- tolower(ext)
    ## Check that user hasn't changed unsupported  arguments.
    if (!isSubset(
        x = ext,
        y = c(.extGroup[["delim"]], .extGroup[["excel"]])
    )) {
        assert(
            identical(rownames, eval(formals()[["rownames"]])),
            identical(colnames, eval(formals()[["colnames"]]))
        )
    }
    ## - sheet (excel, prism)
    if (!isSubset(ext, c(.extGroup[["excel"]], "pzfx"))) {
        assert(identical(sheet, eval(formals()[["sheet"]])))
    }
    ## - skip
    if (!isSubset(
        x = ext,
        y = c(.extGroup[["delim"]], .extGroup[["excel"]], .extGroup[["lines"]])
    )) {
        assert(identical(skip, eval(formals()[["skip"]])))
    }
    ## - metadata
    if (isSubset(ext, .extGroup[["lines"]])) {
        assert(identical(metadata, eval(formals()[["metadata"]])))
    }
    ## Now we're ready to hand off to file-type-specific importers.
    args <- list(
        "file" = file,
        "quiet" = quiet
    )
    if (isSubset(ext, .extGroup[["delim"]])) {
        fun <- .importDelim
        args <- append(
            x = args,
            values = list(
                "colnames" = colnames,
                "comment" = comment,
                "ext" = ext,
                "metadata" = metadata,
                "nMax" = nMax,
                "skip" = skip
            )
        )
    } else if (isSubset(ext, .extGroup[["excel"]])) {
        fun <- .importExcel
        args <- append(
            x = args,
            values = list(
                "colnames" = colnames,
                "metadata" = metadata,
                "nMax" = nMax,
                "sheet" = sheet,
                "skip" = skip
            )
        )
    } else if (identical(ext, "pzfx")) {
        ## GraphPad Prism project.
        ## Note that Prism files always contain column names.
        fun <- .importPZFX
        args <- append(
            x = args,
            values = list(
                "metadata" = metadata,
                "sheet" = sheet
            )
        )
    } else if (identical(ext, "rds")) {
        fun <- .importRDS
    } else if (isSubset(ext, .extGroup[["rda"]])) {
        fun <- .importRDA
    } else if (identical(ext, "gmt")) {
        fun <- .importGMT
    } else if (identical(ext, "gmx")) {
        fun <- .importGMX
    } else if (identical(ext, "grp")) {
        fun <- .importGRP
    } else if (identical(ext, "json")) {
        fun <- .importJSON
        args <- append(x = args, values = list("metadata" = metadata))
    } else if (isSubset(ext, .extGroup[["yaml"]])) {
        fun <- .importYAML
        args <- append(x = args, values = list("metadata" = metadata))
    } else if (identical(ext, "mtx")) {
        ## We're always requiring row and column sidecar files for MTX.
        fun <- .importMTX
        args <- append(x = args, values = list("metadata" = metadata))
    } else if (identical(ext, "counts")) {
        ## bcbio counts format always contains row and column names.
        fun <- .importBcbioCounts
        args <- append(x = args, values = list("metadata" = metadata))
    } else if (isSubset(ext, .extGroup[["lines"]])) {
        fun <- .importLines
        args <- append(
            x = args,
            values = list(
                "comment" = comment,
                "nMax" = nMax,
                "skip" = skip
            )
        )
    } else if (isSubset(ext, .extGroup[["rtracklayer"]])) {
        fun <- .rtracklayerImport
        args <- append(x = args, values = list("metadata" = metadata))
    } else if (isSubset(ext, .extGroup[["rio"]])) {
        fun <- .rioImport
        args <- append(x = args, values = list("metadata" = metadata))
    } else {
        stop(sprintf(
            "Import of '%s' failed. '%s' extension is not supported.",
            basename(file), ext
        ))
    }
    object <- do.call(what = fun, args = args)
    ## Ensure imported R objects return unmodified.
    if (identical(ext, "rds") || isSubset(ext, .extGroup[["rda"]])) {
        return(object)
    }
    ## Check that manual column names are correct.
    if (isCharacter(colnames)) {
        assert(identical(colnames(object), colnames))
    }
    ## Data frame-specific operations.
    if (is.data.frame(object)) {
        ## Set row names automatically.
        if (isTRUE(rownames) && isSubset("rowname", colnames(object))) {
            if (!isTRUE(quiet)) {
                alertInfo("Setting row names from {.var rowname} column.")
            }
            rownames(object) <- object[["rowname"]]
            object[["rowname"]] <- NULL
        }
    }
    if (hasNames(object)) {
        if (isTRUE(any(duplicated(names(object))))) {
            dupes <- sort(names(object)[duplicated(names(object))])
            alertWarning(sprintf(
                "Duplicate names: {.var %s}.",
                toString(dupes, width = 100L)
            ))
        }
        ## Harden against any object classes that don't support names
        ## assignment, to prevent unwanted error on this step.
        tryCatch(
            expr = {
                names(object) <- makeNames(names(object))
            },
            error = function(e) NULL
        )
        if (!isTRUE(hasValidNames(object))) {
            alertWarning("Invalid names detected.")
        }
    }
    if (isTRUE(metadata)) {
        if (!is.null(metadata2(object, which = "import"))) {
            ## Add the call to metadata.
            m <- metadata2(object, which = "import")
            call <- tryCatch(
                expr = standardizeCall(),
                error = function(e) NULL
            )
            m[["call"]] <- call
            metadata2(object, which = "import") <- m
        }
    }
    object
}

formals(import)[c("makeNames", "metadata", "quiet")] <-
    formalsList[c("import.make.names", "import.metadata", "quiet")]



## Add data provenance metadata.
## Previously, "which" was defined as "pipette", until v0.3.8.
## Updated 2019-10-24.
.slotImportMetadata <- function(object, file, pkg, fun) {
    assert(
        isString(file),
        isString(pkg),
        isString(fun)
    )
    metadata2(object, which = "import") <- list(
        package = packageName(),
        packageVersion = packageVersion(packageName()),
        importer = paste0(pkg, "::", fun),
        importerVersion = packageVersion(pkg),
        file = if (isAFile(file)) {
            realpath(file)
        } else {
            file  # nocov
        },
        date = Sys.Date()
    )
    object
}



## Basic =======================================================================
#' Internal importer for a delimited file (e.g. `.csv`, `.tsv`).
#'
#' @details
#' Calls `vroom::vroom()` internally by default.
#' Can override using `acid.import.engine` option, which also supports
#' data.table and readr packages.
#'
#' @note Updated 2021-01-13.
#' @noRd
.importDelim <- function(
    file,
    colnames,
    comment,
    ext,
    metadata,
    nMax,
    quiet,
    skip
) {
    verbose <- getOption("acid.verbose", default = FALSE)
    assert(
        isFlag(colnames) || isCharacter(colnames),
        is.character(comment) && length(comment) <= 1L,
        isString(ext),
        isFlag(metadata),
        isPositive(nMax),
        isFlag(quiet),
        isInt(skip), isNonNegative(skip),
        isFlag(verbose)
    )
    ext <- match.arg(ext, choices = .extGroup[["delim"]])
    whatPkg <- match.arg(
        arg = getOption(
            x = "acid.import.engine",
            default = .defaultDelimEngine
        ),
        choices = .delimEngines
    )
    if (ext == "txt") ext <- "table"
    if (ext == "table") whatPkg <- "base"
    requireNamespaces(whatPkg)
    ## This step will automatically decompress on the fly, if necessary.
    tmpfile <- localOrRemoteFile(file = file, quiet = quiet)
    switch(
        EXPR = whatPkg,
        "base" = {
            args <- list(
                "file" = tmpfile,
                "blank.lines.skip" = TRUE,
                "comment.char" = comment,
                "na.strings" = naStrings,
                "nrows" = nMax,
                "skip" = skip,
                "stringsAsFactors" = FALSE,
                "strip.white" = TRUE
            )
            if (isCharacter(colnames)) {
                args[["header"]] <- FALSE
                args[["col.names"]] <- colnames
            } else {
                args[["header"]] <- colnames
            }
            switch(
                EXPR = ext,
                "csv" = {
                    whatFun <- "read.csv"
                },
                "tsv" = {
                    whatFun <- "read.delim"
                    args[["sep"]] <- "\t"
                },
                "table" = {
                    whatFun <- "read.table"
                }
            )
        },
        "data.table" = {
            whatFun <- "fread"
            if (isString(comment)) {
                ## nocov start
                stop(sprintf(
                    paste0(
                        "'%s::%s' does not yet support comment exclusion.\n",
                        "See '%s' for details."
                    ),
                    whatPkg, whatFun,
                    "https://github.com/Rdatatable/data.table/issues/856"
                ))
                ## nocov end
            }
            args <- list(
                "file" = tmpfile,
                "blank.lines.skip" = TRUE,
                "check.names" = TRUE,
                "data.table" = FALSE,
                "fill" = FALSE,
                "na.strings" = naStrings,
                "nrows" = nMax,
                "skip" = skip,
                "showProgress" = FALSE,
                "stringsAsFactors" = FALSE,
                "strip.white" = TRUE,
                "verbose" = verbose
            )
            if (isCharacter(colnames)) {
                args[["header"]] <- FALSE
                args[["col.names"]] <- colnames
            } else {
                args[["header"]] <- colnames
            }
        },
        "readr" = {
            whatFun <- switch(
                EXPR = ext,
                "csv" = "read_csv",
                "tsv" = "read_tsv"
            )
            args <- list(
                "file" = tmpfile,
                "col_names" = colnames,
                "col_types" = readr::cols(),
                "comment" = comment,
                "na" = naStrings,
                "n_max" = nMax,
                "progress" = FALSE,
                "trim_ws" = TRUE,
                "skip" = skip,
                "skip_empty_rows" = TRUE
            )
        },
        "vroom" = {
            whatFun <- "vroom"
            args <- list(
                "file" = tmpfile,
                "delim" = switch(
                    EXPR = ext,
                    "csv" = ",",
                    "tsv" = "\t"
                ),
                "col_names" = colnames,
                "col_types" = vroom::cols(),
                "comment" = comment,
                "na" = naStrings,
                "n_max" = nMax,
                "progress" = FALSE,
                "skip" = skip,
                "trim_ws" = TRUE,
                ".name_repair" = make.names
            )
        }
    )
    if (!isTRUE(quiet)) {
        where <- ifelse(
            test = isAURL(file),
            yes = dirname(file),
            no = realpath(dirname(file))
        )
        alert(sprintf(
            "Importing {.file %s} at {.path %s} using {.pkg %s}::{.fun %s}.",
            basename(file), where,
            whatPkg, whatFun
        ))
    }
    what <- get(x = whatFun, envir = asNamespace(whatPkg), inherits = TRUE)
    assert(is.function(what))
    object <- do.call(what = what, args = args)
    assert(is.data.frame(object))
    if (!identical(class(object), "data.frame")) {
        object <- as.data.frame(
            x = object,
            make.names = FALSE,
            stringsAsFactors = FALSE
        )
    }
    if (isTRUE(metadata)) {
        object <- .slotImportMetadata(
            object = object,
            file = file,
            pkg = whatPkg,
            fun = whatFun
        )
    }
    object
}



#' Internal importer for (source code) lines
#'
#' @note Updated 2021-01-13.
#' @noRd
#'
#' @note `vroom_lines` can return this error on empty files:
#' Error: Unnamed `col_types` must have the same length as `col_names`.
.importLines <- function(
    file,
    comment = "",
    nMax = Inf,
    quiet,
    skip = 0L
) {
    assert(
        isInt(skip),
        is.character(comment) && length(comment) <= 1L,
        isPositive(nMax),
        isFlag(quiet),
        isInt(skip), isNonNegative(skip),
        isPositive(nMax)
    )
    if (isString(comment)) {
        assert(is.infinite(nMax))
    }
    whatPkg <- match.arg(
        arg = getOption(
            x = "acid.import.engine",
            default = .defaultDelimEngine
        ),
        choices = .delimEngines
    )
    requireNamespaces(whatPkg)
    tmpfile <- localOrRemoteFile(file = file, quiet = quiet)
    switch(
        EXPR = whatPkg,
        "base" = {
            whatFun <- "readLines"
            args <- list(
                "con" = tmpfile,
                "warn" = FALSE
            )
        },
        "data.table" = {
            whatFun <- "fread"
            args <- list(
                "file" = tmpfile,
                "blank.lines.skip" = FALSE,
                "header" = FALSE,
                "nrows" = nMax,
                "sep" = "\n",
                "skip" = skip
            )
        },
        "readr" = {
            whatFun <- "read_lines"
            args <- list(
                "file" = tmpfile,
                "n_max" = nMax,
                "progress" = FALSE,
                "skip" = skip,
                "skip_empty_rows" = FALSE
            )
        },
        "vroom" = {
            whatFun <- "vroom_lines"
            args <- list(
                "file" = tmpfile,
                "n_max" = nMax,
                "progress" = FALSE,
                "skip" = skip
            )
        }
    )
    if (!isTRUE(quiet)) {
        where <- ifelse(
            test = isAURL(file),
            yes = dirname(file),
            no = realpath(dirname(file))
        )
        alert(sprintf(
            "Importing {.file %s} at {.path %s} using {.pkg %s}::{.fun %s}.",
            basename(file), where,
            whatPkg, whatFun
        ))
    }
    if (file.size(tmpfile) == 0L) {
        return(character())
    }
    what <- get(x = whatFun, envir = asNamespace(whatPkg), inherits = TRUE)
    assert(is.function(what))
    x <- do.call(what = what, args = args)
    if (whatPkg == "data.table") x <- x[[1L]]
    assert(is.character(x))
    if (isString(comment)) {
        keep <- !grepl(pattern = paste0("^", comment), x = x)
        x <- x[keep]
    }
    if (whatPkg == "base") {
        if (skip > 0L) {
            assert(skip < length(x))
            start <- skip + 1L
            end <- length(x)
            x <- x[start:end]
        }
        if (nMax < length(x)) {
            x <- x[1L:nMax]
        }
    }
    x
}



## R data ======================================================================
#' Internal importer for an R data serialized file (`.rds`)
#'
#' @note Updated 2020-08-13.
#' @noRd
.importRDS <- function(file, quiet) {
    assert(isFlag(quiet))
    tmpfile <- localOrRemoteFile(file = file, quiet = quiet)
    if (!isTRUE(quiet)) {
        where <- ifelse(
            test = isAURL(file),
            yes = dirname(file),
            no = realpath(dirname(file))
        )
        alert(sprintf(
            "Importing {.file %s} at {.path %s} using {.pkg %s}::{.fun %s}.",
            basename(file), where,
            "base", "readRDS"
        ))
    }
    object <- readRDS(file = tmpfile)
    object
}



#' Internal importer for an R data file (`.rda`)
#'
#' @note Updated 2020-08-13.
#' @noRd
.importRDA <- function(file, quiet) {
    assert(isFlag(quiet))
    tmpfile <- localOrRemoteFile(file = file, quiet = quiet)
    if (!isTRUE(quiet)) {
        where <- ifelse(
            test = isAURL(file),
            yes = dirname(file),
            no = realpath(dirname(file))
        )
        alert(sprintf(
            "Importing {.file %s} at {.path %s} using {.pkg %s}::{.fun %s}.",
            basename(file), where,
            "base", "load"
        ))
    }
    safe <- new.env()
    object <- load(file = tmpfile, envir = safe)
    if (!isTRUE(hasLength(safe, n = 1L))) {
        stop(sprintf("'%s' does not contain a single object.", basename(file)))
    }
    object <- get(object, envir = safe, inherits = FALSE)
    object
}



## Sparse matrix ===============================================================
#' Internal importer for a sparse matrix file (`.mtx`)
#'
#' @note Updated 2021-02-02.
#' @noRd
.importMTX <- function(file, metadata, quiet) {
    assert(
        isFlag(metadata),
        isFlag(quiet)
    )
    tmpfile <- localOrRemoteFile(file = file, quiet = quiet)
    if (!isTRUE(quiet)) {
        where <- ifelse(
            test = isAURL(file),
            yes = dirname(file),
            no = realpath(dirname(file))
        )
        alert(sprintf(
            "Importing {.file %s} at {.path %s} using {.pkg %s}::{.fun %s}.",
            basename(file), where,
            "Matrix", "readMM"
        ))
    }
    object <- readMM(file = tmpfile)
    ## Add the rownames automatically using `.rownames` sidecar file.
    rownamesFile <- paste(file, "rownames", sep = ".")
    rownamesFile <- tryCatch(
        expr = localOrRemoteFile(file = rownamesFile, quiet = quiet),
        error = function(e) {
            NULL  # nocov
        }
    )
    if (!is.null(rownamesFile)) {
        rownames(object) <-
            .importMTXSidecar(file = rownamesFile, quiet = quiet)
    }
    ## Add the colnames automatically using `.colnames` sidecar file.
    colnamesFile <- paste(file, "colnames", sep = ".")
    colnamesFile <- tryCatch(
        expr = localOrRemoteFile(file = colnamesFile, quiet = quiet),
        error = function(e) {
            NULL  # nocov
        }
    )
    if (!is.null(colnamesFile)) {
        colnames(object) <-
            .importMTXSidecar(file = colnamesFile, quiet = quiet)
    }
    if (isTRUE(metadata)) {
        object <- .slotImportMetadata(
            object = object,
            file = file,
            pkg = "Matrix",
            fun = "readMM"
        )
    }
    object
}



#' Internal importer for a sparse matrix sidecar file (e.g. `.rownames`)
#'
#' @note Updated 2020-08-13
#' @noRd
.importMTXSidecar <- function(file, quiet) {
    assert(isFlag(quiet))
    if (!isTRUE(quiet)) {
        where <- ifelse(
            test = isAURL(file),
            yes = dirname(file),
            no = realpath(dirname(file))
        )
        alert(sprintf(
            "Importing sidecar {.file %s} at {.path %s}.",
            basename(file), where
        ))
    }
    .importLines(file = file, quiet = quiet)
}



## List ========================================================================
#' Internal importer for a JSON file (`.json`)
#'
#' @note Updated 2020-08-13.
#' @noRd
.importJSON <- function(file, metadata, quiet) {
    requireNamespaces("jsonlite")
    assert(
        isFlag(metadata),
        isFlag(quiet)
    )
    tmpfile <- localOrRemoteFile(file = file, quiet = quiet)
    if (!isTRUE(quiet)) {
        where <- ifelse(
            test = isAURL(file),
            yes = dirname(file),
            no = realpath(dirname(file))
        )
        alert(sprintf(
            "Importing {.file %s} at {.path %s} using {.pkg %s}::{.fun %s}.",
            basename(file), where,
            "jsonlite", "read_json"
        ))
    }
    object <- jsonlite::read_json(path = tmpfile)
    if (isTRUE(metadata)) {
        object <- .slotImportMetadata(
            object = object,
            file = file,
            pkg = "jsonlite",
            fun = "read_json"
        )
    }
    object
}



#' Internal importer for a YAML file (`.yaml`, `.yml`)
#'
#' @note Updated 2020-08-13.
#' @noRd
.importYAML <- function(file, metadata, quiet) {
    requireNamespaces("yaml")
    assert(
        isFlag(metadata),
        isFlag(quiet)
    )
    tmpfile <- localOrRemoteFile(file = file, quiet = quiet)
    if (!isTRUE(quiet)) {
        where <- ifelse(
            test = isAURL(file),
            yes = dirname(file),
            no = realpath(dirname(file))
        )
        alert(sprintf(
            "Importing {.file %s} at {.path %s} using {.pkg %s}::{.fun %s}.",
            basename(file), where,
            "yaml", "yaml.load_file"
        ))
    }
    object <- yaml::yaml.load_file(input = tmpfile)
    if (isTRUE(metadata)) {
        object <- .slotImportMetadata(
            object = object,
            file = file,
            pkg = "yaml",
            fun = "yaml.load_file"
        )
    }
    object
}



## GSEA ========================================================================
#' Internal importer for a gene matrix transposed file (`.gmt`)
#'
#' @note Updated 2020-08-13
#' @noRd
#'
#' @seealso `fgsea::gmtPathways()`.
.importGMT <- function(file, quiet) {
    assert(isFlag(quiet))
    if (!isTRUE(quiet)) {
        where <- ifelse(
            test = isAURL(file),
            yes = dirname(file),
            no = realpath(dirname(file))
        )
        alert(sprintf(
            "Importing {.file %s} at {.path %s}.",
            basename(file), where
        ))
    }
    lines <- .importLines(file = file, quiet = quiet)
    lines <- strsplit(lines, split = "\t")
    pathways <- lapply(lines, tail, n = -2L)
    names(pathways) <- vapply(
        X = lines,
        FUN = head,
        FUN.VALUE = character(1L),
        n = 1L
    )
    pathways
}



#' Internal importer for a gene matrix file (`.gmx`)
#'
#' @note Updated 2020-08-13.
#' @noRd
.importGMX <- function(file, quiet) {
    assert(isFlag(quiet))
    if (!isTRUE(quiet)) {
        where <- ifelse(
            test = isAURL(file),
            yes = dirname(file),
            no = realpath(dirname(file))
        )
        alert(sprintf(
            "Importing {.file %s} at {.path %s}.",
            basename(file), where
        ))
    }
    lines <- .importLines(file = file, quiet = quiet)
    pathways <- list(tail(lines, n = -2L))
    names(pathways) <- lines[[1L]]
    pathways
}



#' Internal importer for a gene set file (`.grp`)
#'
#' @note Updated 2021-01-13
#' @noRd
.importGRP <- .importGMX



## Microsoft Excel =============================================================
## Note that `readxl::read_excel()` doesn't currently support automatic blank
## lines removal, so ensure that is fixed downstream.

#' Internal importer for a Microsoft Excel worksheet (`.xlsx`)
#'
#' @note Updated 2021-01-13.
#' @noRd
.importExcel <- function(
    file,
    colnames,
    metadata,
    nMax,
    quiet,
    sheet,
    skip
) {
    requireNamespaces("readxl")
    assert(
        isFlag(colnames) || isCharacter(colnames),
        isFlag(metadata),
        isPositive(nMax),
        isFlag(quiet),
        isScalar(sheet),
        isInt(skip), isNonNegative(skip)
    )
    tmpfile <- localOrRemoteFile(file = file, quiet = quiet)
    if (!isTRUE(quiet)) {
        where <- ifelse(
            test = isAURL(file),
            yes = dirname(file),
            no = realpath(dirname(file))
        )
        alert(sprintf(
            "Importing {.file %s} at {.path %s} using {.pkg %s}::{.fun %s}.",
            basename(file), where,
            "readxl", "read_excel"
        ))
    }
    ## Note that `tryCatch()` or `withCallingHandlers()` doesn't work here.
    ## http://adv-r.had.co.nz/Exceptions-Debugging.html
    warn <- getOption("warn")
    options(warn = 2L)
    object <- readxl::read_excel(
        path = tmpfile,
        col_names = colnames,
        n_max = nMax,
        na = naStrings,
        progress = FALSE,
        sheet = sheet,
        skip = skip,
        trim_ws = TRUE,
        .name_repair = make.names
    )
    options(warn = warn)
    ## Always return as data.frame instead of tibble at this step.
    object <- as.data.frame(
        x = object,
        make.names = FALSE,
        stringsAsFactors = FALSE
    )
    if (isTRUE(metadata)) {
        object <- .slotImportMetadata(
            object = object,
            file = file,
            pkg = "readxl",
            fun = "read_excel"
        )
    }
    object
}



## GraphPad Prism ==============================================================
#' Internal importer for a GraphPad Prism file (`.pzfx`)
#'
#' @note Updated 2020-08-13.
#' @noRd
#'
#' @note This function doesn't support optional column names.
.importPZFX <- function(
    file,
    sheet,
    metadata,
    quiet
) {
    requireNamespaces("pzfx")
    assert(
        isScalar(sheet),
        isFlag(metadata),
        isFlag(quiet)
    )
    tmpfile <- localOrRemoteFile(file = file, quiet = quiet)
    if (!isTRUE(quiet)) {
        where <- ifelse(
            test = isAURL(file),
            yes = dirname(file),
            no = realpath(dirname(file))
        )
        alert(sprintf(
            "Importing {.file %s} at {.path %s} using {.pkg %s}::{.fun %s}.",
            basename(file), where,
            "pzfx", "read_pzfx"
        ))
    }
    object <- pzfx::read_pzfx(
        path = tmpfile,
        table = sheet
    )
    if (isTRUE(metadata)) {
        object <- .slotImportMetadata(
            object = object,
            file = file,
            pkg = "pzfx",
            fun = "read_pzfx"
        )
    }
    object
}



## bcbio =======================================================================
#' Import bcbio featureCounts file
#'
#' @details
#' Internal importer for a bcbio count matrix file (`.counts`).
#' These files contain an `"id"` column that we need to coerce to row names.
#'
#' @note Updated 2020-12-18.
#' @noRd
.importBcbioCounts <- function(file, metadata, quiet) {
    assert(
        isFlag(metadata),
        isFlag(quiet)
    )
    object <- import(
        file = file,
        format = "tsv",
        metadata = metadata,
        quiet = quiet
    )
    if (isTRUE(metadata)) {
        m <- metadata2(object, which = "import")
        assert(
            is.list(m),
            hasLength(m)
        )
    }
    assert(
        is.data.frame(object),
        isSubset("id", colnames(object)),
        hasNoDuplicates(object[["id"]])
    )
    rownames(object) <- object[["id"]]
    object[["id"]] <- NULL
    object <- as.matrix(object)
    mode(object) <- "integer"
    if (isTRUE(metadata)) {
        metadata2(object, which = "import") <- m
    }
    object
}



## Handoff =====================================================================
#' Handoff to rio import
#'
#' @note Updated 2020-08-13.
#' @noRd
.rioImport <- function(file, metadata, quiet, ...) {
    requireNamespaces("rio")
    assert(
        isFlag(metadata),
        isFlag(quiet)
    )
    tmpfile <- localOrRemoteFile(file = file, quiet = quiet)
    if (!isTRUE(quiet)) {
        where <- ifelse(
            test = isAURL(file),
            yes = dirname(file),
            no = realpath(dirname(file))
        )
        alert(sprintf(
            "Importing {.file %s} at {.path %s} using {.pkg %s}::{.fun %s}.",
            basename(file), where,
            "rio", "import"
        ))
    }
    object <- rio::import(file = tmpfile, ...)
    if (isTRUE(metadata)) {
        object <- .slotImportMetadata(
            object = object,
            file = file,
            pkg = "rio",
            fun = "import"
        )
    }
    object
}



#' Handoff to rtracklayer import
#'
#' @note Updated 2020-08-13.
#' @noRd
#'
#' @note Using `tryCatch()` here to error if there are any warnings.
.rtracklayerImport <- function(file, metadata, quiet, ...) {
    requireNamespaces("rtracklayer")
    assert(
        isFlag(metadata),
        isFlag(quiet)
    )
    tmpfile <- localOrRemoteFile(file = file, quiet = quiet)
    if (!isTRUE(quiet)) {
        where <- ifelse(
            test = isAURL(file),
            yes = dirname(file),
            no = realpath(dirname(file))
        )
        alert(sprintf(
            "Importing {.file %s} at {.path %s} using {.pkg %s}::{.fun %s}.",
            basename(file), where,
            "rtracklayer", "import"
        ))
    }
    object <- tryCatch(
        expr = rtracklayer::import(con = tmpfile, ...),
        error = function(e) {
            stop("File failed to load.")  # nocov
        },
        warning = function(w) {
            stop("File failed to load.")  # nocov
        }
    )
    if (isTRUE(metadata)) {
        object <- .slotImportMetadata(
            object = object,
            file = file,
            pkg = "rtracklayer",
            fun = "import"
        )
    }
    object
}
