//
//  PHChoiceController.m
//

#import "PHChoiceController.h"

@implementation PHChoiceController {
    NSArray *_built;
}

- (NSString *)key {
    return [self.specifier propertyForKey:@"key"];
}

- (NSArray *)options {
    NSString *key = [self key];
    if ([key isEqualToString:@"dockEdge"]) {
        return @[@{@"title": @"右侧", @"value": @0},
                 @{@"title": @"左侧", @"value": @1}];
    }
    if ([key isEqualToString:@"hostStrategy"]) {
        return @[@{@"title": @"自动（依次尝试）", @"value": @0},
                 @{@"title": @"呈现器 UIScenePresentationManager", @"value": @1},
                 @{@"title": @"场景视图 SBApplicationSceneView", @"value": @2},
                 @{@"title": @"宿主视图 initWithScene:", @"value": @3}];
    }
    return @[];
}

- (NSArray *)specifiers {
    if (_built) return _built;
    NSMutableArray *a = [NSMutableArray array];
    [a addObject:[PSSpecifier groupSpecifierWithName:@"选择一项"]];
    id current = PHGetValue([self key]) ?: PHDefaultFor([self key]);
    for (NSDictionary *o in [self options]) {
        BOOL sel = [o[@"value"] isEqual:current];
        PSSpecifier *s = [PSSpecifier preferenceSpecifierNamed:(sel ? [NSString stringWithFormat:@"✓ %@", o[@"title"]] : o[@"title"])
                                                        target:self
                                                           set:nil get:nil detail:nil
                                                          cell:PSButtonCell edit:nil];
        [s setProperty:o[@"value"] forKey:@"value"];
        [s setButtonAction:@selector(choose:)];
        [a addObject:s];
    }
    _built = a;
    return _built;
}

- (void)choose:(PSSpecifier *)sender {
    PHSetValue([self key], [sender propertyForKey:@"value"]);
    [self.navigationController popViewControllerAnimated:YES];
}

@end
