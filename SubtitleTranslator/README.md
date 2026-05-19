# 悬浮字幕 (Floating Subtitles)

## 实时悬浮中英双语字幕 iOS APP

一款纯原生 SwiftUI iOS APP，实现系统级悬浮双语字幕，覆盖全屏观影场景。支持中英双向实时语音识别与翻译，完全本地离线处理，保护隐私。

---

## 功能概览

| 功能 | 说明 |
|------|------|
| 系统内录 | 通过 iOS Broadcast Extension 捕获设备内部播放的音频 |
| 离线语音识别 | Apple SFSpeechRecognizer 本地离线识别中/英文 |
| 离线翻译 | Apple NLTranslator + 内置词典，中英互译 |
| 全局悬浮窗 | UIWindow 置顶覆盖所有 APP，可拖拽、半透明 |
| 双语双行 | 一行原文 + 一行译文，支持顺序切换 |
| 样式自定义 | 字体大小、颜色、透明度、背景色可调 |
| 灵动岛 | Live Activity 在灵动岛和锁屏显示字幕 |
| 小组件 | 主屏幕小组件查看运行状态 |
| 纯本地 | 无需联网、无需付费接口、无需第三方SDK |

---

## 系统要求

| 项目 | 要求 |
|------|------|
| iOS 版本 | **iOS 16.0 及以上** |
| 设备 | iPhone（全机型兼容） |
| Xcode | **15.0 及以上** |
| Swift | 5.9 |
| Apple ID | 需要（用于签名） |

---

## 项目结构

```
SubtitleTranslator/
├── project.yml                          # XcodeGen 项目配置
├── README.md                            # 本文档
├── setup.sh                             # 一键生成 Xcode 项目脚本
├── Shared/
│   ├── AppTypes.swift                   # 数据模型、设置、颜色封装
│   └── AudioBuffer.swift                # 音频缓冲区、进程间通信
├── SubtitlesApp/
│   ├── Info.plist                       # 主应用配置
│   ├── SubtitlesApp.entitlements        # 权限声明
│   ├── Assets.xcassets/                 # 资源目录
│   ├── AppMain.swift                    # App 入口 & AppDelegate
│   ├── ContentView.swift                # 根视图
│   ├── Services/
│   │   ├── AudioCaptureEngine.swift     # 音频捕获引擎
│   │   ├── SpeechRecognizer.swift       # 语音识别服务
│   │   ├── TranslationEngine.swift      # 翻译引擎
│   │   └── SubtitleOverlayManager.swift # 字幕管理层
│   └── Views/
│       ├── MainView.swift               # 主界面
│       ├── OverlayWindow.swift          # 悬浮窗 & 浮窗管理器
│       └── SettingsView.swift           # 高级设置页
├── BroadcastExtension/
│   ├── Info.plist                       # 广播扩展现配置
│   ├── BroadcastExtension.entitlements  # 扩展权限
│   ├── SampleHandler.swift              # 系统音频捕获处理
│   └── BroadcastSetupViewController.swift # 广播启动界面
├── SubtitleWidget/
│   ├── Info.plist                       # 小组件配置
│   ├── SubtitleWidget.entitlements      # 小组件权限
│   └── SubtitleWidgetBundle.swift       # 灵动岛 + 主屏幕小组件
└── Scripts/
    └── gen_launch_screen.swift          # 启动画面生成脚本
```

---

## 快速开始（三步）

### 第一步：安装 XcodeGen（如未安装）

```bash
brew install xcodegen
```

或从 https://github.com/yonaskolb/XcodeGen 下载。

### 第二步：生成 Xcode 项目

```bash
cd SubtitleTranslator
chmod +x setup.sh
./setup.sh
```

脚本会自动：
1. 运行 `xcodegen` 生成 `.xcodeproj`
2. 生成 `LaunchScreen.storyboard`
3. 生成占位 App Icon

### 第三步：在 Xcode 中编译

```bash
open SubtitlesApp.xcodeproj
```

然后在 Xcode 中：
1. 选择 **SubtitlesApp** scheme
2. 目标设备选择 **iPhone（任意型号）**
3. 按 `Cmd+R` 编译运行

---

## 自签名安装到手机（无需开发者账号）

### 方法一：Xcode 直接安装（推荐）

1. 用数据线连接 iPhone 到 Mac
2. Xcode → Window → Devices and Simulators
3. 选择你的 iPhone
4. 在项目设置中：
   - Signing & Capabilities → Team 选择你的 Apple ID
   - 修改 Bundle Identifier（如 `com.yourname.subtitletranslator`）
   - 同步修改 `BroadcastExtension` 和 `SubtitleWidget` 的 Bundle ID
5. 修改 `SubtitlesApp.entitlements`、`BroadcastExtension/BroadcastExtension.entitlements`、`SubtitleWidget/SubtitleWidget.entitlements` 中的 `group.com.subtitletranslator` 为 `group.你的新BundleID`
6. 修改 `Shared/AppTypes.swift` 中的 `groupIdentifier` 为新的 App Group ID
7. 按 `Cmd+R` 运行到手机

### 方法二：AltStore / SideStore 侧载

1. 在 Xcode 中 Archive → Distribute App → Development
2. 导出 `.ipa` 文件
3. 使用 AltStore 或 SideStore 侧载到手机

### 方法三：JB 设备直接安装

TrollStore 或其他永久签名工具直接安装 `.ipa`。

---

## 使用说明

### 启动字幕

1. 打开「悬浮字幕」APP
2. 打开 **主开关** → APP 开始使用麦克风收音
3. 悬浮窗自动出现在屏幕上

### 使用系统内录模式（捕获手机内部音频）

通过 iOS Broadcast Extension 捕获设备内音频：

1. 从屏幕右上角下拉打开 **控制中心**
2. **长按**录屏按钮（⏺）
3. 在列表中选择 **「悬浮字幕广播」**
4. 点击 **开始广播**
5. 切回视频/直播 APP 播放 → 字幕自动生成

### 悬浮窗操作

- **拖动**：按住悬浮窗拖动到任意位置
- **样式**：主界面滑动调节字体大小、颜色、透明度
- **隐藏**：关闭主开关即可隐藏悬浮窗

### 设置推荐

| 场景 | 推荐设置 |
|------|---------|
| 看英文电影 | 识别:English → 翻译:中文 → 原文在上 |
| 看国产剧/直播 | 识别:中文 → 翻译:English → 原文在上 |
| 夜间观影 | 字体白色 + 背景深黑 + 透明度70% |
| 字幕尽量小 | 字体14pt + 透明度50% + 背景全透明 |

---

## 常见问题

### Q: 语音识别没反应？
A: 检查 设置 → 隐私 → 语音识别 → 开启悬浮字幕权限。同时确保 iOS 设置 → 通用 → 键盘 → 听写 → 已下载对应语言包。

### Q: 翻译不准确？
A: 优先使用 Apple NLTranslator 本地翻译。当 NLTranslator 不可用时会自动降级为内置词典匹配。内置词典覆盖100+常用影视短语。后续版本会扩充词典。

### Q: 灵动岛不显示？
A: 灵动岛需要 iPhone 14 Pro 及以上机型。Live Activity 会在广播启动后自动显示。

### Q: 系统内录没有声音？
A: Broadcast Extension 只能捕获系统音频（App内播放的音频），无法捕获通话音频。确保从控制中心正确启动了「悬浮字幕广播」。

### Q: APP 闪退？
A: 确保 iOS 16.0+，Xcode 15.0+。检查 Bundle ID 和 App Group 配置一致性。

---

## 技术架构

```
┌──────────────────────────────────────────┐
│           iOS 设备                         │
│                                          │
│  ┌─────────────┐     ┌───────────────┐  │
│  │ 控制中心      │     │  视频APP       │  │
│  │ 广播选择器   │────▶│  (B站/YouTube) │  │
│  └─────────────┘     └───────┬───────┘  │
│                              │           │
│                   系统音频输出            │
│                              │           │
│  ┌───────────────────────────▼────────┐ │
│  │     BroadcastExtension              │ │
│  │     (SampleHandler)                 │ │
│  │     捕获 PCM 音频数据               │ │
│  └──────────────┬─────────────────────┘ │
│                 │ App Group (共享容器)    │
│  ┌──────────────▼─────────────────────┐ │
│  │     主 APP (SubtitlesApp)           │ │
│  │                                    │ │
│  │  AudioCaptureEngine                │ │
│  │     ↓                              │ │
│  │  SpeechRecognizer (SFSpeech)       │ │
│  │     ↓                              │ │
│  │  TranslationEngine (NLTranslator)  │ │
│  │     ↓                              │ │
│  │  SubtitleOverlayManager            │ │
│  │     ↓                              │ │
│  │  FloatingOverlayWindow             │ │
│  │  (全局悬浮窗 + 灵动岛)              │ │
│  └────────────────────────────────────┘ │
│                                          │
│  用户看到: 屏幕上悬浮双语字幕             │
└──────────────────────────────────────────┘
```

---

## 隐私声明

本 APP **完全在设备本地运行**：
- ✅ 语音识别在设备端进行（Apple SFSpeechRecognizer on-device）
- ✅ 翻译在设备端进行（Apple NLTranslator + 本地词典）
- ✅ 音频数据不离开设备
- ✅ 无任何网络请求
- ✅ 无第三方数据收集
- ✅ 无用户追踪

---

## 开发计划

- [x] 核心双语字幕悬浮窗
- [x] 离线语音识别（中/英）
- [x] 离线翻译引擎
- [x] 系统内录广播扩展
- [x] 灵动岛 Live Activity
- [x] 主屏幕小组件
- [ ] Whisper.cpp 离线模型集成（更高精度）
- [ ] 日/韩语支持
- [ ] 字幕历史导出
- [ ] iCloud 设置同步

---

## License

MIT License — 仅供学习与研究使用。

---

## 致谢

- Apple Speech Framework
- Apple NaturalLanguage Framework  
- Apple ReplayKit Framework
- Apple WidgetKit
