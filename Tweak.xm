//
//  Tweak.xm — Porthole 注入入口
//

#import "PHManager.h"
#import "PHCommon.h"
#import "PHLog.h"
#import <signal.h>

static void PHNotifyCallback(CFNotificationCenterRef center,
                             void *observer,
                             CFStringRef name,
                             const void *object,
                             CFDictionaryRef userInfo) {
    NSString *n = (__bridge NSString *)name;
    if ([n isEqualToString:@"com.milkway.porthole/prefs-changed"]) {
        [[PHManager shared] prefsChanged];
    } else if ([n isEqualToString:@"com.milkway.porthole/toggle"]) {
        [[PHManager shared] toggleTargetBundle];
    } else if ([n isEqualToString:@"com.milkway.porthole/respring"]) {
        kill(getpid(), SIGTERM);
    }
}

%hook SpringBoard

- (void)applicationDidFinishLaunching:(id)application {
    %orig;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        [[PHManager shared] start];
    });
}

%end

%ctor {
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),
                                   NULL,
                                   PHNotifyCallback,
                                   CFSTR("com.milkway.porthole/prefs-changed"),
                                   NULL,
                                   CFNotificationSuspensionBehaviorDeliverImmediately);
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),
                                   NULL,
                                   PHNotifyCallback,
                                   CFSTR("com.milkway.porthole/toggle"),
                                   NULL,
                                   CFNotificationSuspensionBehaviorDeliverImmediately);
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),
                                   NULL,
                                   PHNotifyCallback,
                                   CFSTR("com.milkway.porthole/respring"),
                                   NULL,
                                   CFNotificationSuspensionBehaviorDeliverImmediately);

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(6.0 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        [[PHManager shared] start];
    });
}
