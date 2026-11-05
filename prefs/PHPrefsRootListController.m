//
//  PHPrefsRootListController.m
//

#import "PHPrefsRootListController.h"
#import "PHAppListController.h"
#import "PHChoiceController.h"
#import "PHLogController.h"

@implementation PHPrefsRootListController {
    NSArray *_built;
}

#pragma mark - PSSpecifier 工具

- (PSSpecifier *)group:(NSString *)name {
    return [PSSpecifier groupSpecifierWithName:name];
}

- (PSSpecifier *)switchRow:(NSString *)name key:(NSString *)key {
    PSSpecifier *s = [PSSpecifier preferenceSpecifierNamed:name
                                                    target:self
                                                       set:@selector(setValue:specifier:)
                                                       get:@selector(getValue:)
                                                    detail:nil
                                                      cell:PSSwitchCell
                                                      edit:nil];
    [s setProperty:key forKey:@"key"];
    return s;
}

- (PSSpecifier *)sliderRow:(NSString *)name key:(NSString *)key min:(double)min max:(double)max {
    PSSpecifier *s = [PSSpecifier preferenceSpecifierNamed:name
                                                    target:self
                                                       set:@selector(setValue:specifier:)
                                                       get:@selector(getValue:)
                                                    detail:nil
                                                      cell:PSSliderCell
                                                      edit:nil];
    [s setProperty:key forKey:@"key"];
    [s setProperty:@(min) forKey:@"minValue"];
    [s setProperty:@(max) forKey:@"maxValue"];
    [s setProperty:@YES forKey:@"isContinuous"];
    return s;
}

- (PSSpecifier *)linkRow:(NSString *)name key:(NSString *)key detail:(Class)detail {
    PSSpecifier *s = [PSSpecifier preferenceSpecifierNamed:name
                                                    target:self
                                                       set:nil
                                                       get:@selector(getValue:)
                                                    detail:detail
                                                      cell:PSLinkCell
                                                      edit:nil];
    [s setProperty:key forKey:@"key"];
    return s;
}

- (PSSpecifier *)buttonRow:(NSString *)name action:(SEL)action {
    PSSpecifier *s = [PSSpecifier preferenceSpecifierNamed:name
                                                    target:self
                                                       set:nil
                                                       get:nil
                                                    detail:nil
                                                      cell:PSButtonCell
                                                      edit:nil];
    [s setButtonAction:action];
    return s;
}

- (PSSpecifier *)staticRow:(NSString *)name {
    return [PSSpecifier preferenceSpecifierNamed:name
                                          target:nil set:nil get:nil detail:nil
                                            cell:PSStaticTextCell edit:nil];
}

#pragma mark - 取值

- (id)getValue:(PSSpecifier *)specifier {
    NSString *key = [specifier propertyForKey:@"key"];
    id v = PHGetValue(key);
    return v ?: PHDefaultFor(key);
}

- (void)setValue:(id)value specifier:(PSSpecifier *)specifier {
    NSString *key = [specifier propertyForKey:@"key"];
    PHSetValue(key, value);
}

- (id)readPreferenceValue:(PSSpecifier *)specifier {
    return [self getValue:specifier];
}

- (void)setPreferenceValue:(id)value specifier:(PSSpecifier *)specifier {
    [self setValue:value specifier:specifier];
}

#pragma mark - 列表

- (NSArray *)specifiers {
    if (_built) return _built;
    NSMutableArray *a = [NSMutableArray array];

    [a addObject:[self group:@"舷窗"]];
    [a addObject:[self switchRow:@"启用" key:@"enabled"]];
    [a addObject:[self switchRow:@"边缘把手" key:@"showDock"]];
    [a addObject:[self linkRow:@"目标应用" key:@"targetBundle" detail:[PHAppListController class]]];
    [a addObject:[self linkRow:@"停靠边" key:@"dockEdge" detail:[PHChoiceController class]]];
    [a addObject:[self switchRow:@"阴影" key:@"shadow"]];

    [a addObject:[self group:@"窗口"]];
    [a addObject:[self sliderRow:@"宽度" key:@"width" min:180 max:520]];
    [a addObject:[self sliderRow:@"高度" key:@"height" min:200 max:760]];
    [a addObject:[self sliderRow:@"圆角" key:@"cornerRadius" min:0 max:44]];

    [a addObject:[self group:@"托管方式"]];
    [a addObject:[self linkRow:@"场景托管" key:@"hostStrategy" detail:[PHChoiceController class]]];
    [a addObject:[self staticRow:@"自动会依次尝试 呈现器 → 场景视图 → 宿主视图。"]];

    [a addObject:[self group:@"调试"]];
    [a addObject:[self buttonRow:@"测试开关浮窗" action:@selector(testToggle)]];
    [a addObject:[self linkRow:@"黑匣子日志" key:@"__log" detail:[PHLogController class]]];
    [a addObject:[self buttonRow:@"清空日志" action:@selector(clearLog)]];
    [a addObject:[self buttonRow:@"重启 SpringBoard" action:@selector(respring)]];

    [a addObject:[self group:@"关于"]];
    [a addObject:[self staticRow:@"Porthole 0.1.1 — 舷窗"]];

    _built = a;
    return _built;
}

#pragma mark - 动作

- (void)testToggle {
    CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(),
                                         PH_TOGGLE_NAME, NULL, NULL, true);
}

- (void)clearLog {
    NSString *p = @"/var/mobile/Library/Porthole/porthole.log";
    [[NSFileManager defaultManager] createFileAtPath:p contents:nil attributes:nil];
    [[NSFileManager defaultManager] setAttributes:@{NSFilePosixPermissions: @0666}
                                     ofItemAtPath:p error:NULL];
    UIAlertController *al = [UIAlertController alertControllerWithTitle:@"黑匣子"
                                                               message:@"已清空"
                                                        preferredStyle:UIAlertControllerStyleAlert];
    [al addAction:[UIAlertAction actionWithTitle:@"好" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:al animated:YES completion:nil];
}

- (void)respring {
    UIAlertController *al = [UIAlertController alertControllerWithTitle:@"重启 SpringBoard"
                                                               message:@"确定要注销界面吗？"
                                                        preferredStyle:UIAlertControllerStyleAlert];
    [al addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    [al addAction:[UIAlertAction actionWithTitle:@"重启" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *x) {
        CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(),
                                             CFSTR("com.milkway.porthole/respring"), NULL, NULL, true);
    }]];
    [self presentViewController:al animated:YES completion:nil];
}

@end
