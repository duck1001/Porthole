# Porthole · 舷窗

把第三方 App 装进一个可拖动、可缩放的浮动窗口。roothide 专用。

## 结构

```
Porthole/
├── Tweak.xm                  注入入口（SpringBoard）
├── PHManager.{h,m}           总控：把手 + 浮窗 + 配置联动
├── PHSceneHost.{h,m}         场景托管层（三条路径）
├── PHWindow.{h,m}            浮窗窗口：标题条、拖动、缩放、全屏
├── PHDock.{h,m}              边缘把手
├── PHPrefs.{h,m}             配置读取
├── PHLog.{h,m}               黑匣子日志
├── prefs/                    设置面板（PreferenceBundle）
└── .github/workflows/build.yml
```

## 场景托管的三条路径

设置里「场景托管」可选，默认自动依次尝试：

1. **呈现器** — `[FBScene uiPresentationManager]` → `createPresenterWithIdentifier:priority:`
   → `activate` → `presentationView`
2. **场景视图** — `SBApplicationSceneView` / `SBSceneView` 的 `initWithSceneHandle:`
3. **宿主视图** — `_UISceneHostingView` 一类的 `initWithScene:debugDescription:`

每次尝试都会写进黑匣子日志（`/var/mobile/Library/Porthole/porthole.log`），
设置里「黑匣子日志」可以直接看。哪条通了就把「场景托管」固定到那一条。

## 已实现

- 边缘把手：拖动、点击开关浮窗、长按关闭
- 浮窗：标题条拖动、右下角缩放、双击标题条全屏/还原、关闭
- 设置面板：开关、目标应用（列出已安装 App）、尺寸、圆角、停靠边、托管方式、日志
- 死循环保护：所有私有 API 调用前做 `respondsToSelector` 检查，失败只写日志不崩

## 未实现 / 下一步

- 侧边泊位（1 主 + N 侧）
- 键盘重定位（需要注入 App 进程）
- 应用快照动画
- 弧形菜单

## 构建

GitHub Actions 自动出包：`.github/workflows/build.yml`，产物在 Actions artifacts。
本地构建：

```bash
make package THEOS_PACKAGE_SCHEME=roothide ARCHS="arm64 arm64e" FINALPACKAGE=1
```

## 安装

```bash
dpkg -i com.milkway.porthole_0.1.0_iphoneos-arm64.deb
killall -9 SpringBoard
```

## 使用

1. 设置 → Porthole → 选目标应用（先把目标 App 启动到前台）
2. 屏幕上出现右侧把手，点一下开浮窗
3. 开不出来就看「黑匣子日志」，把日志发我
