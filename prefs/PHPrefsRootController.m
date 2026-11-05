//
//  PHPrefsRootController.m
//  纯 UIKit 设置面板
//

#import "PHPrefsRootController.h"
#import "PHPreferences.h"
#import "PHAppPickerController.h"
#import "PHChoiceController.h"
#import "PHLogViewController.h"

typedef NS_ENUM(NSInteger, PHRowType) {
    PHRowSwitch,
    PHRowSlider,
    PHRowLink,
    PHRowButton,
    PHRowInfo,
};

@interface PHRow : NSObject
@property (nonatomic, assign) PHRowType type;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *key;
@property (nonatomic, copy) NSString *action;
@property (nonatomic, assign) double minV;
@property (nonatomic, assign) double maxV;
@property (nonatomic, strong) NSArray *options;
+ (instancetype)row:(PHRowType)type title:(NSString *)title key:(NSString *)key;
@end

@implementation PHRow
+ (instancetype)row:(PHRowType)type title:(NSString *)title key:(NSString *)key {
    PHRow *r = [PHRow new];
    r.type = type;
    r.title = title;
    r.key = key;
    return r;
}
@end

#pragma mark - Cells

@interface PHSwitchCell : UITableViewCell
@property (nonatomic, strong) UISwitch *sw;
@end

@implementation PHSwitchCell
- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];
    if (self) {
        _sw = [UISwitch new];
        self.accessoryView = _sw;
        self.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    return self;
}
@end

@interface PHSliderCell : UITableViewCell
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *valueLabel;
@property (nonatomic, strong) UISlider *slider;
@end

@implementation PHSliderCell
- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        _titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _titleLabel.font = [UIFont systemFontOfSize:16];
        _titleLabel.textColor = UIColor.labelColor;
        [self.contentView addSubview:_titleLabel];

        _valueLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _valueLabel.font = [UIFont monospacedDigitSystemFontOfSize:14 weight:UIFontWeightRegular];
        _valueLabel.textColor = UIColor.secondaryLabelColor;
        _valueLabel.textAlignment = NSTextAlignmentRight;
        [self.contentView addSubview:_valueLabel];

        _slider = [[UISlider alloc] initWithFrame:CGRectZero];
        [self.contentView addSubview:_slider];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGRect b = self.contentView.bounds;
    _titleLabel.frame = CGRectMake(16, 6, b.size.width - 100, 22);
    _valueLabel.frame = CGRectMake(b.size.width - 84, 6, 68, 22);
    _slider.frame = CGRectMake(16, 32, b.size.width - 32, 30);
}
@end

#pragma mark - Root

@interface PHPrefsRootController ()
@property (nonatomic, strong) NSArray<NSArray<PHRow *> *> *sections;
@property (nonatomic, strong) NSArray<NSString *> *sectionTitles;
@end

@implementation PHPrefsRootController

- (instancetype)init {
    self = [super initWithStyle:UITableViewStyleInsetGrouped];
    return self;
}

// PreferenceLoader / PSListController 会按自己的接口往 detail 控制器上发消息，
// 这里把它们可能用到的入口全部实现成安全空实现，避免 doesNotRecognizeSelector 崩溃。
- (void)setSpecifier:(id)specifier {}
- (id)specifier { return nil; }
- (void)setRootController:(id)controller {}
- (id)rootController { return nil; }
- (void)setParentController:(id)controller {}
- (id)parentController { return nil; }
- (void)setBundle:(NSBundle *)bundle {}
- (NSBundle *)bundle { return [NSBundle bundleForClass:self.class]; }
- (void)setPreferenceValue:(id)value specifier:(id)specifier {}
- (id)readPreferenceValue:(id)specifier { return nil; }
- (void)reloadSpecifiers { [self.tableView reloadData]; }
- (void)showController:(id)controller {}
- (void)pushController:(id)controller {}
- (void)popController {}
- (void)setCells:(id)cells {}
- (id)cells { return nil; }
- (void)setProperty:(id)value forKey:(NSString *)key {}
- (id)propertyForKey:(NSString *)key { return nil; }
- (void)setPreferenceValue:(id)value specifier:(id)specifier animated:(BOOL)animated {}
- (void)setPreferenceValue:(id)value specifier:(id)specifier postNotification:(BOOL)post {}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Porthole";
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 48;
    [self buildSections];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(reload)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:nil];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)reload {
    [self.tableView reloadData];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.tableView reloadData];
}

- (void)buildSections {
    PHRow *enabled = [PHRow row:PHRowSwitch title:@"启用" key:@"enabled"];
    PHRow *dock = [PHRow row:PHRowSwitch title:@"边缘把手（悬浮球）" key:@"showDock"];
    PHRow *target = [PHRow row:PHRowLink title:@"目标应用" key:@"targetBundle"];
    PHRow *edge = [PHRow row:PHRowLink title:@"停靠边" key:@"dockEdge"];
    edge.options = @[@{@"title": @"右侧", @"value": @0}, @{@"title": @"左侧", @"value": @1}];
    PHRow *shadow = [PHRow row:PHRowSwitch title:@"阴影" key:@"shadow"];

    PHRow *w = [PHRow row:PHRowSlider title:@"宽度" key:@"width"];
    w.minV = 180; w.maxV = 520;
    PHRow *h = [PHRow row:PHRowSlider title:@"高度" key:@"height"];
    h.minV = 200; h.maxV = 760;
    PHRow *r = [PHRow row:PHRowSlider title:@"圆角" key:@"cornerRadius"];
    r.minV = 0; r.maxV = 44;

    PHRow *host = [PHRow row:PHRowLink title:@"场景托管" key:@"hostStrategy"];
    host.options = @[
        @{@"title": @"自动（依次尝试）", @"value": @0},
        @{@"title": @"呈现器 UIScenePresentationManager", @"value": @1},
        @{@"title": @"场景视图 SBApplicationSceneView", @"value": @2},
        @{@"title": @"宿主视图 initWithScene:", @"value": @3},
    ];

    PHRow *test = [PHRow row:PHRowButton title:@"测试开关浮窗" key:nil];
    test.action = @"testToggle";
    PHRow *log = [PHRow row:PHRowLink title:@"黑匣子日志" key:nil];
    log.action = @"openLog";
    PHRow *clear = [PHRow row:PHRowButton title:@"清空日志" key:nil];
    clear.action = @"clearLog";
    PHRow *respring = [PHRow row:PHRowButton title:@"注销 SpringBoard" key:nil];
    respring.action = @"respring";

    PHRow *about = [PHRow row:PHRowInfo title:@"Porthole 0.1.3 — 舷窗" key:nil];

    self.sectionTitles = @[@"舷窗", @"窗口", @"托管方式", @"调试", @"关于"];
    self.sections = @[@[enabled, dock, target, edge, shadow],
                      @[w, h, r],
                      @[host],
                      @[test, log, clear, respring],
                      @[about]];
}

#pragma mark - 取值显示

- (NSString *)displayValueForRow:(PHRow *)row {
    if ([row.key isEqualToString:@"targetBundle"]) {
        return PHTargetBundle();
    }
    if ([row.key isEqualToString:@"dockEdge"]) {
        return [PHValueOrDefault(@"dockEdge") integerValue] == 1 ? @"左侧" : @"右侧";
    }
    if ([row.key isEqualToString:@"hostStrategy"]) {
        NSInteger v = [PHValueOrDefault(@"hostStrategy") integerValue];
        NSArray *titles = @[@"自动", @"呈现器", @"场景视图", @"宿主视图"];
        return (v >= 0 && v < (NSInteger)titles.count) ? titles[v] : @"自动";
    }
    return nil;
}

#pragma mark - Table

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.sections.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return self.sectionTitles[section];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.sections[section].count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    PHRow *row = self.sections[indexPath.section][indexPath.row];

    switch (row.type) {
        case PHRowSwitch: {
            PHSwitchCell *cell = [tableView dequeueReusableCellWithIdentifier:@"sw"];
            if (!cell) cell = [[PHSwitchCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"sw"];
            cell.textLabel.text = row.title;
            cell.sw.on = [PHValueOrDefault(row.key) boolValue];
            cell.sw.tag = indexPath.section * 1000 + indexPath.row;
            [cell.sw removeTarget:self action:@selector(onSwitch:) forControlEvents:UIControlEventValueChanged];
            [cell.sw addTarget:self action:@selector(onSwitch:) forControlEvents:UIControlEventValueChanged];
            return cell;
        }
        case PHRowSlider: {
            PHSliderCell *cell = [tableView dequeueReusableCellWithIdentifier:@"sl"];
            if (!cell) cell = [[PHSliderCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"sl"];
            cell.titleLabel.text = row.title;
            cell.slider.minimumValue = row.minV;
            cell.slider.maximumValue = row.maxV;
            double v = [PHValueOrDefault(row.key) doubleValue];
            cell.slider.value = MAX(row.minV, MIN(row.maxV, v));
            cell.valueLabel.text = [NSString stringWithFormat:@"%.0f", cell.slider.value];
            cell.slider.tag = indexPath.section * 1000 + indexPath.row;
            [cell.slider removeTarget:self action:@selector(onSlider:) forControlEvents:UIControlEventValueChanged];
            [cell.slider addTarget:self action:@selector(onSlider:) forControlEvents:UIControlEventValueChanged];
            return cell;
        }
        case PHRowLink: {
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ln"];
            if (!cell) cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"ln"];
            cell.textLabel.text = row.title;
            cell.detailTextLabel.text = [self displayValueForRow:row];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.selectionStyle = UITableViewCellSelectionStyleDefault;
            return cell;
        }
        case PHRowButton: {
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"bt"];
            if (!cell) cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"bt"];
            cell.textLabel.text = row.title;
            cell.textLabel.textColor = self.view.tintColor;
            cell.textLabel.textAlignment = NSTextAlignmentCenter;
            cell.accessoryType = UITableViewCellAccessoryNone;
            cell.selectionStyle = UITableViewCellSelectionStyleDefault;
            return cell;
        }
        case PHRowInfo: {
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"in"];
            if (!cell) cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"in"];
            cell.textLabel.text = row.title;
            cell.textLabel.textColor = UIColor.secondaryLabelColor;
            cell.textLabel.font = [UIFont systemFontOfSize:13];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            return cell;
        }
    }
    return [UITableViewCell new];
}

- (PHRow *)rowForIndexPath:(NSIndexPath *)indexPath {
    return self.sections[indexPath.section][indexPath.row];
}

- (void)onSwitch:(UISwitch *)sw {
    NSInteger s = sw.tag / 1000, r = sw.tag % 1000;
    PHRow *row = self.sections[s][r];
    PHSetValue(row.key, @(sw.isOn));
}

- (void)onSlider:(UISlider *)slider {
    NSInteger s = slider.tag / 1000, r = slider.tag % 1000;
    PHRow *row = self.sections[s][r];
    NSIndexPath *ip = [NSIndexPath indexPathForRow:r inSection:s];
    PHSliderCell *cell = (PHSliderCell *)[self.tableView cellForRowAtIndexPath:ip];
    cell.valueLabel.text = [NSString stringWithFormat:@"%.0f", slider.value];
    PHSetValue(row.key, @(round(slider.value)));
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    PHRow *row = [self rowForIndexPath:indexPath];

    if (row.type == PHRowLink) {
        UIViewController *vc = nil;
        if ([row.key isEqualToString:@"targetBundle"]) {
            vc = [PHAppPickerController new];
        } else if (row.options.count) {
            vc = [[PHChoiceController alloc] initWithTitle:row.title key:row.key options:row.options];
        } else if ([row.action isEqualToString:@"openLog"]) {
            vc = [PHLogViewController new];
        }
        if (vc) [self.navigationController pushViewController:vc animated:YES];
        return;
    }

    if (row.type == PHRowButton) {
        SEL sel = NSSelectorFromString(row.action);
        if ([self respondsToSelector:sel]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
            [self performSelector:sel];
#pragma clang diagnostic pop
        }
    }
}

#pragma mark - 动作

- (void)testToggle {
    CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(),
                                         PH_TOGGLE_NAME, NULL, NULL, true);
}

- (void)openLog {
    [self.navigationController pushViewController:[PHLogViewController new] animated:YES];
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
    UIAlertController *al = [UIAlertController alertControllerWithTitle:@"注销 SpringBoard"
                                                               message:@"确定要重启界面吗？"
                                                        preferredStyle:UIAlertControllerStyleAlert];
    [al addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    [al addAction:[UIAlertAction actionWithTitle:@"注销" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *x) {
        CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(),
                                             PH_RESPRING_NAME, NULL, NULL, true);
    }]];
    [self presentViewController:al animated:YES completion:nil];
}

@end
