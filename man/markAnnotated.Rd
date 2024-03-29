% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/markAnnotated.R
\name{markAnnotated}
\alias{markAnnotated}
\title{Mark Detections as Annotated}
\usage{
markAnnotated(
  x,
  anno = NULL,
  tBuffer = 0,
  fBuffer = 0,
  table = "Spectrogram_Annotation"
)
}
\arguments{
\item{x}{an AcousticStudy object}

\item{anno}{annotations to read from. If \code{NULL}, will be read in from
the PAMguard database. If a data.frame, must have columns \code{start} and
\code{end} in UTC, and column \code{id}. Can additionally have columns \code{fmin} and \code{fmax}
to apply frequency bounds (values in Hz).}

\item{tBuffer}{additional buffer value to add on to annotation time bounds in
seconds. If a single number, the number of seconds to extend the bounds by
on the start and end of each annotation. Can also be a vector of two to
extend different values on the start and end. This can be useful if original
bounding boxes were drawn very close to the desired detections since any small
portion of a signal outside the box will cause it to be excluded.}

\item{fBuffer}{additional buffer value to add to annotation frequency bounds in
Hz. If a single number, the number of Hz to extend bounds by on lower and upper
end of boxes. Can also be a vector of two to extend different values on lower and
upper bounds. This can be useful if original bounding boxes were drawn very close
to the desired detections since any small portion of a signal outside the box will
cause it to be excluded.}

\item{table}{if \code{anno} is \code{NULL}, the name of the "Spectrogram Annotation"
module table within the database.}
}
\value{
the same object as \code{x}, but detectors have additional columns added
}
\description{
Marks detections within an \linkS4class{AcousticStudy} as
  being within the bounds of an annotation box. Annotations can either
  be read in from the "Spectrogram Annotation" module of PAMguard, or
  supplied as a separate dataframe. Detections must be entirely contained
  within the annotation bounds.
}
\details{
This adds new columns \code{inAnno} and \code{annoId} to all detector
  dataframes within the AcousticStudy. \code{inAnno} is a logical flag whether or not
  a given detection was fully contained in any annotation bounding box, and \code{annoId}
  lists the IDs of the boxes it matched. A detection is considered within an annotation
  only if it is entirely within the time and frequency bounds of the annotation. For
  GPL and whistle detections, the min and max frequency values are used. For click detections,
  only the peak frequency is used. For cesptrum detections, frequency bounds are ignored.
}
\examples{
data(exStudy)
annotation <- data.frame(start = min(getWhistleData(exStudy)$UTC),
                         fmin = c(16000, 17000),
                         fmax = c(17000, 18000))
annotation$end <- annotation$star + 1
exStudy <- markAnnotated(exStudy, annotation)
getWhistleData(exStudy)[c('UTC', 'duration', 'freqMin', 'freqMax', 'inAnno', 'annoId')]

}
\author{
Taiki Sakai \email{taiki.sakai@noaa.gov}
}
