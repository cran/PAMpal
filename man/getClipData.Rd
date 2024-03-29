% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/getClipData.R
\name{getClipData}
\alias{getClipData}
\title{Get Wav Clips of Data}
\usage{
getClipData(
  x,
  buffer = c(0, 0.1),
  mode = c("event", "detection"),
  channel = 1,
  useSample = FALSE,
  fixLength = FALSE,
  progress = TRUE,
  verbose = TRUE,
  FUN = NULL,
  ...
)
}
\arguments{
\item{x}{\linkS4class{AcousticStudy} object containing data to read wav clips for}

\item{buffer}{amount before and after each event to also include in the clip, in seconds.
Can either be a vector of length two specifying how much to buffer before and after
(first number should be negative), or a single value if the buffer amount should be identical.}

\item{mode}{either \code{'event'} or \code{'detection'} specifying whether to create
wav clips of entire events or individual detections}

\item{channel}{channel(s) of clips to write}

\item{useSample}{logical flag to use startSample information in binaries instead of UTC
time for start of detections. This can be slightly more accurate (~1ms) but will take
longer}

\item{fixLength}{logical flag to fix the output clip length to a constant value. If
\code{TRUE}, then output clip length is entirely determined by the buffer value, as
if the detection or event had zero length. E.g. \code{buffer=c(-2,1)} will produce clips
3 seconds long, starting 2 seconds before the detection/event start time.}

\item{progress}{logical flag to show progress bar}

\item{verbose}{logical flag to show summary messages}

\item{FUN}{optional function to apply to wav clips. This function takes default inputs \code{wav},
a Wave class object, \code{name} the name of the detection or event, \code{time} the start and end
time of the clip, \code{channel} as above, \code{mode} as above, and additional args \dots}

\item{\dots}{optional arguments to pass to \code{FUN}}
}
\value{
A named list of wav clips
}
\description{
Reads audio clips containing sounds from events or detections
}
\examples{

data(exStudy)
recs <- system.file('extdata', 'Recordings', package='PAMpal')
exStudy <- addRecordings(exStudy, folder=recs, log=FALSE, progress=FALSE)
\dontrun{
# not running so that no wav clips are written to disk
wavs <- getClipData(exStudy, mode='event')
}

}
\author{
Taiki Sakai \email{taiki.sakai@noaa.gov}
}
