% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/summariseDiveDepth.R
\name{summariseDiveDepth}
\alias{summariseDiveDepth}
\title{Summarise Dive Depth}
\usage{
summariseDiveDepth(x, hpDepthError = 1, locType = "PGTargetMotion")
}
\arguments{
\item{x}{an \linkS4class{AcousticStudy} that has been
processed with \link{calculateEchoDepth}}

\item{hpDepthError}{hydrophone depth error to use for error estimation}

\item{locType}{name of localization, note that this function is not computing
any localization, only using previously calculated}
}
\value{
a dataframe with columns summarising the estimated dive depth
  for each event in \code{x}
}
\description{
Summarise results of dive depth estimation using
  \link{calculateEchoDepth} and related functions
}
\examples{
# example not run because \link{calculateEchoDepth} must be run first,
# and it requires a large amount of data not stored in the package
\dontrun{
study <- calculateEchoDepth(study, wav='path/to/wavFiles')
summariseDiveDepth(study)
}

}
\author{
Taiki Sakai \email{taiki.sakai@noaa.gov}
}
