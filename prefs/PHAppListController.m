//
//  PHAppListController.m
//

#import "PHAppListController.h"

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
        // 系统 App 太多，只保留设置里常用的那个特例
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

@implementation PHAppListController {
    NSArray *_built;
}

- (NSArray *)specifiers {
    if (_built) return _built;
    NSMutableArray *a = [NSMutableArray array];
    [a addObject:[PSSpecifier groupSpecifierWithName:@"选择目标应用（需先启动到前台）"]];

    NSString *current = PHGetValue(@"targetBundle") ?: @"com.apple.mobilesafari";
    for (NSDictionary *app in PHInstalledApps()) {
        BOOL sel = [app[@"bundle"] isEqualToString:current];
        NSString *title = sel ? [NSString stringWithFormat:@"✓ %@", app[@"name"]] : app[@"name"];
        PSSpecifier *s = [PSSpecifier preferenceSpecifierNamed:title
                                                        target:self
                                                           set:nil get:nil detail:nil
                                                          cell:PSButtonCell edit:nil];
        [s setProperty:app[@"bundle"] forKey:@"bundle"];
        [s setButtonAction:@selector(choose:)];
        [a addObject:s];
    }
    _built = a;
    return _built;
}

- (void)choose:(PSSpecifier *)sender {
    NSString *bundle = [sender propertyForKey:@"bundle"];
    if (bundle.length) PHSetValue(@"targetBundle", bundle);
    [self.navigationController popViewControllerAnimated:YES];
}

@end
