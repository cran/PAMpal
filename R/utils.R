# random utils

# for converting from database UTC columns that are characters
pgDateToPosix <- function(x) {
    as.POSIXct(as.character(x), format='%Y-%m-%d %H:%M:%OS', tz='UTC')
}

# drop columns with names cols
dropCols <- function(x, cols) {
    keepCols <- !(colnames(x) %in% cols)
    x[, keepCols, drop=FALSE]
}

# what event is a UID in returns named index
whereUID <- function(study, UID, quiet=FALSE) {
    UID <- as.character(UID)
    where <- sapply(UID, function(u) { #for each uid
        ix <- which(sapply(events(study), function(e) { #go through each event
            any(sapply(detectors(e), function(d) { #and every detector in that event
                u %in% d$UID
            }))
        }))
        if(length(ix) == 0) {
            return(NA)
        }
        ix
    }, USE.NAMES=TRUE, simplify=FALSE)
    whereNA <- is.na(where)
    if(!quiet && any(whereNA)) {
        pamWarning('UID(s) ', paste0(UID[whereNA], collapse=', '),
                ' not found in any events.')
    }
    where
}

# match SR function
# data needs UTC, thats it
# db is sound acq data, either DF or db
# safe to fail with NULL instead of error
#' @importFrom data.table data.table setkeyv
#'
matchSR <- function(data, db, extraCols = NULL, safe=FALSE) {
    if(is.character(db)) {
        if(!file.exists(db)) {
            if(safe) return(NULL)
            stop('Database ', db, ' does not exist.')
        }
        con <-dbConnect(db, drv=SQLite())
        on.exit(dbDisconnect(con))
        if(!('Sound_Acquisition' %in% dbListTables(con))) {
            soundAcquisition <- NULL
        } else {
            soundAcquisition <- dbReadTable(con, 'Sound_Acquisition')
            soundAcquisition$UTC <- pgDateToPosix(soundAcquisition$UTC)
        }
    }
    if(is.data.frame(db)) {
        soundAcquisition <- db
    }
    if(!('UTC' %in% colnames(data)) ||
       !inherits(data$UTC, 'POSIXct')) {
        stop('Data must have a column "UTC" in POSIXct format.')
    }
    if(!is.null(soundAcquisition)) {
        soundAcquisition <- soundAcquisition %>%
            mutate(Status = str_trim(.data$Status),
                   SystemType = str_trim(.data$SystemType)) %>%
            filter(.data$Status=='Start') %>%
            arrange(.data$UTC) %>%
            select(all_of(c('UTC', 'sampleRate', extraCols))) %>%
            distinct() %>%
            data.table()
        
        setkeyv(soundAcquisition, 'UTC')
        
        data <- data.table(data)
        setkeyv(data, 'UTC')
        
        # This rolling join rolls to the first time before. Since we filtered to only starts, it goes back
        # to whatever the last Start was.
        data <- soundAcquisition[data, roll = TRUE] %>%
            data.frame()
        srNa <- which(is.na(data$sampleRate))
    } else {
        data[extraCols] <- NA
        srNa <- rep(TRUE, nrow(data))
    }
    if(length(srNa) == nrow(data)) {
        cat('\nNo Sample Rate found in SoundAcquisition table. Enter Sample Rate for this data:\n')
        srReplace <- as.integer(readline())
        data$sampleRate[srNa] <- srReplace
    } else if(length(srNa) > 0) {
        # get mode
        mode <- which.max(tabulate(data$sampleRate[-srNa]))
        srChoice <- menu(title=paste0('Could not get Sample Rate for all detections from the "SoundAcquistion" table.',
                                      ' Should missing values be replaced with ', mode, '(value found in table).'),
                         choices = c('Yes', 'No (I want to enter my own SR)'))
        srReplace <- switch(srChoice,
                            '1' = mode,
                            '2' = {
                                cat('\nWhat Sample Rate should be used?\n')
                                readline()
                            },
                            stop('Sample Rate required for calculations.')
        )
        data$sampleRate[srNa] <- srReplace
    }
    data
}

# check if in start/stop interval
# bounds is a single start/stop, sa is sound acq table from db
#' @importFrom tidyr spread
#'
inInterval <- function(bounds, sa) {
    sa <- sa[sa$Status %in% c('Start', 'Stop'), c('UTC', 'Status', 'sampleRate')]
    first <- min(which(sa$Status == 'Start'))
    last <- max(which(sa$Status == 'Stop'))
    sa <- sa[first:last,]
    alt <- sa$Status[1:(nrow(sa)-1)] != sa$Status[2:nrow(sa)]
    sa <- sa[c(TRUE, alt), ]
    sa$id <- rep(1:(nrow(sa)/2), each=2)
    sa <- tidyr::spread(sa, 'Status', 'UTC')
    startIn <- (any((bounds[1] >= sa[['Start']]) & (bounds[1] <= sa[['Stop']])))
    endIn <- (any((bounds[2] >= sa[['Start']]) & (bounds[2] <= sa[['Stop']])))
    contain <- (any((bounds[1] <= sa[['Start']]) & (bounds[2] >= sa[['Stop']])))
    startIn || endIn || contain
}

# add list without replacing old one, only replace matching names
safeListAdd <- function(x, value) {
    if(is.null(value)) {
        return(x)
    }
    if(!is.list(value) ||
       is.null(names(value))) {
        stop('Can only add named lists ')
    }
    hasName <- names(value) %in% names(x)
    if(any(hasName)) {
        for(n in names(value)[hasName]) {
            x[[n]] <- value[[n]]
        }
    }
    if(any(!hasName)) {
        x <- c(x, value[!hasName])
    }
    x
}

# clip of fixed length, zeropads if needed and deals with edge case
clipAroundPeak <- function(wave, length, noise=FALSE) {
    if(length(wave) < length) {
        return(c(wave, rep(0, length - length(wave))))
    }
    peak <- which.max(abs(wave))
    low <- peak - floor(length/2)
    high <- ceiling(peak + length/2) -1
    if(low < 1) {
        return(wave[1:length])
    }
    if(high > length(wave)) {
        return(wave[(length(wave)-length+1):length(wave)])
    }
    if(noise) {
        if(low - length > 1) {
            return(wave[(low-length):(low-1)])
        } else {
            return(wave[1:length])
        }
    }
    wave[low:high]
}

printN <- function(x, n=6, collapse=', ') {
    nItems <- length(x)
    if(nItems == 0) {
        return('')
    }
    if(nItems > n) {
        x <- c(x[1:n], paste0('... (', nItems-n, ' more not shown)'))
    }
    paste0(paste(x, collapse=collapse))
}

checkRecordings <- function(x) {
    if(is.null(files(x)$recordings)) {
        stop('No recordings found, use function "addRecordings" first.', call.=FALSE)
    }
    exists <- file.exists(files(x)$recordings$file)
    if(all(!exists)) {
        stop('Recording files could not be located on disk, try ',
             '"updateFiles" first.', call.=FALSE)
    }
    exists
}

getPamFft <- function(data) {
    if(inherits(data, 'PamBinary')) {
        data$data <- contourToFreq(data$data)
        return(data)
    }
    if(length(data) == 0) {
        return(data)
    }
    if(!(all(c('sliceData', 'nSlices', 'sampleDuration', 'startSample', 'maxFreq') %in%
             names(data[[1]])))) {
        stop('Appears data is not a Whistle and Moan Detector binary file.')
    }
    tempData <- data[[1]]
    if(tempData$sliceData[[1]]$sliceNumber == 0) {
        tempData <- data[[2]]
    }
    fftHop <- (tempData$startSample + 1)/tempData$sliceData[[1]]$sliceNumber
    fftLen <- tempData$sampleDuration -
        (tempData$sliceData[[tempData$nSlices]]$sliceNumber - tempData$sliceData[[1]]$sliceNumber) * fftHop
    sr <- fftLen * tempData$maxFreq /
        max(unlist(lapply(tempData$sliceData, function(x) x$peakData)))
    list(sr=sr, hop=fftHop, wl=fftLen)
}

ppVars <- function() {
    list(nonModelVars = c('UID', 'Id', 'parentUID', 'sampleRate', 'Channel',
                          'angle', 'angleError', 'peakTime', 'depth', 'sr'),
         tarMoCols = c(
             "TMModelName1", "TMLatitude1", "TMLongitude1", "BeamLatitude1",                
             "BeamLongitude1", "BeamTime1", "TMSide1", "TMChi21", "TMAIC1", "TMProbability1",               
             "TMDegsFreedom1", "TMPerpendicularDistance1", "TMPerpendicularDistanceError1", "TMDepth1",                     
             "TMDepthError1","TMHydrophones1","TMComment1","TMError1","TMLatitude2","TMLongitude2",                
             "BeamLatitude2","BeamLongitude2","BeamTime2","TMSide2", "TMChi22","TMAIC2",                       
             "TMProbability2", "TMDegsFreedom2", "TMPerpendicularDistance2", "TMPerpendicularDistanceError2",
             "TMDepth2" ,"TMDepthError2", "TMHydrophones2","TMError2","TMComment2"),
         bftHeight = data.table(bftMax=c(1, 2.4, 2.9, 3.4, 3.9, 4.4, 4.9, 5.4, 6, 12),
                                waveHeight=c(0, 0.05, 0.1, 0.2, 0.5, 0.6, 1.25, 1.3, 2.5, 2.5),
                                key='bftMax'),
         specMap = data.frame(comment = c('cuviers', 'cuvier', 'gervais', 'gervai', 
                                          'sowerbys', 'sowerby', 'trues', 'true', 
                                          'blainvilles', 'blainville',
                                          'unid mesoplodon', 'mmme', 'undi mesoplodon'),
                              id = c('Cuviers', 'Cuviers', 'Gervais', 'Gervais', 
                                     'Sowerbys', 'Sowerbys', 'Trues', 'Trues', 
                                     'Blainvilles', 'Blainvilles',
                                     'MmMe', 'MmMe', 'MmMe')),
         dglCols = c('Id', 'UID', 'UTC', 'UTCMilliseconds', 'PCLocalTime', 'PCTime', 
                      'ChannelBitmap', 'SequenceBitmap', 'EndTime', 'DataCount')
    )
}

# logic to see whether Type or Name is holding wav files
findWavCol <- function(sa) {
    st <- sa$SystemType
    sn <- sa$SystemName
    wavCol <- NA
    if((all(is.na(sn)) || is.null(sn)) &&
       !all(grepl('^Audio ', st))) {
        wavCol <- 'SystemType'
    } 
    if(!(all(is.na(sn)) || is.null(sn)) &&
       !(all(grepl('Audio ', sn)))) {
        wavCol <- 'SystemName'
    }
    wavCol
}