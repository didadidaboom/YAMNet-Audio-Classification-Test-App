# YAMNet 音频分类测试应用 / YAMNet Audio Classification Test App

<div align="center">

[![Flutter](https://img.shields.io/badge/Flutter-3.0+-blue.svg)](https://flutter.dev/)
[![TensorFlow Lite](https://img.shields.io/badge/TensorFlow%20Lite-0.11.0-orange.svg)](https://www.tensorflow.org/lite)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

**基于 Flutter + TensorFlow Lite 的实时音频分类应用**  
**Real-time audio classification app built with Flutter + TensorFlow Lite**

[English](#english) | [中文](#中文)

</div>

---

## 中文

### 🎯 项目简介

这是一个基于 **Flutter** 和 **TensorFlow Lite** 的实时音频分类测试应用，使用 **YAMNet** 模型进行高精度音频识别。应用支持 521 种音频类别的识别，包括语音、动物声音、环境声音、音乐等。

### ✨ 核心特性

- 🎵 **实时音频分类**: 基于 YAMNet 模型的 522 种音频类别识别
- 🔒 **本地处理**: 所有音频数据在本地处理，保护用户隐私
- 🍎 **Apple-level 权限管理**: 智能权限检测和优雅的用户体验
- 📱 **现代化 UI**: 简洁美观的用户界面和实时状态反馈
- ⚡ **高性能**: 使用 TensorFlow Lite 进行高效推理

### 🚀 快速开始

#### 环境要求
- Flutter 3.0+
- Dart 3.0+
- Android SDK / iOS SDK

#### 安装步骤

1. **克隆项目**
```bash
git clone https://github.com/didadidaboom/yamnet-test-app.git
cd yamnet-test-app
```

2. **安装依赖**
```bash
flutter pub get
```

3. **确保模型文件**
```
model/
├── yamnet.tflite    # YAMNet TensorFlow Lite 模型
└── labels.txt       # 音频分类标签文件
```

4. **运行应用**
```bash
flutter run
```

### 📱 使用说明

1. **启动应用**: 自动加载模型和检查权限
2. **开始录音**: 点击录音按钮，应用会请求麦克风权限
3. **停止录音**: 点击停止按钮，自动分析音频内容
4. **查看结果**: 显示识别结果和置信度排名

### 🛠️ 技术栈

- **前端框架**: Flutter 3.0+
- **机器学习**: TensorFlow Lite 0.11.0
- **音频处理**: flutter_sound 9.2.13
- **权限管理**: permission_handler 11.0.1
- **模型**: YAMNet (522 类别音频分类)

### 📁 项目结构

```
yamnet-test-app/
├── lib/
│   ├── yamnet_test.dart          # 核心音频处理类
│   └── yamnet_test_page.dart     # Flutter UI 界面
├── model/                        # 模型文件目录
│   ├── yamnet.tflite            # YAMNet 模型
│   └── labels.txt               # 分类标签
├── pubspec.yaml                 # 项目配置
└── README.md                   # 项目文档
```

### 🔧 开发说明

#### 主要依赖
```yaml
dependencies:
  tflite_flutter: ^0.11.0        # TensorFlow Lite
  flutter_sound: ^9.2.13         # 音频录制
  permission_handler: ^11.0.1    # 权限管理
  app_settings: ^5.1.1           # 系统设置
```

#### 核心功能
- **音频录制**: 16kHz 采样率，单声道录音
- **模型推理**: 0.975秒音频输入，521个类别输出
- **权限管理**: Apple-level 权限检测和设置引导
- **结果处理**: 置信度排序和可视化展示

### 🤝 贡献指南

欢迎提交 Issue 和 Pull Request！

1. Fork 本项目
2. 创建特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 开启 Pull Request

### 📝 版权声明

如果您引用或使用此代码，请注明来源：

GitHub: @didadidaboom

© 2024 @didadidaboom. All rights reserved.

This work is licensed under the MIT License. See LICENSE file for details.

---

## English

### 🎯 Project Overview

A real-time audio classification test application built with **Flutter** and **TensorFlow Lite**, using the **YAMNet** model for high-precision audio recognition. The app supports identification of 521 audio categories, including speech, animal sounds, environmental sounds, music, and more.

### ✨ Key Features

- 🎵 **Real-time Audio Classification**: 522 audio category recognition based on YAMNet model
- 🔒 **Local Processing**: All audio data processed locally, protecting user privacy
- 🍎 **Apple-level Permission Management**: Smart permission detection and elegant UX
- 📱 **Modern UI**: Clean and beautiful user interface with real-time status feedback
- ⚡ **High Performance**: Efficient inference using TensorFlow Lite

### 🚀 Quick Start

#### Requirements
- Flutter 3.0+
- Dart 3.0+
- Android SDK / iOS SDK

#### Installation

1. **Clone Repository**
```bash
git clone https://github.com/didadidaboom/yamnet-test-app.git
cd yamnet-test-app
```

2. **Install Dependencies**
```bash
flutter pub get
```

3. **Ensure Model Files**
```
model/
├── yamnet.tflite    # YAMNet TensorFlow Lite Model
└── labels.txt       # Audio Classification Labels
```

4. **Run Application**
```bash
flutter run
```

### 📱 Usage Guide

1. **Launch App**: Automatically loads model and checks permissions
2. **Start Recording**: Tap record button, app will request microphone permission
3. **Stop Recording**: Tap stop button, automatically analyzes audio content
4. **View Results**: Displays recognition results and confidence rankings

### 🛠️ Tech Stack

- **Frontend Framework**: Flutter 3.0+
- **Machine Learning**: TensorFlow Lite 0.11.0
- **Audio Processing**: flutter_sound 9.2.13
- **Permission Management**: permission_handler 11.0.1
- **Model**: YAMNet (522-category audio classification)

### 📁 Project Structure

```
yamnet-test-app/
├── lib/
│   ├── yamnet_test.dart          # Core Audio Processing Class
│   └── yamnet_test_page.dart     # Flutter UI Interface
├── model/                        # Model Files Directory
│   ├── yamnet.tflite            # YAMNet Model
│   └── labels.txt               # Classification Labels
├── pubspec.yaml                 # Project Configuration
└── README.md                   # Project Documentation
```

### 🔧 Development Guide

#### Main Dependencies
```yaml
dependencies:
  tflite_flutter: ^0.11.0        # TensorFlow Lite
  flutter_sound: ^9.2.13         # Audio Recording
  permission_handler: ^11.0.1    # Permission Management
  app_settings: ^5.1.1           # System Settings
```

#### Core Features
- **Audio Recording**: 16kHz sample rate, mono channel recording
- **Model Inference**: 0.975s audio input, 521 category output
- **Permission Management**: Apple-level permission detection and settings guidance
- **Result Processing**: Confidence ranking and visualization

### 🤝 Contributing

Issues and Pull Requests are welcome!

1. Fork this project
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

### 📝 Copyright Notice

If you reference or use this code, please cite the source:

GitHub: @didadidaboom

© 2024 @didadidaboom. All rights reserved.

This work is licensed under the MIT License. See LICENSE file for details. 
