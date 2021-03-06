% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/removeFunction.R
\name{removeFunction}
\alias{removeFunction}
\title{Remove a Function from a PAMpalSettings Object}
\usage{
removeFunction(pps, index = NULL)
}
\arguments{
\item{pps}{a \linkS4class{PAMpalSettings} object to remove a function from}

\item{index}{index indicating which function to move, counting from
\code{ClickDetector} functions first, then \code{WhistlesMoans} functions,
then \code{Cepstrum} functions.
This is the same order functions appear in when examining the pps object.
For example, if there are two Click functions and one Whistle function, the
Whistle function would have an index of 3. If missing, user can select
from a list. This can also be a vector to remove multiple functions at once.}
}
\value{
the same \linkS4class{PAMpalSettings} object as pps, with the function
  removed from the "functions" slot
}
\description{
Remove a function from the "function" slot in a PAMpalSettings
  object.
}
\examples{

exPps <- new('PAMpalSettings')
exPps <- addFunction(exPps, roccaWhistleCalcs, module='WhistlesMoans')
exPps <- addFunction(exPps, standardCepstrumCalcs, module = 'Cepstrum')
removeFunction(exPps, 1)
removeFunction(exPps, 1:2)
# normally best to use interactively instead of specifying index
if(interactive()) removeFunction(exPps)

}
\author{
Taiki Sakai \email{taiki.sakai@noaa.gov}
}
