//
//  PHManager.h — 舷窗总控
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface PHManager : NSObject

+ (instancetype)shared;

- (void)start;
- (void)prefsChanged;
- (void)toggleTargetBundle;
- (void)closeWindowIfNeeded;

@end

/// 给别的插件/快捷指令用的入口
void PHOpenBundle(NSString *bundleID);

NS_ASSUME_NONNULL_END
