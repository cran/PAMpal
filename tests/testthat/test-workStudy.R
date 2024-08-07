context('Test working with AcousticStudy object')

test_that('Test working with AcousticStudy object', {
    # build basic study object
    exPps <- new('PAMpalSettings')
    exPps <- addDatabase(exPps, system.file('extdata', 'Example.sqlite3', package='PAMpal'), verbose=FALSE)
    exPps <- addBinaries(exPps, system.file('extdata', 'Binaries', package='PAMpal'), verbose=FALSE)
    exClick <- function(data) {
        standardClickCalcs(data, calibration=NULL, filterfrom_khz = 0)
    }
    exPps <- addFunction(exPps, exClick, module = 'ClickDetector', verbose=FALSE)
    exPps <- addFunction(exPps, roccaWhistleCalcs, module='WhistlesMoans', verbose=FALSE)
    exPps <- addFunction(exPps, standardCepstrumCalcs, module = 'Cepstrum', verbose=FALSE)
    exData <- processPgDetections(exPps, mode='db', id='Example', progress = FALSE, verbose = FALSE)

    # check adding gps
    exData <- addGps(exData, thresh=365*24*3600)
    expect_equal(nrow(gps(exData)), 200)
    expect_true(!any(
        is.na(gps(exData)[['Latitude']])
    ))
    expect_true(all(c('UTC', 'Latitude', 'Longitude') %in% colnames(exData[[1]][[1]])))
    expect_true(!any(
        is.na(exData[[1]][[1]][['Latitude']])
    ))
    expect_true(!any(
        is.na(exData[[1]][[1]][['Longitude']])
    ))
    expect_true(all(c('UTC', 'Latitude', 'Longitude') %in% colnames(exData[[1]][[2]])))
    expect_true(!any(
        is.na(exData[[1]][[2]][['Latitude']])
    ))
    expect_true(!any(
        is.na(exData[[1]][[2]][['Longitude']])
    ))
    expect_true(all(c('UTC', 'Latitude', 'Longitude') %in% colnames(exData[[1]][[3]])))
    expect_true(!any(
        is.na(exData[[1]][[3]][['Latitude']])
    ))
    expect_true(!any(
        is.na(exData[[1]][[3]][['Longitude']])
    ))
    gps <- data.frame(Latitude = 32, Longitude=-118, UTC = as.POSIXct('2020-01-30 00:00:00', tz='UTC'))
    expect_warning(addGps(exData, gps=gps, thresh=3600),
                   '3 events had GPS matches')
    exData <- addGps(exData, gps=gps, thresh=Inf)
    expect_equal(nrow(gps(exData)), 1)
    expect_equal(getClickData(exData)$Latitude[1], 32)
    # add gps from DF
    # check ici
    expect_warning(iciData <- getICI(exData), 'No ICI data')
    expect_null(iciData)
    exData <- calculateICI(exData)
    expect_true(all(c('Click_Detector_1', 'All') %in% names(ancillary(exData[[1]])$ici)))
    expect_true(!any(
        is.na(ancillary(exData[[1]])$ici[[1]]$ici)
    ))
    expect_true(!any(
        is.na(ancillary(exData[[1]])$ici[[2]]$ici)
    ))
    expect_true(all(c('Click_Detector_1_ici', 'All_ici') %in% names(ancillary(exData[[1]])$measures)))
    expect_true(all(c('Click_Detector_1_ici', 'All_ici') %in% names(getMeasures(exData[[1]]))))
    expect_true(all(c('Click_Detector_1_ici', 'All_ici') %in% names(getClickData(exData[[1]]))))
    iciData <- getICI(exData, 'data')
    expect_true(all(c('Click_Detector_1', 'All') %in% iciData$detectorName))
    # expect_identical(names(iciData), names(events(exData)))
    expect_true(all(names(events(exData)) %in% iciData$eventId))
    iciData <- getICI(exData, 'value')
    expect_true(all(c('Click_Detector_1_ici', 'All_ici') %in% names(iciData[[1]])))

    # check setSpecies
    exData <- setSpecies(exData, method='pamguard')
    expect_equal(species(exData[[1]])$id, 'Test')
    expect_equal(species(exData[[2]])$id, 'Test')
    # check manual edge cases
    expect_warning(setSpecies(exData, method='manual'), 'Manual mode requires')
    expect_warning(setSpecies(exData, method='manual', value=1:4), 'Length of "value"')
    expect_warning(setSpecies(exData, method='manual', value= data.frame(old=1, new=2),
                              'must contain columns'))
    expect_message(setSpecies(exData, method='manual',
                              value = data.frame(event = 'a', species=1)),
                   'No match found')
    exData <- setSpecies(exData, method = 'manual', value=letters[1:3])
    expect_equal(species(exData[[1]])$id, 'a')
    expect_equal(species(exData[[2]])$id, 'b')
    expect_equal(species(exData[[3]])$id, 'c')
    exData <- setSpecies(exData, method='manual',
                         value = data.frame(event='Example.OE1', species = 'c'))
    expect_equal(species(exData[[1]])$id, 'c')
    # check reassign edge cases
    expect_warning(setSpecies(exData, method='reassign'), 'mode requires a "value"')
    expect_warning(setSpecies(exData, method='reassign', value=data.frame(x=1, y=2)),
                   'must have columns')
    exData <- setSpecies(exData, method='reassign',
                         value= data.frame(old='c', new='b'))
    expect_equal(species(exData[[1]])$id, 'b')
    # test banter export
    banterData <- export_banter(exData, verbose=FALSE)
    expect_equal(nrow(banterData$events), 3)
    expect_equal(length(banterData$detectors), 3)
    expect_warning(export_banter(exData, dropSpecies = c('b', 'c'), verbose=FALSE))
    lessData <- export_banter(exData, dropVars = c('peak'), verbose=FALSE)
    expect_true(!any(
        sapply(lessData$detectors, function(x) 'peak' %in% colnames(x))
    ))

    # test add recordings
    recs <- system.file('extdata', 'Recordings', package='PAMpal')
    exData <- addRecordings(exData, folder = recs, log=FALSE, progress=FALSE)
    expect_identical(normalizePath(files(exData)$recordings$file, winslash = '/'),
                     normalizePath(list.files(recs, full.names = TRUE), winslash = '/'))
    expect_warning(warnRec <- addRecordings(exData, folder = 'DNE', log=FALSE, progress=FALSE))
    # test clip fun
    clips <- getClipData(exData, mode='detection', buffer=c(0, .1))
    expect_equal(nrow(clips[['Example.DGL1.8000003']]@.Data) / clips[['Example.DGL1.8000003']]@samp.rate,
                 0.1)
    expect_equal(
        round(nrow(clips[['Example.DGL1.386000022']]@.Data) / clips[['Example.DGL1.386000022']]@samp.rate, 2),
        .1 + round(exData$Example.DGL1$Whistle_and_Moan_Detector$duration, 2)
    )
    fixClips <- getClipData(exData, mode='detection', buffer=c(0, .1), fixLength=TRUE)
    expect_equal(
        round(nrow(fixClips[['Example.DGL1.386000022']]@.Data) / fixClips[['Example.DGL1.386000022']]@samp.rate, 2),
        .1
    )
    # test warning access from recorder warning
    warns <- getWarnings(warnRec)
    expect_is(warns, 'data.frame')
    expect_true('Provided folder DNE does not exist.' %in% warns$message)

})

test_that('Test filter', {
    data(exStudy)
    # test filtering
    expect_warning({
        filterNone <- filter(exStudy, VARDNE == 'DNE')
        })
    expect_warning(filter(exStudy, peak = 3))
    # expect_identical(events(exStudy), events(filterNone))
    expect_true(checkSameDetections(exStudy, filterNone))
    exStudy <- setSpecies(exStudy, method='manual', value=letters[1:2])
    spFilter <- filter(exStudy, species == 'a')
    expect_equal(length(events(spFilter)), 1)
    expect_equal(species(spFilter[[1]])$id, 'a')
    spFilter <- filter(exStudy, species %in% letters[1:3])
    # expect_identical(events(spFilter), events(exStudy))
    expect_true(checkSameDetections(spFilter, exStudy))
    peakFilter <- filter(exStudy, peak < 20)
    expect_true(all(detectors(peakFilter)$click$peak < 20))
    peakFilter <- filter(exStudy, peak < 2000)

    expect_warning(filter(exStudy, detector == 'Click_Detector_1'))
    detFilter <- filter(exStudy, detectorName == 'Cepstrum_Detector')
    expect_equal(nClicks(detFilter), 0)
    expect_equal(getCepstrumData(exStudy), getCepstrumData(detFilter))
    expect_true(checkSameDetections(peakFilter, exStudy))

    dbFilter <- filter(exStudy, database == files(exStudy)$db)
    # expect_identical(events(exStudy), events(dbFilter))
    expect_true(checkSameDetections(exStudy, dbFilter))
    dbNone <- filter(exStudy, database == 'NODB.sqlite3')
    expect_equal(length(events(dbNone)), 0)
    # test complex filters
    multiFilt <- filter(exStudy, (detectorName != 'Cepstrum_Detector' | ici > .0016))
    expect_true(all(
        getCepstrumData(multiFilt)$ici > .0016
    ))
    expect_equal(nrow(getClickData(multiFilt)),
                 nrow(getClickData(exStudy)))

    expect_warning(filter(exStudy, (detectorName != 'Cepstrum_Detector' | blergh > 10)))
})
test_that('Test checkStudy test cases', {
    # create example data
    data(exStudy)
    expect_warning(checkStudy(exStudy, maxLength = 1),
                   'Found 2 events longer than 1 seconds')
    expect_warning(checkStudy(exStudy, maxSep = .1),
                   'Found 2 events with detections more than 0.1')
    exStudy$Example.OE1$Click_Detector_1$peak <- 0
    expect_warning(checkStudy(exStudy), 'Some clicks had a peak frequency of 0')
})

test_that('Test getBinaryData', {
    data(exStudy)
    binFolder <- system.file('extdata', 'Binaries', package='PAMpal')
    exStudy <- updateFiles(exStudy, bin=binFolder, db=NA, verbose=FALSE)
    bin <- getBinaryData(exStudy, UID = 8000003)
    expect_equal(names(bin), '8000003')
    expect_true(all(c('wave', 'sr', 'minFreq') %in% names(bin[[1]])))
    expect_null(expect_warning(getBinaryData(exStudy, UID = 1)))
})

test_that('Test getDetectorData', {
    data(exStudy)
    dets <- getDetectorData(exStudy)
    expect_true(all(c('click', 'whistle', 'cepstrum') %in% names(dets)))
    expect_is(dets, 'list')
    expect_is(dets[[1]], 'data.frame')
    # works same on events and studies
    expect_identical(getDetectorData(exStudy[1]),
                     getDetectorData(exStudy[[1]]))
    expect_identical(dets$click, getClickData(exStudy))
    expect_identical(dets$whistle, getWhistleData(exStudy))
    expect_identical(dets$cepstrum, getCepstrumData(exStudy))
    expect_equal(nDetections(exStudy), 28L)
    expect_equal(nClicks(exStudy), 4L)
    expect_equal(nWhistles(exStudy), 14L)
    expect_equal(nCepstrum(exStudy), 10L)
    expect_equal(nGPL(exStudy), 0L)
})

test_that('Test updateFiles', {
    data(exStudy)
    # corrupting filepaths
    files(exStudy)$db <- substr(files(exStudy)$db, start=5, stop=10e3)
    files(exStudy)$binaries <- substr(files(exStudy)$binaries, start=5, stop=10e3)
    files(exStudy[[1]])$db <- substr(files(exStudy[[1]])$db, start=5, stop=10e3)
    files(exStudy[[1]])$binaries <- substr(files(exStudy[[1]])$binaries, start=5, stop=10e3)
    db <- system.file('extdata', 'Example.sqlite3', package='PAMpal')
    bin <- system.file('extdata', 'Binaries', package='PAMpal')
    expect_true(!any(file.exists(files(exStudy)$db,
                                 files(exStudy)$binaries,
                                 # files(exStudy)$recordings$file,
                                 files(exStudy[[1]])$db,
                                 files(exStudy[[1]])$binaries)))
    exStudy <- updateFiles(exStudy, db=db, bin=bin, verbose=FALSE)
    # exStudy <- updateFiles(exStudy, db=db, bin=bin, recording = recs, verbose=FALSE)
    expect_true(all(file.exists(files(exStudy)$db,
                                files(exStudy)$binaries,
                                # files(exStudy)$recordings$file,
                                files(exStudy[[1]])$db,
                                files(exStudy[[1]])$binaries)))
    recs <- system.file('extdata', 'Recordings', package='PAMpal')
    exStudy <- addRecordings(exStudy, folder =recs, log=FALSE, progress=FALSE)
    # files(exStudy)$recordings$file <- substr(files(exStudy)$recordings$file, start=5, stop=10e3)
    files(exStudy)$recordings$file <-
        gsub(dirname(recs), 'New/Directory',
             files(exStudy)$recordings$file)
    expect_true(!any(file.exists(files(exStudy)$recordings$file)))
    exStudy <- updateFiles(exStudy, recording=recs, verbose=FALSE)
    expect_true(all(file.exists(files(exStudy)$recordings$file)))
})

test_that('Test bindStudies', {
    data(exStudy)
    expect_warning(bind2 <- bindStudies(exStudy, exStudy), 'Duplicate names')
    expect_equal(nClicks(exStudy)*2, nClicks(bind2))
    bind2list <- expect_warning(bindStudies(list(exStudy, exStudy)))
    expect_equal(nClicks(exStudy)*2, nClicks(bind2list))
})

test_that('Test hydrophone depth', {
    data(exStudy)
    exStudy <- addHydrophoneDepth(exStudy, depth=10)
    clicks <- getClickData(exStudy)
    expect_true('hpDepth' %in% colnames(clicks))
    expect_equal(10, clicks$hpDepth[1])
})

test_that('Test annotation stuff', {
    exPps <- new('PAMpalSettings')
    exPps <- addDatabase(exPps, system.file('extdata', 'Example.sqlite3', package='PAMpal'), verbose=FALSE)
    exPps <- addBinaries(exPps, system.file('extdata', 'Binaries', package='PAMpal'), verbose=FALSE)
    exClick <- function(data) {
        standardClickCalcs(data, calibration=NULL, filterfrom_khz = 0)
    }
    exPps <- addFunction(exPps, exClick, module = 'ClickDetector', verbose=FALSE)
    exPps <- addFunction(exPps, roccaWhistleCalcs, module='WhistlesMoans', verbose=FALSE)
    exPps <- addFunction(exPps, standardCepstrumCalcs, module = 'Cepstrum', verbose=FALSE)
    exData <- processPgDetections(exPps, mode='db', id='Example', progress = FALSE, verbose = FALSE)

    exData <- addGps(exData, thresh=365*24*3600)
    exData <- setSpecies(exData, 'pamguard')
    anno <- prepAnnotation(exData)
    expect_warning(checkAnnotation(anno), 'Fill in data for')
    anno$source <- 'test'
    anno$annotator <- 'me'
    anno$contact <- 'me'
    recUrl <- data.frame(matchId = names(events(exData)),
                         filestart = min(getClickData(exData)$UTC),
                         recording_url = paste0(1:3, 'test.com'))
    anno <- matchRecordingUrl(anno, recUrl)
    expect_message(checkAnnotation(anno), 'Also missing')
    exData <- addAnnotation(exData, anno, verbose = FALSE)
    expect_identical(anno, getAnnotation(exData))
    expect_message(export_annomate(exData), 'Also missing')
    expect_identical(export_annomate(exData), export_annomate(anno))
})

test_that('Test spec anno marking', {
    data("exStudy")
    anno <- data.frame(
        start = as.POSIXct('2018-03-20 15:25:10', tz='UTC'),
        fmin = c(16000, 17000, 18000, 20000),
        fmax = c(17000, 18000, 19000, 24000))
    anno$end <- anno$start + 1
    exStudy <- markAnnotated(exStudy, anno)
    expect_true(all(getClickData(exStudy)$inAnno[c(1,3)]))
    expect_true(!any(getClickData(exStudy)$inAnno[c(2,4)]))
    expect_true(!any(getWhistleData(exStudy)$inAnno))
    exStudy <- markAnnotated(exStudy, anno, tBuffer=c(0,1.5))
    expect_true(all(getWhistleData(exStudy)$inAnno[c(3,4,5,6,7,10,11,12,13,14)]))
    expect_true(all(getCepstrumData(exStudy)$inAnno))
    exStudy <- markAnnotated(exStudy, anno, tBuffer =c(0, 1.5), fBuffer = c(0, 400))
    expect_true(all(getWhistleData(exStudy)$inAnno[1:2]))
})

test_that('Test FPOD adding', {
    data('exStudy')
    fpodFile <- system.file('extdata', 'FPODExample.csv', package='PAMpal')
    exStudy <- addFPOD(exStudy, fpodFile)
    fpod <- getFPODData(exStudy)
    expect_equal(nrow(fpod), 8)
    expect_equal(nrow(exStudy[[1]][['FPOD']]), 4)
    filtStudy <- filter(exStudy, MaxPkLinear > 60)
    expect_equal(nrow(getFPODData(filtStudy)), 4)
    noFPOD <- filter(exStudy, detectorName != 'FPOD')
    expect_null(getFPODData(noFPOD))
    exStudy <- addFPOD(exStudy, fpodFile, detectorName='FPOD2')
    fpod <- getFPODData(exStudy)
    expect_equal(nrow(fpod), 16)
    expect_equal(nrow(exStudy[[1]][['FPOD2']]), 4)
})

test_that('Test subsampler', {
    data('exStudy')
    half <- sampleDetector(exStudy, n=0.5)
    expect_equal(nDetections(half), 12)
    two <- sampleDetector(exStudy, n=2)
    expect_equal(nDetections(two), 2 * 3 * 2)
    same <- sampleDetector(exStudy, n=Inf)
    expect_equal(nDetections(exStudy), nDetections(same))
    lessone <- sampleDetector(exStudy, n=-1)
    expect_equal(nDetections(lessone), 28 - 2 * 1 * 3)
    dropFive <- sampleDetector(exStudy, n=-5)
    expect_equal(nDetections(dropFive), 2 * 2)
    # same tests for event version
    event <- exStudy[[1]]
    half <- sampleDetector(event, n=.5)
    expect_equal(nDetections(half), 6)
    two <- sampleDetector(event, n=2)
    expect_equal(nDetections(two), 2*3)
    same <- sampleDetector(event, n=Inf)
    expect_equal(nDetections(same), nDetections(event))
    lessone <- sampleDetector(event, n=-1)
    expect_equal(nDetections(lessone), 14 - 1*3)
    lessHalf <- sampleDetector(event, n=-.5)
    expect_equal(nDetections(lessHalf), 14-6)
    dropFive <- sampleDetector(event, n=-5)
    expect_equal(nDetections(dropFive), 2)
})

test_that('Test measure functions', {
    data('exStudy')
    measList <- list('Example.OE1' = list(a=1, b=2),
                     'Example.OE2' = list(a=3, b=4))
    measDf <- data.frame(eventId = c('Example.OE1', 'Example.OE2'),
                         a = 4:5,
                         b = 6:7,
                         c = 10:11
    )
    exStudy <- addMeasures(exStudy, measList)
    outMeas <- getMeasures(exStudy)
    expect_identical(outMeas$a, c(1,3))
    exStudy <- addMeasures(exStudy, measDf, replace=FALSE)
    expect_identical(getMeasures(exStudy)$a, c(1,3))
    exStudy <- addMeasures(exStudy, measDf, replace=TRUE)
    expect_identical(getMeasures(exStudy)$a, 4:5)
    expect_identical(colnames(outMeas), c('eventId', 'a', 'b'))
    measDf$eventId <- c('Wrong', 'Name')
    expect_error(addMeasures(exStudy, measDf))
    measDf$eventId <- c('Example.OE1', 'Example.OE3')
    measDf$a <- 20:21
    exStudy <- addMeasures(exStudy, measDf, replace=TRUE)
    expect_equal(getMeasures(exStudy)$a, c(20, 5))
})

test_that('Test wav clip name parser',  {
    # so Det|Ev_db.OE#.UIDCH_TIME(14_3|8_6_3).wav
    posix <- as.POSIXct('2020-10-31 12:00:11', tz='UTC') + .5
    posixChar <- psxToChar(posix)
    evName <- paste0('folder/', 'Event_Databasename.OE4CH3_', posixChar, '.wav')
    detName <- paste0('folder/', 'Detection_Databasename.OE4.1234567CH3_', posixChar, '.wav')
    expect_equal(parseEventClipName(evName, part='event'), 'Databasename.OE4')
    expect_equal(parseEventClipName(evName, part='UID'), NA)
    expect_equal(parseEventClipName(detName, part='UID'), '1234567')
    expect_equal(parseEventClipName(evName, part='channel'), '3')
    expect_equal(parseEventClipName(evName, part='time'), posix)
    expect_equal(parseEventClipName(evName, part='UTC'), posix)
})
