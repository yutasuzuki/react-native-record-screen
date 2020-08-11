#import <React/RCTBridgeModule.h>
#import <ReplayKit/ReplayKit.h>
#import <AVFoundation/AVFoundation.h>

@interface RecordScreen : NSObject <RCTBridgeModule>

    @property (strong, nonatomic) RPScreenRecorder *screenRecorder;
    @property (strong, nonatomic) RPPreviewViewController *previewViewController;
    @property (strong, nonatomic) AVAssetWriter *assetWriter;
    @property (strong, nonatomic) AVAssetWriterInput *assetWriterInput;
    @property (assign, nonatomic) int screenWidth;
    @property (assign, nonatomic) int screenHeight;
    @property (strong, nonatomic) NSDictionary *crop;

@end
