#import <React/RCTBridgeModule.h>
#import <ReplayKit/ReplayKit.h>
#import <AVFoundation/AVFoundation.h>

@interface RecordScreen : NSObject <RCTBridgeModule>

    @property (strong, nonatomic) RPScreenRecorder *screenRecorder;
    @property (strong, nonatomic) AVAssetWriterInput *videoInput;
    @property (strong, nonatomic) AVAssetWriterInput *audioInput;
    @property (strong, nonatomic) AVAssetWriterInput *micInput;
    @property (assign, nonatomic) int screenWidth;
    @property (assign, nonatomic) int screenHeight;
    @property (assign, nonatomic) BOOL enableMic;
    @property (assign, nonatomic) int fps;
    @property (assign, nonatomic) int bitrate;

    @property (nonatomic) AVAssetWriter *writer;
    @property BOOL encounteredFirstBuffer;
    @property CMSampleBufferRef afterAppBackgroundAudioSampleBuffer;
    @property CMSampleBufferRef afterAppBackgroundMicSampleBuffer;
    @property CMSampleBufferRef afterAppBackgroundVideoSampleBuffer;

@end
