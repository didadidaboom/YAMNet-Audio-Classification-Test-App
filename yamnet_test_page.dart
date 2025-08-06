import 'dart:async';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:app_settings/app_settings.dart';
import 'yamnet_test.dart';

/// YAMNet音频分类测试页面
class YamnetTestPage extends StatefulWidget {
  const YamnetTestPage({super.key});

  @override
  State<YamnetTestPage> createState() => _YamnetTestPageState();
}

class _YamnetTestPageState extends State<YamnetTestPage> {
  final YamnetTest _yamnetTest = YamnetTest();
  bool _isModelLoaded = false;
  bool _isRecording = false;
  bool _isProcessing = false;
  List<MapEntry<String, double>> _results = [];
  String _statusMessage = '准备就绪';
  int _recordingDuration = 0;
  Timer? _recordingTimer;

  // 🎯 Apple-level Permission Management
  Timer? _permissionCheckTimer;
  bool _isInitializingAudioDetection = false;

  @override
  void initState() {
    super.initState();
    
    // 🎯 Apple-level Permission Management
    // 延迟执行权限检查，确保页面完全加载
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // 再延迟一点时间，确保页面稳定
      Future.delayed(Duration(milliseconds: 500), () async {
        if (!mounted) return;
        
        try {
          print('🎯 Starting permission check for YAMNet...');
          bool permissionGranted = await _requestMicrophonePermissionDirectly();
          
          // 🎯 只有在权限未授予时才启动权限状态监听
          if (!permissionGranted && mounted) {
            _startPermissionListener();
          }
        } catch (e) {
          print('❌ Error during permission initialization: $e');
          // 权限初始化失败时，显示权限要求对话框
          if (mounted) {
            _showMicrophonePermissionRequiredDialog();
          }
        }
      });
    });
    
    _loadModel();
  }

  @override
  void dispose() {
    // 🎯 Apple-level Resource Cleanup
    _permissionCheckTimer?.cancel();
    _recordingTimer?.cancel();
    _yamnetTest.dispose();
    super.dispose();
  }

  /// 加载模型
  Future<void> _loadModel() async {
    try {
      setState(() {
        _statusMessage = '正在加载模型...';
      });
      
      await _yamnetTest.loadModel();
      
      setState(() {
        _isModelLoaded = true;
        _statusMessage = '模型加载完成，可以开始录音';
      });
    } catch (e) {
      setState(() {
        _statusMessage = '模型加载失败: $e';
      });
    }
  }

  /// 🎯 Apple-level Permission Status Listener
  void _startPermissionListener() {
    // 每3秒检查一次权限状态，减少频率
    _permissionCheckTimer = Timer.periodic(Duration(seconds: 3), (timer) async {
      if (!mounted) {
        timer.cancel();
        return;
      }
      
      try {
        final micStatus = await Permission.microphone.status;
        print('🎯 YAMNet permission listener check: $micStatus');
        
        if (micStatus.isGranted) {
          // 麦克风权限授予，更新状态
          print('✅ Microphone permission granted via listener for YAMNet');
          if (mounted) {
            setState(() {
              _statusMessage = '模型加载完成，可以开始录音';
            });
          }
          // 停止监听
          timer.cancel();
        } else if (micStatus.isPermanentlyDenied) {
          // 权限被永久拒绝，显示设置指导
          print('❌ Microphone permission permanently denied via listener');
          if (mounted) {
            _showMicrophonePermissionRequiredDialog();
          }
          // 停止监听
          timer.cancel();
        } else if (micStatus.isDenied) {
          // 权限被拒绝，显示设置指导
          print('❌ Microphone permission denied via listener');
          if (mounted) {
            _showMicrophonePermissionRequiredDialog();
          }
          // 停止监听
          timer.cancel();
        }
        // 如果是其他状态（如 isRestricted），继续监听，不显示任何对话框
      } catch (e) {
        print('❌ Error in YAMNet permission listener: $e');
        // 出错时停止监听
        timer.cancel();
      }
    });
  }

  /// 🍎 Apple-level Direct Microphone Permission Request
  Future<bool> _requestMicrophonePermissionDirectly() async {
    try {
      // 1. 检查当前权限状态
      PermissionStatus status = await Permission.microphone.status;
      print('🎯 Current microphone permission status for YAMNet: $status');
      
      if (status.isGranted) {
        // 2. 权限已授予，直接更新状态
        print('✅ Microphone permission already granted for YAMNet');
        if (mounted) {
          setState(() {
            _statusMessage = '模型加载完成，可以开始录音';
          });
        }
        return true;
      }
      
      if (status.isPermanentlyDenied) {
        // 3. 权限被永久拒绝，显示设置指导
        print('❌ Microphone permission permanently denied for YAMNet');
        if (mounted) {
          _showMicrophonePermissionRequiredDialog();
        }
        return false;
      }
      
      // 4. 权限未授予，直接请求权限（会显示系统弹窗）
      print('🎯 Requesting microphone permission for YAMNet...');
      status = await Permission.microphone.request();
      print('🎯 Permission request result for YAMNet: $status');
      
      // 5. 等待用户响应系统权限弹窗
      await Future.delayed(Duration(milliseconds: 1000));
      
      // 6. 再次检查权限状态
      status = await Permission.microphone.status;
      print('🎯 Final permission status after user response for YAMNet: $status');
      
      if (status.isGranted) {
        // 7. 权限授予成功，更新状态
        print('✅ Microphone permission granted for YAMNet');
        if (mounted) {
          setState(() {
            _statusMessage = '模型加载完成，可以开始录音';
          });
        }
        return true;
      } else if (status.isDenied) {
        // 8. 用户拒绝了权限，显示设置指导
        print('❌ User denied microphone permission for YAMNet');
        if (mounted) {
          _showMicrophonePermissionRequiredDialog();
        }
        return false;
      } else if (status.isPermanentlyDenied) {
        // 9. 用户永久拒绝了权限，显示设置指导
        print('❌ User permanently denied microphone permission for YAMNet');
        if (mounted) {
          _showMicrophonePermissionRequiredDialog();
        }
        return false;
      } else {
        // 10. 其他状态，可能是用户还没有响应，不显示任何对话框
        print('⚠️ Permission status unclear for YAMNet, user may still be deciding');
        // 不显示任何对话框，让用户继续使用系统权限弹窗
        return false;
      }
      
    } catch (e) {
      print('❌ Error requesting microphone permission for YAMNet: $e');
      if (mounted) {
        // 11. 发生错误时，显示设置指导
        _showMicrophonePermissionRequiredDialog();
      }
      return false;
    }
  }

  /// 🍎 Apple-level Direct Settings Dialog
  void _showMicrophonePermissionRequiredDialog() {
    if (!mounted) return;
    
    showDialog(
      context: context,
      barrierDismissible: false, // 确保遮罩不可点击
      barrierColor: Colors.black54, // 优雅的遮罩颜色
      builder: (context) => WillPopScope(
        onWillPop: () async => false, // 防止返回键关闭对话框
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 8, // 增加阴影效果
          backgroundColor: Colors.white,
          title: Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.mic_off, color: Colors.orange, size: 20),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'YAMNet Requires Microphone',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'YAMNet audio classification requires microphone access to analyze and classify audio in real-time. Please enable it in Settings to continue testing.',
                style: TextStyle(fontSize: 15, color: Colors.black87, height: 1.5),
              ),
              SizedBox(height: 12),
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withOpacity(0.15)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.security, color: Colors.blue, size: 14),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Audio processed locally only - no data sent to servers',
                        style: TextStyle(fontSize: 11, color: Colors.blue.shade700, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop(); // 返回上一页
              },
              style: TextButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: Text(
                'Cancel',
                style: TextStyle(fontSize: 15, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await AppSettings.openAppSettings();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
                shadowColor: Colors.blue.withOpacity(0.3),
              ),
              child: Text(
                'Open Settings',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
          ],
          actionsPadding: EdgeInsets.fromLTRB(24, 0, 24, 20),
        ),
      ),
    );
  }

  /// 请求录音权限 (保持向后兼容)
  Future<void> _requestPermission() async {
    var status = await Permission.microphone.status;
    if (status.isDenied) {
      status = await Permission.microphone.request();
      if (status.isDenied) {
        setState(() {
          _statusMessage = '需要麦克风权限才能录音';
        });
        return;
      }
    }
  }

  /// 开始录音
  Future<void> _startRecording() async {
    try {
      // 🎯 Apple-level Permission Check before Recording
      final micStatus = await Permission.microphone.status;
      if (!micStatus.isGranted) {
        print('🎯 Microphone permission not granted, requesting...');
        final granted = await _requestMicrophonePermissionDirectly();
        if (!granted) {
          setState(() {
            _statusMessage = '需要麦克风权限才能录音';
          });
          return;
        }
      }
      
      await _yamnetTest.startRecording();
      
      // 开始录音计时器
      _recordingDuration = 0;
      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          _recordingDuration++;
        });
      });
      
      setState(() {
        _isRecording = true;
        _statusMessage = '正在录音... 请说话';
        _results.clear();
      });
    } catch (e) {
      setState(() {
        _statusMessage = '录音失败: $e';
      });
    }
  }

  /// 停止录音并分类
  Future<void> _stopRecording() async {
    try {
      // 停止录音计时器
      _recordingTimer?.cancel();
      
      setState(() {
        _isRecording = false;
        _isProcessing = true;
        _statusMessage = '正在处理音频...';
      });

      // 停止录音
      List<double> audioData = await _yamnetTest.stopRecording();
      
      if (audioData.isEmpty) {
        setState(() {
          _isProcessing = false;
          _statusMessage = '录音数据为空，请重新录音';
        });
        return;
      }
      
      // 分类音频
      List<MapEntry<String, double>> results = await _yamnetTest.classifyAudio(audioData);
      
      setState(() {
        _isProcessing = false;
        _results = results;
        _statusMessage = results.isNotEmpty 
            ? '识别完成，找到 ${results.length} 个类别'
            : '未识别到任何类别';
      });
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _statusMessage = '处理失败: $e';
      });
      print('❌ Error in _stopRecording: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('YAMNet 音频分类测试'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 状态显示
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Icon(
                      _isModelLoaded ? Icons.check_circle : Icons.error,
                      color: _isModelLoaded ? Colors.green : Colors.red,
                      size: 48,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _statusMessage,
                      style: const TextStyle(fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    if (_isRecording) ...[
                      const SizedBox(height: 8),
                      Text(
                        '录音时长: ${_recordingDuration}秒',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // 录音按钮
            ElevatedButton.icon(
              onPressed: _isModelLoaded && !_isProcessing
                  ? (_isRecording ? _stopRecording : _startRecording)
                  : null,
              icon: Icon(_isRecording ? Icons.stop : Icons.mic),
              label: Text(_isRecording ? '停止录音' : '开始录音'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _isRecording ? Colors.red : Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // 处理指示器
            if (_isProcessing)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(width: 16),
                      Text('正在分析音频...'),
                    ],
                  ),
                ),
              ),
            
            const SizedBox(height: 16),
            
            // 结果显示
            if (_results.isNotEmpty) ...[
              const Text(
                '识别结果:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Card(
                  child: ListView.builder(
                    itemCount: _results.length,
                    itemBuilder: (context, index) {
                      var result = _results[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue,
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text(
                          result.key,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        subtitle: LinearProgressIndicator(
                          value: result.value,
                          backgroundColor: Colors.grey[300],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            result.value > 0.5 ? Colors.green : Colors.orange,
                          ),
                        ),
                        trailing: Text(
                          '${(result.value * 100).toStringAsFixed(1)}%',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ] else if (!_isProcessing && _isModelLoaded) ...[
              const Expanded(
                child: Card(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.music_note,
                          size: 64,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          '点击"开始录音"按钮开始测试',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
} 