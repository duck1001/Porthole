//
//  PHPreferences.h
//  纯 UIKit 设置面板：不依赖 Preferences 私有框架
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <objc/message.h>

#define PH_DOMAIN @"com.milkway.porthole"
#define PH_NOTIFY_NAME CFSTR("com.milkway.porthole/prefs-changed")
#define PH_TOGGLE_NAME CFSTR("com.milkway.porthole/toggle")
#define PH_RESPRING_NAME CFSTR("com.milkway.porthole/respring")

static inline id PHGetValue(NSString *key) {
    CFPropertyListRef v = CFPreferencesCopyValue((__bridge CFStringRef)key,
                                                 (__bridge CFStringRef)PH_DOMAIN,
                                                 kCFPreferencesCurrentUser,
                                                 kCFPreferencesAnyHost);
    return (__bridge_transfer id)v;
}

static inline void PHSetValue(NSString *key, id value) {
    CFPreferencesSetValue((__bridge CFStringRef)key,
                          (__bridge CFPropertyListRef)value,
                          (__bridge CFStringRef)PH_DOMAIN,
                          kCFPreferencesCurrentUser,
                          kCFPreferencesAnyHost);
    CFPreferencesAppSynchronize((__bridge CFStringRef)PH_DOMAIN);
    CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(),
                                         PH_NOTIFY_NAME, NULL, NULL, true);
}

static inline id PHDefaultFor(NSString *key) {
    if ([key isEqualToString:@"enabled"]) return @YES;
    if ([key isEqualToString:@"targetBundle"]) return @"com.apple.mobilesafari";
    if ([key isEqualToString:@"width"]) return @320;
    if ([key isEqualToString:@"height"]) return @420;
    if ([key isEqualToString:@"cornerRadius"]) return @22;
    if ([key isEqualToString:@"showDock"]) return @YES;
    if ([key isEqualToString:@"shadow"]) return @YES;
    if ([key isEqualToString:@"dockEdge"]) return @0;
    if ([key isEqualToString:@"hostStrategy"]) return @0;
    return nil;
}

static inline id PHValueOrDefault(NSString *key) {
    id v = PHGetValue(key);
    return v ?: PHDefaultFor(key);
}

static inline NSString *PHTargetBundle(void) {
    id v = PHGetValue(@"targetBundle");
    return [v isKindOfClass:NSString.class] ? v : @"com.apple.mobilesafari";
}
