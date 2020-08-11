#import "RecordScreen.h"
#import <React/RCTConvert.h>

@implementation RecordScreen

const int DEFAULT_FPS = 30;

- (NSDictionary *)errorResponse:(NSDictionary *)result;
{
    NSDictionary *json = [NSDictionary dictionaryWithObjectsAndKeys:
        @"error", @"status",
        result, @"result",nil];
    return json;

}

- (NSDictionary *) successResponse:(NSDictionary *)result;
{
    NSDictionary *json = [NSDictionary dictionaryWithObjectsAndKeys:
        @"success", @"status",
        result, @"result",nil];
    return json;

}

- (void) cropMovie: (NSString *)inputFilePath resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject;
{
    float w = [RCTConvert float:self.crop[@"width"]];
    float h = [RCTConvert float:self.crop[@"height"]];
    float x = [RCTConvert float:self.crop[@"x"]];
    float y = [RCTConvert float:self.crop[@"y"]];
    int fps = self.crop[@"fps"] ? [RCTConvert int:self.crop[@"fps"]] : DEFAULT_FPS;

    NSString *path = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *inputPath = [inputFilePath stringByReplacingOccurrencesOfString:@"file://" withString:@""];
    NSString *outputPath = [[path stringByAppendingPathComponent:@"result"] stringByAppendingPathExtension:@"mp4"];

    AVMutableComposition *composition = [AVMutableComposition composition];
    AVMutableCompositionTrack *compositionVideoTrack = [composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
//    AVMutableCompositionTrack *compositionAudioTrack = [composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
    NSError *error;

    NSURL *inputURL = [NSURL fileURLWithPath:inputPath];
    AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:inputURL options:nil];
    CMTimeRange range = CMTimeRangeMake(kCMTimeZero, asset.duration);

    AVAssetTrack *videoTrack;
//    AVAssetTrack *audioTrack;

    if ([asset tracksWithMediaType:AVMediaTypeVideo]) {
        videoTrack = [asset tracksWithMediaType:AVMediaTypeVideo][0];
        [compositionVideoTrack insertTimeRange:range ofTrack:videoTrack atTime:kCMTimeZero error:&error];
    }

//    if (isAudio) {
//        AVMutableCompositionTrack *compositionAudioTrack = [composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
//        AVAssetTrack *audioTrack;
//        audioTrack = [asset tracksWithMediaType:AVMediaTypeAudio][0];
//        [compositionAudioTrack insertTimeRange:range ofTrack:audioTrack atTime:kCMTimeZero error:&error];
//    }

//    if ([asset tracksWithMediaType:AVMediaTypeAudio]) {
//        audioTrack = [asset tracksWithMediaType:AVMediaTypeAudio][0];
//        [compositionAudioTrack insertTimeRange:range ofTrack:audioTrack atTime:kCMTimeZero error:&error];
//    }

    AVMutableVideoCompositionInstruction *instruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
    instruction.timeRange = range;

    AVMutableVideoCompositionLayerInstruction *layerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:compositionVideoTrack];

    CGSize videoSize = videoTrack.naturalSize;
    CGAffineTransform transform = videoTrack.preferredTransform;;

    videoSize = CGSizeMake(w, h);
    transform = CGAffineTransformConcat(transform, CGAffineTransformMakeTranslation(x, -y));

    [layerInstruction setTransform:transform atTime:kCMTimeZero];
    instruction.layerInstructions = @[layerInstruction];

    AVMutableVideoComposition *videoComposition = [AVMutableVideoComposition videoComposition];
    videoComposition.renderSize = videoSize;
    videoComposition.instructions = @[instruction];
    videoComposition.frameDuration = CMTimeMake(1, fps);

    NSFileManager *fm = [NSFileManager defaultManager];
    if ([fm fileExistsAtPath:outputPath]) {
        [fm removeItemAtPath:outputPath error:&error];
    }

    AVAssetExportSession *session = [[AVAssetExportSession alloc] initWithAsset:composition presetName:AVAssetExportPresetHighestQuality];
    session.outputURL = [NSURL fileURLWithPath:outputPath];
    session.outputFileType = AVFileTypeQuickTimeMovie;
    session.videoComposition = videoComposition;

    [session exportAsynchronouslyWithCompletionHandler:^{
        if (session.status == AVAssetExportSessionStatusCompleted) {
            NSLog(@"output complete!");
            NSDictionary *result = [NSDictionary dictionaryWithObject:session.outputURL.absoluteString forKey:@"outputURL"];
            self.assetWriterInput = nil;
            self.assetWriter = nil;
            self.screenRecorder = nil;
            resolve([self successResponse:result]);
        } else {
            reject(@"error", @"output error", session.error);
        }
    }];
}

RCT_EXPORT_MODULE()

RCT_EXPORT_METHOD(setup: (NSDictionary *)config)
{
    self.screenWidth = [RCTConvert int: config[@"width"]];
    self.screenHeight = [RCTConvert int: config[@"height"]];
    self.crop = config[@"crop"] ? [RCTConvert NSDictionary: config[@"crop"]] : nil;
}

RCT_REMAP_METHOD(startRecording, resolve:(RCTPromiseResolveBlock)resolve rejecte:(RCTPromiseRejectBlock)reject)
{
    self.screenRecorder = [RPScreenRecorder sharedRecorder];
    if (self.screenRecorder.isRecording) {
        return;
    }
    NSError *error = nil;
    NSArray *pathDocuments = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *outputURL = pathDocuments[0];

    NSString *videoOutPath = [[outputURL stringByAppendingPathComponent:[NSString stringWithFormat:@"%u", arc4random() % 1000]] stringByAppendingPathExtension:@"mp4"];
    self.assetWriter = [AVAssetWriter assetWriterWithURL:[NSURL fileURLWithPath:videoOutPath] fileType:AVFileTypeMPEG4 error:&error];

    NSDictionary *compressionProperties = @{AVVideoProfileLevelKey         : AVVideoProfileLevelH264HighAutoLevel,
                                            AVVideoH264EntropyModeKey      : AVVideoH264EntropyModeCABAC,
                                            AVVideoAverageBitRateKey       : @(1920 * 1080 * 114),
                                            AVVideoMaxKeyFrameIntervalKey  : @60,
                                            AVVideoAllowFrameReorderingKey : @NO};

    if (@available(iOS 11.0, *)) {
        NSDictionary *videoSettings = @{AVVideoCompressionPropertiesKey : compressionProperties,
                                        AVVideoCodecKey                 : AVVideoCodecTypeH264,
                                        AVVideoWidthKey                 : @(self.screenWidth),
                                        AVVideoHeightKey                : @(self.screenHeight)};

        self.assetWriterInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:videoSettings];
    } else {
        // Fallback on earlier versions
    }



    [self.assetWriter addInput:self.assetWriterInput];
    [self.assetWriterInput setMediaTimeScale:60];
    [self.assetWriter setMovieTimeScale:60];
    [self.assetWriterInput setExpectsMediaDataInRealTime:YES];

    if (@available(iOS 11.0, *)) {
        [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (granted) {
                    [self.screenRecorder startCaptureWithHandler:^(CMSampleBufferRef  _Nonnull sampleBuffer, RPSampleBufferType bufferType, NSError * _Nullable error) {
                        if (CMSampleBufferDataIsReady(sampleBuffer)) {
                            NSLog(@"AVAssetWriterStatusWriting! %ld", AVAssetWriterStatusWriting);
                            if (self.assetWriter.status == AVAssetWriterStatusUnknown && bufferType == RPSampleBufferTypeVideo) {
                                [self.assetWriter startWriting];
                                [self.assetWriter startSessionAtSourceTime:CMSampleBufferGetPresentationTimeStamp(sampleBuffer)];
                            }
                            if (self.assetWriter.status == AVAssetWriterStatusFailed) {
                                [[RPScreenRecorder sharedRecorder] stopCaptureWithHandler:^(NSError * _Nullable error) {
                                    NSLog(@"self.assetWriter.status! %ld", self.assetWriter.status);
                                    NSLog(@"AVAssetWriterStatusFailed! %ld", AVAssetWriterStatusFailed);
                                    NSLog(@"isReadyForMoreMediaData! %d", self.assetWriterInput.isReadyForMoreMediaData);
                                    self.assetWriterInput = nil;
                                    self.assetWriter = nil;
                                    self.screenRecorder = nil;
                                }];
                                reject(@"error", @"An error occured", error);
                                return;
                            }
                            if (bufferType == RPSampleBufferTypeVideo) {
                                if (self.assetWriterInput.isReadyForMoreMediaData) {
                                    [self.assetWriterInput appendSampleBuffer:sampleBuffer];
                                }
                            }
                        }
                    } completionHandler:^(NSError * _Nullable error) {
                        if (!error) {
                            AVAudioSession *session = [AVAudioSession sharedInstance];
                            [session setActive:YES error:nil];
                            // Start recording
                            NSLog(@"Recording start");
//                            resolve([NSDictionary dictionaryWithObjectsAndKeys: @"success", @"status", nil]);
                        } else {
                            //show alert
                            reject(@"error", @"Recording not active", error);
                        }
                    }];
                }
            });
        }];


    } else {
        // Fallback on earlier versions
    }

}

RCT_REMAP_METHOD(stopRecording, resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject)
{
    if (@available(iOS 11.0, *)) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [[RPScreenRecorder sharedRecorder] stopCaptureWithHandler:^(NSError * _Nullable error) {
                if (!error) {
                    [self.assetWriterInput markAsFinished];
                    [self.assetWriter finishWritingWithCompletionHandler:^{
                        if (self.crop) {
                            [self cropMovie:self.assetWriter.outputURL.relativeString resolver:resolve rejecter:reject];
                        } else {
                            NSDictionary *result = [NSDictionary dictionaryWithObject:self.assetWriter.outputURL.absoluteString forKey:@"outputURL"];
                            resolve([self successResponse:result]);
                        }
                        NSLog(@"finishWritingWithCompletionHandler: Recording stopped successfully. Cleaning up...");
                        self.assetWriterInput = nil;
                        self.assetWriter = nil;
                        self.screenRecorder = nil;
                    }];
                }
            }];
        });

    } else {
        // Fallback on earlier versions
        reject(@"error", @"Not supported device", nil);
    }

}

//RCT_REMAP_METHOD(getRecordStatus, getRecordStatusResolve:(RCTPromiseResolveBlock)resolve getRecordStatusRejecte:(RCTPromiseRejectBlock)reject) {
//    _screenRecorder = [RPScreenRecorder sharedRecorder];
//    if (_screenRecorder.isRecording) {
//        resolve([NSDictionary dictionaryWithObjectsAndKeys:
//                 [NSNumber numberWithBool:YES], @"status", nil]);
//    } else {
//        resolve([NSDictionary dictionaryWithObjectsAndKeys:
//                 [NSNumber numberWithBool:NO], @"status", nil]);
//    }
//}

RCT_REMAP_METHOD(clean,
                 cleanResolve:(RCTPromiseResolveBlock)resolve
                 cleanRejecte:(RCTPromiseRejectBlock)reject)
{

    NSArray *pathDocuments = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *path = pathDocuments[0];
    [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
    resolve(@"cleaned");
//    if (filename) {
//        NSFileManager *fileMamager = [NSFileManager defaultManager];
//        NSDirectoryEnumerator *enumerator = [fileMamager enumeratorAtPath:path];
//        NSString *name;
//        BOOL isDir;
//        while (name = [enumerator nextObject]) {
//            NSString *fullPath = [path stringByAppendingPathComponent:name];
//            [fileMamager fileExistsAtPath:fullPath isDirectory:&isDir];
//            if (!isDir) {
//                NSLog(@"%@", fullPath);
//            }
//        }
//    } else {
//        [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
//    }
}

//RCT_EXPORT_BLOCKING_SYNCHRONOUS_METHOD(isRecording) {
//  _screenRecorder = [RPScreenRecorder sharedRecorder];
//  return _screenRecorder.isRecording && videoWriter != nil && videoWriter?.status == .writing
//}


//#if RCT_DEV
//- (BOOL)bridge:(RCTBridge *)bridge didNotFindModule:(NSString *)moduleName {
//  return YES;
//}
//#endif

@end


