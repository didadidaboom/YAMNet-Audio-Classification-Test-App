import 'dart:math';
import 'dart:typed_data';
import 'dart:io';
import 'dart:async';
import 'package:tflite_flutter/tflite_flutter.dart' hide List;
import 'package:flutter_sound/flutter_sound.dart';
import 'package:flutter/services.dart' show rootBundle;

/// 简单的YAMNet音频分类测试器
class YamnetTest {
  Interpreter? _interpreter;
  FlutterSoundRecorder? _recorder;
  List<String>? _labels;
  
  // 音频配置 - 适配YAMNet模型
  static const int _sampleRate = 16000; // YAMNet要求16kHz
  static const int _numChannels = 1;
  static const int _bufferSize = 1024;
  static const Duration _subscriptionDuration = Duration(milliseconds: 100);
  
  // 录音状态
  bool _isInitialized = false;
  bool _isRecording = false;
  
  // 音频数据缓冲
  List<List<Float32List>> _audioBuffer = [];
  StreamController<List<Float32List>>? _audioDataController;

  YamnetTest() {
    _recorder = FlutterSoundRecorder();
  }

  /// 初始化录音器和模型
  Future<void> initialize() async {
    try {
      if (_isInitialized) {
        print('🎯 YAMNet test already initialized');
        return;
      }
      
      // 加载YAMNet模型
      _interpreter = await Interpreter.fromAsset('assets/model/yamnet.tflite');
      print('🎯 YAMNet model loaded');
      
      // 加载标签
      String labelsContent = await rootBundle.loadString('assets/model/labels.txt');
      _labels = labelsContent.split('\n').where((line) => line.trim().isNotEmpty).toList();
      print('🎯 Loaded ${_labels!.length} labels');
      
      // 初始化录音器
      print('🎯 Opening flutter_sound recorder...');
      await _recorder!.openRecorder();
      print('🎯 Flutter_sound recorder opened successfully');
      
      // 设置订阅持续时间
      await _recorder!.setSubscriptionDuration(_subscriptionDuration);
      print('🎯 Subscription duration set to ${_subscriptionDuration.inMilliseconds}ms');
      
      _isInitialized = true;
      print('🎯 YAMNet test initialized successfully');
    } catch (e) {
      print('❌ Failed to initialize: $e');
      rethrow;
    }
  }

  /// 加载模型和标签 (保持向后兼容)
  Future<void> loadModel() async {
    await initialize();
  }

  /// 开始录音
  Future<void> startRecording() async {
    try {
      if (!_isInitialized) {
        await initialize();
      }
      
      if (_isRecording) {
        print('🎤 Already recording');
        return;
      }
      
      // 清空之前的音频缓冲
      _audioBuffer.clear();
      
      // 创建音频数据流控制器
      _audioDataController = StreamController<List<Float32List>>();
      _audioDataController!.stream.listen((audioData) {
        _audioBuffer.add(audioData);
      });
      
      // 开始录音 - 使用Float32格式，适配YAMNet
      await _recorder!.startRecorder(
        codec: Codec.pcmFloat32,
        sampleRate: _sampleRate,
        numChannels: _numChannels,
        audioSource: AudioSource.defaultSource,
        toStreamFloat32: _audioDataController!.sink,
        bufferSize: _bufferSize,
      );
      
      _isRecording = true;
      print('🎤 Recording started with Float32 stream');
    } catch (e) {
      print('❌ Failed to start recording: $e');
      rethrow;
    }
  }

  /// 停止录音
  Future<List<double>> stopRecording() async {
    try {
      if (!_isRecording) {
        print('🎤 Not recording');
        return [];
      }
      
      // 停止录音
      await _recorder!.stopRecorder();
      
      // 关闭音频数据流控制器
      await _audioDataController?.close();
      _audioDataController = null;
      
      _isRecording = false;
      
      // 从音频缓冲中提取数据
      List<double> audioData = _extractAudioFromBuffer();
      
      print('🎤 Recording stopped. Length: ${audioData.length}');
      return audioData;
    } catch (e) {
      print('❌ Failed to stop recording: $e');
      rethrow;
    }
  }
  
  /// 从音频缓冲中提取音频数据
  List<double> _extractAudioFromBuffer() {
    if (_audioBuffer.isEmpty) {
      print('⚠️ No audio data in buffer');
      return [];
    }
    
    List<double> combinedAudio = [];
    
    // 合并所有音频数据
    for (var audioData in _audioBuffer) {
      for (var channel in audioData) {
        combinedAudio.addAll(channel);
      }
    }
    
    print('🎵 Extracted ${combinedAudio.length} samples from buffer');
    return combinedAudio;
  }

  /// 获取录音状态
  bool get isRecording => _isRecording;
  
  /// 获取初始化状态
  bool get isInitialized => _isInitialized;
  
  /// 获取音频缓冲大小
  int get audioBufferSize => _audioBuffer.length;

  /// 分类音频
  Future<List<MapEntry<String, double>>> classifyAudio(List<double> audioData) async {
    try {
      if (_interpreter == null || _labels == null) {
        throw Exception('Model or labels not loaded');
      }
      
      print('🎵 Classifying audio...');
      
      // YAMNet TFLite要求：0.975秒音频 (15,600样本 @ 16kHz)
      int targetLength = 15600; // 0.975 * 16000
      
      if (audioData.length > targetLength) {
        // 如果音频太长，取中间部分
        int start = (audioData.length - targetLength) ~/ 2;
        audioData = audioData.sublist(start, start + targetLength);
      } else if (audioData.length < targetLength) {
        // 如果音频太短，用零填充
        audioData.addAll(List.filled(targetLength - audioData.length, 0.0));
      }
      
      print('🎵 Audio length: ${audioData.length} samples (${audioData.length / 16000} seconds)');
      
      // 直接使用原始音频波形，不需要mel频谱图
      var output = await _runInference(audioData);
      
      // 处理结果
      return _processResults(output);
    } catch (e) {
      print('❌ Classification error: $e');
      return [];
    }
  }



  /// 运行推理
  Future<List<double>> _runInference(List<double> audioData) async {
    try {
      // 检查interpreter是否为空
      if (_interpreter == null) {
        throw Exception('Interpreter is null');
      }
      
      // 检查输入形状
      print('🎵 Input audio length: ${audioData.length}');
      
      // 检查模型输入输出形状
      var inputShape = _interpreter!.getInputTensor(0).shape;
      var outputShape = _interpreter!.getOutputTensor(0).shape;
      print('🎵 Model input shape: $inputShape');
      print('🎵 Model output shape: $outputShape');
      
      // 根据案例，YAMNet TFLite期望输入为2D数组 [1, 15600]
      var input = [audioData]; // 包装成2D数组，与案例中的reshapedInput = [input.toList()]一致
      
      // 检查输入数据是否为空
      if (input.isEmpty || input[0].isEmpty) {
        throw Exception('Input audio data is empty');
      }
      
      // 准备输出 - 根据案例，输出形状为 [1, 521]
      var output = [List<double>.filled(521, 0.0)]; // 与案例中的output = [List<double>.filled(2, 0.0)]一致
      
      print('🎵 Input shape: ${input.length} x ${input[0].length}');
      print('🎵 Output shape: ${output.length} x ${output[0].length}');
      
      // 检查输出是否为空
      if (output.isEmpty || output[0].isEmpty) {
        throw Exception('Output tensor is empty');
      }
      
      // 使用官方推荐的run方法
      _interpreter!.run(input, output);
      
      // 检查输出结果
      if (output.isEmpty || output[0].isEmpty) {
        throw Exception('Output is empty after inference');
      }
      
      print('🎵 Inference completed successfully');
      return output[0].cast<double>();
    } catch (e) {
      print('❌ Inference error: $e');
      rethrow;
    }
  }



  /// 处理结果
  List<MapEntry<String, double>> _processResults(List<double> output) {
    List<MapEntry<String, double>> results = [];
    
    // 检查输入参数
    if (output.isEmpty) {
      print('⚠️ Output is empty, returning empty results');
      return results;
    }
    
    if (_labels == null || _labels!.isEmpty) {
      print('⚠️ Labels are null or empty, returning empty results');
      return results;
    }
    
    print('🎵 Processing ${output.length} outputs with ${_labels!.length} labels');
    
    for (int i = 0; i < output.length && i < _labels!.length; i++) {
      double confidence = output[i];
      if (confidence > 0.1) {
        results.add(MapEntry(_labels![i], confidence));
      }
    }
    
    print('🎵 Found ${results.length} results with confidence > 0.1');
    results.sort((a, b) => b.value.compareTo(a.value));
    return results.take(10).toList();
  }

  /// 清理资源
  void dispose() {
    try {
      // 停止录音
      if (_isRecording) {
        _recorder?.stopRecorder();
      }
      
      // 关闭音频数据流控制器
      _audioDataController?.close();
      
      // 关闭模型和录音器
      _interpreter?.close();
      _recorder?.closeRecorder();
      
      print('🎯 YAMNet test disposed');
    } catch (e) {
      print('❌ Error disposing YAMNet test: $e');
    }
  }
} 