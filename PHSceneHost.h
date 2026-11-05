//
//  PHSceneHost.h — 场景托管层
//
//  三条路径，按 prefs 的 hostStrategy 选择：
//    1 呈现器   UIScenePresentationManager → presenter → presentationView
//    2 场景视图 SBApplicationSceneView / SBSceneView initWithSceneHandle:
//    3 宿主视图 _UISceneHostingView initWithScene:debugDescription:
//    0 自动     依次尝试 1 → 2 → 3
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface PHSceneHost : NSObject

@property (nonatomic, strong, readonly, nullable) UIView *hostView;
@property (nonatomic, strong, readonly, nullable) id scene;
@property (nonatomic, strong, readonly, nullable) id app;
@property (nonatomic, copy, readonly) NSString *bundleID;
@property (nonatomic, copy, readonly) NSString *strategyName;
@property (nonatomic, copy, readonly) NSString *lastError;
@property (nonatomic, assign) BOOL verbose;

+ (instancetype)hostForBundle:(NSString *)bundleID strategy:(NSInteger)strategy;

- (BOOL)start;
- (void)applyFrame:(CGRect)frame;
- (void)stop;

@end

NS_ASSUME_NONNULL_END
