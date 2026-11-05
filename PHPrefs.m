//
//  PHPrefs.m
//

#import "PHPrefs.h"
#import "PHCommon.h"

NSString *const PHPrefsChangedNotification = @"com.milkway.porthole/prefs-changed";

static id PHPrefValue(NSString *key) {
    CFStringRef k = (__bridge CFStringRef)key;
    CFStringRef d = (__bridge CFStringRef)PH_DOMAIN;
    CFPropertyListRef v = CFPreferencesCopyValue(k, d, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
    return (__bridge_transfer id)v;
}

@implementation PHPrefs

+ (void)setValue:(id)value forKey:(NSString *)key {
    CFPreferencesSetValue((__bridge CFStringRef)key,
                          (__bridge CFPropertyListRef)value,
                          (__bridge CFStringRef)PH_DOMAIN,
                          kCFPreferencesCurrentUser,
                          kCFPreferencesAnyHost);
    CFPreferencesAppSynchronize((__bridge CFStringRef)PH_DOMAIN);
    CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(),
                                         (__bridge CFStringRef)PHPrefsChangedNotification,
                                         NULL, NULL, true);
}

+ (instancetype)shared {
    static PHPrefs *inst;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ inst = [PHPrefs new]; [inst reload]; });
    return inst;
}

- (void)reload {
    _enabled          = PHPrefValue(@"enabled") ? [PHPrefValue(@"enabled") boolValue] : YES;
    _targetBundle     = PHPrefValue(@"targetBundle") ?: @"com.apple.mobilesafari";
    _width            = PHPrefValue(@"width") ? [PHPrefValue(@"width") doubleValue] : 320.0;
    _height           = PHPrefValue(@"height") ? [PHPrefValue(@"height") doubleValue] : 420.0;
    _cornerRadius     = PHPrefValue(@"cornerRadius") ? [PHPrefValue(@"cornerRadius") doubleValue] : 22.0;
    _showDock         = PHPrefValue(@"showDock") ? [PHPrefValue(@"showDock") boolValue] : YES;
    _shadow           = PHPrefValue(@"shadow") ? [PHPrefValue(@"shadow") boolValue] : YES;
    _followOrientation = PHPrefValue(@"followOrientation") ? [PHPrefValue(@"followOrientation") boolValue] : YES;
    _dockEdge         = PHPrefValue(@"dockEdge") ? [PHPrefValue(@"dockEdge") integerValue] : 0;
    _hostStrategy     = PHPrefValue(@"hostStrategy") ? [PHPrefValue(@"hostStrategy") integerValue] : 0;
    _windowLevel      = PHPrefValue(@"windowLevel") ? [PHPrefValue(@"windowLevel") integerValue] : 1;
}

@end
