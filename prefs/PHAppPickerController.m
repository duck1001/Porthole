//
//  PHAppPickerController.m
//  纯 UIKit 应用列表
//

#import "PHAppPickerController.h"
#import "PHPreferences.h"

static id PHCall0(id o, NSString *sel) {
    if (!o || ![o respondsToSelector:NSSelectorFromString(sel)]) return nil;
    return ((id (*)(id, SEL))objc_msgSend)(o, NSSelectorFromString(sel));
}

static NSArray<NSDictionary *> *PHInstalledApps(void) {
    NSMutableArray *out = [NSMutableArray array];
    NSMutableSet *seen = [NSMutableSet set];

    Class wsc = NSClassFromString(@"LSApplicationWorkspace");
    id ws = PHCall0(wsc, @"defaultWorkspace");
    NSArray *all = PHCall0(ws, @"allInstalledApplications");
    for (id proxy in all) {
        NSString *bid = PHCall0(proxy, @"bundleIdentifier");
        if (!bid.length || [seen containsObject:bid]) continue;
        if ([bid hasPrefix:@"com.apple."] && ![bid isEqualToString:@"com.apple.mobilesafari"]) continue;
        NSString *name = PHCall0(proxy, @"localizedName") ?: bid;
        [seen addObject:bid];
        [out addObject:@{@"name": name, @"bundle": bid}];
    }

    if (out.count == 0) {
        NSFileManager *fm = NSFileManager.defaultManager;
        NSMutableArray<NSString *> *paths = [NSMutableArray array];
        NSString *container = @"/var/containers/Bundle/Application";
        for (NSString *dir in [fm contentsOfDirectoryAtPath:container error:NULL]) {
            NSString *sub = [container stringByAppendingPathComponent:dir];
            for (NSString *item in [fm contentsOfDirectoryAtPath:sub error:NULL]) {
                if ([item.pathExtension isEqualToString:@"app"]) {
                    [paths addObject:[sub stringByAppendingPathComponent:item]];
                }
            }
        }
        for (NSString *item in [fm contentsOfDirectoryAtPath:@"/Applications" error:NULL]) {
            if ([item.pathExtension isEqualToString:@"app"]) {
                [paths addObject:[@"/Applications" stringByAppendingPathComponent:item]];
            }
        }
        for (NSString *appPath in paths) {
            NSDictionary *info = [NSDictionary dictionaryWithContentsOfFile:
                                  [appPath stringByAppendingPathComponent:@"Info.plist"]];
            NSString *bid = info[@"CFBundleIdentifier"];
            if (!bid.length || [seen containsObject:bid]) continue;
            if ([bid hasPrefix:@"com.apple."] && ![bid isEqualToString:@"com.apple.mobilesafari"]) continue;
            NSString *name = info[@"CFBundleDisplayName"] ?: info[@"CFBundleName"] ?: bid;
            [seen addObject:bid];
            [out addObject:@{@"name": name, @"bundle": bid}];
        }
    }

    [out sortUsingComparator:^NSComparisonResult(NSDictionary *a, NSDictionary *b) {
        return [a[@"name"] localizedCaseInsensitiveCompare:b[@"name"]];
    }];
    return out;
}

@interface PHAppPickerController ()
@property (nonatomic, strong) NSArray<NSDictionary *> *apps;
@end

@implementation PHAppPickerController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"目标应用";
    self.apps = PHInstalledApps();
    self.tableView.rowHeight = 46;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.apps.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"a"];
    if (!cell) cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"a"];
    NSDictionary *app = self.apps[indexPath.row];
    cell.textLabel.text = app[@"name"];
    cell.detailTextLabel.text = app[@"bundle"];
    cell.detailTextLabel.font = [UIFont systemFontOfSize:11];
    cell.detailTextLabel.textColor = UIColor.secondaryLabelColor;
    BOOL sel = [app[@"bundle"] isEqualToString:PHTargetBundle()];
    cell.accessoryType = sel ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSDictionary *app = self.apps[indexPath.row];
    PHSetValue(@"targetBundle", app[@"bundle"]);
    [self.navigationController popViewControllerAnimated:YES];
}

@end
