% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/plotDataExplorer.R
\name{plotDataExplorer}
\alias{plotDataExplorer}
\title{Explore Data in an Interactive Shiny Plot}
\usage{
plotDataExplorer(x)
}
\arguments{
\item{x}{data to plot, can be an \code{AcousticStudy}, \code{AcousticEvent},
data.frame or a list of \code{AcousticEvent} objects}
}
\value{
nothing, just plots
}
\description{
Runs an interactive Shiny plot of detector data. Allows user to
  choose which numeric data to plot, and will allow user to both color and
  facet the plot by event number, detector name, or species
}
\examples{

data(exStudy)

if(interactive()) plotDataExplorer(exStudy)

}
\author{
Taiki Sakai \email{taiki.sakai@noaa.gov}
}
