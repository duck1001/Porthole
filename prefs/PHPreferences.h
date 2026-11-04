//
//  PHPreferences.h — 设置面板公共声明
//
//  这里不引 Preferences 私有头，避免依赖 SDK 里没有的框架头文件；
//  PSListController / PSSpecifier 只声明用到的部分，运行时由 Preferences 进程提供。
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <objc/message.h>

#define PH_DOMAIN @"com.milkway.porthole"
#define PH_NOTIFY_NAME CFSTR("com.milkway.porthole/prefs-changed")
#define PH_TOGGLE_NAME CFSTR("com.milkway.porthole/toggle")

typedef NS_ENUM(NSInteger, PSCellType) {
    PSGroupCell        = 0,
    PSLinkCell         = 1,
    PSButtonCell       = 2,
    PSSwitchCell       = 3,
    PSRadioGroupCell   = 4,
    PSLinkListCell     = 5,
    PSListItemCell     = 6,
    PSTitleValueCell   = 7,
    PSSliderCell       = 8,
    PSStaticTextCell   = 9,
    PSSubtitleSwitchCell = 10,
    PSSubtitleButtonCell = 11,
};

@interface PSSpecifier : NSObject
+ (instancetype)preferenceSpecifierNamed:(NSString *)name
                                  target:(id)target
                                     set:(SEL)setter
                                     get:(SEL)getter
                                  detail:(Class)detail
                                    cell:(long)cell
                                    edit:(Class)edit;
+ (instancetype)groupSpecifierWithName:(NSString *)name;
- (void)setProperty:(id)value forKey:(NSString *)key;
- (id)propertyForKey:(NSString *)key;
- (void)setButtonAction:(SEL)action;
- (void)setTarget:(id)target;
- (NSString *)identifier;
@end

@interface PSListController : UIViewController
@property (nonatomic, strong) PSSpecifier *specifier;
- (NSArray *)specifiers;
- (void)setSpecifiers:(NSArray *)specifiers;
- (id)specifierForID:(NSString *)identifier;
- (void)reloadSpecifiers;
- (void)reload;
- (void)pushController:(UIViewController *)controller;
- (void)setTitle:(NSString *)title;
- (id)readPreferenceValue:(PSSpecifier *)specifier;
- (void)setPreferenceValue:(id)value specifier:(PSSpecifier *)specifier;
@end

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
    if ([key isEqualToString:@"followOrientation"]) return @YES;
    if ([key isEqualToString:@"dockEdge"]) return @0;
    if ([key isEqualToString:@"hostStrategy"]) return @0;
    if ([key isEqualToString:@"windowLevel"]) return @1;
    return nil;
}
