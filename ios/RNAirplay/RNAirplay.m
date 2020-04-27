#import "RNAirplay.h"
#import "RNAirplayManager.h"
#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import <MediaPlayer/MediaPlayer.h>

@implementation RNAirplay
{
  bool hasListeners;
}
@synthesize bridge = _bridge;



-(void)startObserving {
    hasListeners = YES;
    // Set up any upstream listeners or background tasks as necessary
}

// Will be called when this module's last listener is removed, or on dealloc.
-(void)stopObserving {
    hasListeners = NO;
    // Remove upstream listeners, stop unnecessary background tasks
}

- (dispatch_queue_t)methodQueue
{
    return dispatch_get_main_queue();
}

RCT_EXPORT_MODULE();

RCT_EXPORT_METHOD(startScan)
{
    printf("init Airplay");
    AVAudioSessionRouteDescription* currentRoute = [[AVAudioSession sharedInstance] currentRoute];
    BOOL isAvailable = NO;
    NSUInteger routeNum = [[currentRoute outputs] count];
    if(routeNum > 0) {
        isAvailable = YES;
        BOOL isConnected = YES;
        BOOL isMirroring = NO;
        if (isConnected) {
            if ([[UIScreen screens] count] < 2) {
                //streaming
                isMirroring = NO;
            } else {
                //mirroring
                isMirroring = YES;
            }
        }
        for (AVAudioSessionPortDescription * output in currentRoute.outputs) {
            if([output.portType isEqualToString:AVAudioSessionPortAirPlay] && hasListeners) {
                [self sendEventWithName:@"airplayConnected" body:@{@"connected": @(isConnected), @"mirroring": @(isMirroring)}];
            }
        }

        [[NSNotificationCenter defaultCenter]
         addObserver:self
         selector: @selector(airplayChanged:)
         name:MPVolumeViewWirelessRouteActiveDidChangeNotification
         object:nil];

    }
    // not currently listening for this event
    // [self sendEventWithName:@"airplayAvailable" body:@{@"available": @(isAvailable)}];
}

RCT_EXPORT_METHOD(disconnect)
{
    printf("disconnect Airplay");
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    // not currently listening for this event
    //[self sendEventWithName:@"airplayAvailable" body:@{@"available": @(NO) }];
}


- (void)airplayChanged:(NSNotification *)sender
{
    AVAudioSessionRouteDescription* currentRoute = [[AVAudioSession sharedInstance] currentRoute];

    BOOL isAirPlayPlaying = NO;
    BOOL isMirroring = NO;
    for (AVAudioSessionPortDescription* output in currentRoute.outputs) {
        if([output.portType isEqualToString:AVAudioSessionPortAirPlay]) {
            isAirPlayPlaying = YES;
            break;
        }
    }
    if (isAirPlayPlaying) {
        if ([[UIScreen screens] count] < 2) {
            //streaming
            isMirroring = NO;
        } else {
            //mirroring
            isMirroring = YES;
        }
    }
    if(hasListeners) {
        [self sendEventWithName:@"airplayConnected" body:@{@"connected": @(isAirPlayPlaying), @"mirroring": @(isMirroring)}];
    }
}

- (NSArray<NSString *> *)supportedEvents {
    return @[/*@"airplayAvailable",*/ @"airplayConnected"];
}


@end
