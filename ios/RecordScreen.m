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

- (void) muteAudioInBuffer:(CMSampleBufferRef)sampleBuffer
{

    CMItemCount numSamples = CMSampleBufferGetNumSamples(sampleBuffer);
    NSUInteger channelIndex = 0;

    CMBlockBufferRef audioBlockBuffer = CMSampleBufferGetDataBuffer(sampleBuffer);
    size_t audioBlockBufferOffset = (channelIndex * numSamples * sizeof(SInt16));
    size_t lengthAtOffset = 0;
    size_t totalLength = 0;
    SInt16 *samples = NULL;
    CMBlockBufferGetDataPointer(audioBlockBuffer, audioBlockBufferOffset, &lengthAtOffset, &totalLength, (char **)(&samples));

    for (NSInteger i=0; i<numSamples; i++) {
        samples[i] = (SInt16)0;
    }
}

// H264は2または4の倍数の数値にしないと緑の縁が入ってしまうので、それを調整する関数
- (int) adjustMultipleOf2:(int)value;
{
    if (value % 2 == 1) {
        return value + 1;
    }
    return value;
}


RCT_EXPORT_MODULE()

RCT_EXPORT_METHOD(setup: (NSDictionary *)config)
{
    self.screenWidth = [RCTConvert int: config[@"width"]];
    self.screenHeight = [RCTConvert int: config[@"height"]];
    self.enableMic = [RCTConvert BOOL: config[@"mic"]];
}

RCT_REMAP_METHOD(startRecording, resolve:(RCTPromiseResolveBlock)resolve rejecte:(RCTPromiseRejectBlock)reject)
{
    self.screenRecorder = [RPScreenRecorder sharedRecorder];
    if (self.screenRecorder.isRecording) {
        return;
    }
    
    self.encounteredFirstBuffer = NO;
    
    NSArray *pathDocuments = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *outputURL = pathDocuments[0];

    NSString *videoOutPath = [[outputURL stringByAppendingPathComponent:[NSString stringWithFormat:@"%u", arc4random() % 1000]] stringByAppendingPathExtension:@"mp4"];
    
    NSError *error;
    self.writer = [AVAssetWriter assetWriterWithURL:[NSURL fileURLWithPath:videoOutPath] fileType:AVFileTypeMPEG4 error:&error];
    if (!self.writer) {
        NSLog(@"writer: %@", error);
        abort();
    }
    
    AudioChannelLayout acl = { 0 };
    acl.mChannelLayoutTag = kAudioChannelLayoutTag_Mono;
    self.audioInput = [[AVAssetWriterInput alloc] initWithMediaType:AVMediaTypeAudio outputSettings:@{ AVFormatIDKey: @(kAudioFormatMPEG4AAC), AVSampleRateKey: @(44100),  AVChannelLayoutKey: [NSData dataWithBytes: &acl length: sizeof( acl ) ], AVEncoderBitRateKey: @(64000)}];
    self.micInput = [[AVAssetWriterInput alloc] initWithMediaType:AVMediaTypeAudio outputSettings:@{ AVFormatIDKey: @(kAudioFormatMPEG4AAC), AVSampleRateKey: @(44100),  AVChannelLayoutKey: [NSData dataWithBytes: &acl length: sizeof( acl ) ], AVEncoderBitRateKey: @(64000)}];
    
    self.audioInput.preferredVolume = 0.0;
    self.micInput.preferredVolume = 0.0;
    
    NSDictionary *compressionProperties = @{AVVideoProfileLevelKey         : AVVideoProfileLevelH264HighAutoLevel,
                                            AVVideoH264EntropyModeKey      : AVVideoH264EntropyModeCABAC,
                                            AVVideoAverageBitRateKey       : @(1920 * 1080 * 114),
                                            AVVideoMaxKeyFrameIntervalKey  : @60,
                                            AVVideoAllowFrameReorderingKey : @NO};

    NSLog(@"width: %d", [self adjustMultipleOf2:self.screenWidth]);
    NSLog(@"height: %d", [self adjustMultipleOf2:self.screenHeight]);
    if (@available(iOS 11.0, *)) {
        NSDictionary *videoSettings = @{AVVideoCompressionPropertiesKey : compressionProperties,
                                        AVVideoCodecKey                 : AVVideoCodecTypeH264,
                                        AVVideoWidthKey                 : @([self adjustMultipleOf2:self.screenWidth]),
                                        AVVideoHeightKey                : @([self adjustMultipleOf2:self.screenHeight])};

        self.videoInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:videoSettings];
    } else {
        // Fallback on earlier versions
    }
    
    [self.writer addInput:self.audioInput];
    [self.writer addInput:self.micInput];
    [self.writer addInput:self.videoInput];
    [self.videoInput setMediaTimeScale:60];
    [self.writer setMovieTimeScale:60];
    [self.videoInput setExpectsMediaDataInRealTime:YES];

    if (self.enableMic) {
        self.screenRecorder.microphoneEnabled = YES;
    }
    
    [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (granted) {
                if (@available(iOS 11.0, *)) {
                    [self.screenRecorder startCaptureWithHandler:^(CMSampleBufferRef sampleBuffer, RPSampleBufferType bufferType, NSError* error) {
                        if (CMSampleBufferDataIsReady(sampleBuffer)) {
                            if (self.writer.status == AVAssetWriterStatusUnknown && !self.encounteredFirstBuffer && bufferType == RPSampleBufferTypeVideo) {
                                self.encounteredFirstBuffer = YES;
                                NSLog(@"First buffer video");
                                [self.writer startWriting];
                                [self.writer startSessionAtSourceTime:CMSampleBufferGetPresentationTimeStamp(sampleBuffer)];
                            } else if (self.writer.status == AVAssetWriterStatusFailed) {
                                
                            }
                            
                            if (self.writer.status == AVAssetWriterStatusWriting) {
                                switch (bufferType) {
                                    case RPSampleBufferTypeVideo:
                                        if (self.videoInput.isReadyForMoreMediaData) {
                                            [self.videoInput appendSampleBuffer:sampleBuffer];
                                        }
                                        break;
                                    case RPSampleBufferTypeAudioApp:
                                        if (self.audioInput.isReadyForMoreMediaData) {
                                            if(self.enableMic){
                                                [self.audioInput appendSampleBuffer:sampleBuffer];
                                            } else {
                                                [self muteAudioInBuffer:sampleBuffer];
                                            }
                                        }
                                        break;
                                    case RPSampleBufferTypeAudioMic:
                                        if (self.micInput.isReadyForMoreMediaData) {
                                            if(self.enableMic){
                                                [self.micInput appendSampleBuffer:sampleBuffer];
                                            } else {
                                                [self muteAudioInBuffer:sampleBuffer];
                                            }
                                        }
                                        break;
                                    default:
                                        break;
                                }
                            }
                        }
                    } completionHandler:^(NSError* error) {
                        NSLog(@"startCapture: %@", error);
                        resolve(@"started");
                    }];
                } else {
                    // Fallback on earlier versions
                }
            } else {
                NSError* err = nil;
                reject(0, @"Permission denied", err);
            }
        });
    }];

    if (self.enableMic) {
        self.screenRecorder.microphoneEnabled = YES;
    }
}

RCT_REMAP_METHOD(stopRecording, resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject)
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (@available(iOS 11.0, *)) {
            [[RPScreenRecorder sharedRecorder] stopCaptureWithHandler:^(NSError * _Nullable error) {
                if (!error) {
                    [self.audioInput markAsFinished];
                    [self.micInput markAsFinished];
                    [self.videoInput markAsFinished];
                    [self.writer finishWritingWithCompletionHandler:^{
                        
                        NSDictionary *result = [NSDictionary dictionaryWithObject:self.writer.outputURL.absoluteString forKey:@"outputURL"];
                        resolve([self successResponse:result]);
                        
                        //                    UISaveVideoAtPathToSavedPhotosAlbum(self.writer.outputURL.absoluteString, nil, nil, nil);
                        NSLog(@"finishWritingWithCompletionHandler: Recording stopped successfully. Cleaning up... %@", result);
                        self.audioInput = nil;
                        self.micInput = nil;
                        self.videoInput = nil;
                        self.writer = nil;
                        self.screenRecorder = nil;
                    }];
                }
            }];
        } else {
            // Fallback on earlier versions
        }
    });
}

RCT_REMAP_METHOD(clean,
                 cleanResolve:(RCTPromiseResolveBlock)resolve
                 cleanRejecte:(RCTPromiseRejectBlock)reject)
{

    NSArray *pathDocuments = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *path = pathDocuments[0];
    [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
    resolve(@"cleaned");
}

@end
