% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/AllGenerics.R, R/factorize-methods.R
\name{factorize}
\alias{factorize}
\alias{factorize,DataFrame-method}
\title{Factorize}
\usage{
factorize(object, ...)

\S4method{factorize}{DataFrame}(object)
}
\arguments{
\item{object}{Object.}

\item{...}{Additional arguments.}
}
\value{
Modified object.
All columns will be coerced to \code{factor}.
}
\description{
Coerce all columns in the object to \code{factor} (i.e. \code{stringsAsFactors}).
}
\note{
Updated 2021-02-11.
}
\examples{
df <- DataFrame(a = letters[seq_len(5L)], b = seq_len(5L))
x <- factorize(df)
}
\seealso{
\code{\link[AcidGenerics:encode]{encode()}} for run-length encoding (Rle) approach.
}
