# Study Timer iOS

一个用于记录学习时长的 iOS 学习项目。

当前版本已经实现：

- 学习项目管理（预置项目 + 手动新增）
- 开始/结束一次学习计时
- 今日与本周累计时长
- 历史学习记录
- 项目总时长统计排行
- 本地持久化存储

## Tech Stack

- SwiftUI
- Observation
- 本地 JSON 持久化
- Xcode / iOS Simulator

## Skill Usage

这个项目的第一版主要使用了 OpenAI `build-ios-apps` 插件中的 `swiftui-ui-patterns` skill 来完成 SwiftUI 结构设计与界面实现。

参考：

- https://github.com/openai/plugins/tree/main/plugins/build-ios-apps

## Learning Notes

这个仓库会作为 iOS 学习过程中的阶段性记录，后续计划继续补充：

- 项目编辑与删除
- 每日学习目标
- 周统计图表
- 本地通知提醒
- Widget

## Build

```bash
xcodebuild -project XcodeSandbox.xcodeproj -scheme XcodeSandbox -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' build
```
