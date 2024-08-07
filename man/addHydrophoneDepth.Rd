% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/addHydrophoneDepth.R
\name{addHydrophoneDepth}
\alias{addHydrophoneDepth}
\title{Add Hydrophone Depth Data to an AcousticStudy}
\usage{
addHydrophoneDepth(x, depth = NULL, depthCol = NULL, thresh = 60, ...)
}
\arguments{
\item{x}{an \linkS4class{AcousticStudy} to add depth data to}

\item{depth}{a CSV or data frame of depth values to match to data from \code{x}.
Must have column \code{UTC}, and a column containing depth data to be
specified by \code{depthCol}. If not provided and \code{x} is an
\linkS4class{AcousticEvent} or \linkS4class{AcousticStudy} object, then
the depth data will be read from the databases contained in the \code{files}
slot of \code{x}}

\item{depthCol}{the name of the column containing depth in the dataframe or
database. If left as \code{NULL}, will search for a single column containing
the word "depth" or "Depth"}

\item{thresh}{maximum time apart in seconds for matching depth to
data, if the closest value is more than \code{thresh} apart then the
depth value will be set to \code{NA}}

\item{\dots}{additional arguments for other methods}
}
\value{
the same data as \code{x}, with depth data added. All AcousticEvents will
  have depth data added to all detector dataframes as column \code{hpDepth}
}
\description{
Add hydrophone depth to an AcousticStudy or AcousticEvent
}
\details{
Depth values will be matched to the data
  by using data.table's rolling join with \code{roll='nearest'}. After the
  join is done, the time difference between the matched rows is checked
  and any that are greater than the set threshold are set to NA. This is
  done to prevent accidentally matching weird things if an incomplete set
  of depth data is provided.

  If \code{x} is an \linkS4class{AcousticEvent} or \linkS4class{AcousticStudy},
  then \code{depth} can be omitted and will be read from the databases contained
  in the \code{files} slot of \code{x}.
}
\examples{

data(exStudy)
# need to update database file to local directory
db <- system.file('extdata', 'Example.sqlite3', package='PAMpal')
exStudy <- updateFiles(exStudy, db=db, bin=NA, verbose=FALSE)
exStudy <- addHydrophoneDepth(exStudy)
getClickData(exStudy[1])

}
\author{
Taiki Sakai \email{taiki.sakai@noaa.gov}
}
