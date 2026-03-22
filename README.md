# StudyMemory（考研复习助手）

> 一个面向考研的 Flutter 桌面/移动学习 App，帮助你把**知识点 → 复习计划 → 日常打卡**串起来。

## 这个项目能做什么

### 核心功能
- 🎯 **目标管理**：设置复习目标与科目方向
- 📝 **知识点录入**：快速添加题目/概念/知识卡片
- 📚 **今日复习**：按计划筛选当天待复习内容
- 📅 **复习日历**：按日期查看复习任务与完成情况
- 📈 **进度反馈**：XP、等级、Streak（连击）与基础统计
- 🧩 **本地化存储**：采用 SQLite，本地先运行、数据本机持久化

### 设计目标
- 轻量、可扩展、上手快
- 先把“能用”做稳，再逐步补齐高级功能

---

## 技术栈

- **Flutter + Dart**：跨平台 UI 与业务代码
- **sqflite（SQLite）**：本地数据库持久化
- **Material 风格页面设计**：移动端友好

---

## 目录文件说明（最实用版）

```bash
lib/
├─ app.dart                 # 应用主题/路由总入口
├─ main.dart                # 启动入口
├─ database/
│  └─ app_database.dart     # 数据库初始化、表结构与数据库操作入口
├─ models/
│  └─ study_models.dart     # 知识点/目标/任务等数据模型定义
├─ services/
│  └─ study_service.dart    # 业务层：数据的增删改查、复习逻辑封装
├─ pages/
│  ├─ home_page.dart        # 首页（核心入口/总体看板）
│  ├─ goal_page.dart        # 目标设置页
│  ├─ add_page.dart         # 新建学习条目页
│  ├─ calendar_page.dart    # 日历页（按日期查看复习）
│  └─ stats_page.dart       # 统计页（进度与习惯）
└─ widgets/
   ├─ section_card.dart     # 通用卡片组件
   └─ stat_badge.dart       # 通用统计/指标组件

assets/
  ├─ images/                # 未来放置资源图
  └─ ...

copyright_materials/
  ├─ README.md
  ├─ software_manual.md
  ├─ source_manifest.md
  └─ source_submission.txt   # 版权与来源声明相关文件

android/ ios / macos / windows / linux / web
  └─ 各平台工程化配置与打包脚本

test/
  └─ widget_test.dart        # 最基础测试样例

pubspec.yaml / pubspec.lock
  └─ 依赖和包版本配置
```

---

## 快速运行

```bash
flutter pub get
flutter run
```

> 如果是首次运行，先检查 Flutter SDK 是否安装并能识别设备/模拟器。

---

## 当前状态（里程碑）

- ✅ 已完成：目标、知识点、今日复习、日历、XP/等级/Streak
- 🚧 进行中：更友好的学习反馈与可视化优化
- 🔜 待做：
  - 复习评分系统（1~4 级记忆程度）
  - 逾期任务红色预警
  - 通知提醒（待办提醒）
  - 更详细的数据统计页

---

## 常见提问（对外展示版）

**Q：这个项目适合谁？**
- 适合正在备考、希望系统化管理知识点复习的人。

**Q：会不会联网？**
- 目前以本地存储为主，关注学习数据隐私。

**Q：能直接上架使用吗？**
- 这是可迭代版本，已具备可运行的核心功能，后续持续打磨体验。
