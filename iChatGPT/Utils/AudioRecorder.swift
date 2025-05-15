//
//  AudioRecorder.swift
//  iChatGPT
//
//  Created by EKI KOUKA on R 6/10/13.
//

import AVFoundation

class AudioRecorder: NSObject, ObservableObject {
    var audioRecorder: AVAudioRecorder?
    var recordingURL: URL?
    
    @Published var recordingDuration: TimeInterval = 0 // 録音時长
    private var timer: Timer? // 监听音频电平定時器
    @Published var audioPower: [Float] = [0.0] // 声音强度

    override init() {
        super.init()
    }
    
    func prepareRecording() -> Bool {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let fileURL = paths[0].appendingPathComponent("recording.wav")
        recordingURL = fileURL
    
        let settings = [
            AVFormatIDKey: Int(kAudioFormatLinearPCM), // 使用线性 PCM 格式 (WAV)
            AVSampleRateKey: 16000, // Whisper API 建议的采样率为 16kHz
            AVNumberOfChannelsKey: 1, // 单声道録音
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        do {
            audioRecorder = try AVAudioRecorder(url: fileURL, settings: settings)
            audioRecorder?.isMeteringEnabled = true // 启用音频电平监测
            audioRecorder?.prepareToRecord()
            return true
        } catch {
            print("无法初始化録音：\(error.localizedDescription)")
            return false
        }
    }
    
    // 録音時長計時器
    private func startRecordingTimer() {
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            if let recorder = self.audioRecorder, recorder.isRecording {
                self.recordingDuration += 1.0 // 每秒增加録音時长
            } else {
                timer.invalidate() // 停止計時器
            }
        }
    }

    func startRecording(completion: @escaping (Bool) -> Void) {
        PermissionManager.checkPermission(for: .microphone) { granted in
            guard granted else {
                print("用户未授权麦克风訪問権限")
                completion(false) // 権限被拒绝，传递結果
                return
            }
            guard self.prepareRecording() else { // 権限通過後，先準備録音
                print("録音器初始化失敗")
                completion(false)
                return
            }
            
            // 然後開始録音
            do {
                try AVAudioSession.sharedInstance().setCategory(.playAndRecord, mode: .default)
                try AVAudioSession.sharedInstance().setActive(true)
                
                guard let recorder = self.audioRecorder else {
                    print("音频録音器未正确初始化")
                    return
                }
                recorder.record()
                print("开始録音 \(Date())")
                // 启动一个定時器来更新録音時长
                self.startRecordingTimer()
                self.startMonitoringAudioLevels() // 开始监听音频电平
                completion(true) // 録音成功，传递结果
            } catch {
                print("音频会话配置失败: \(error.localizedDescription)")
            }
        }
    }

    func stopRecording() -> URL? {
        guard let recorder = audioRecorder else {
            print("音频録音器未正确初始化")
            return nil
        }
        recorder.stop()
        stopMonitoringAudioLevels() // 停止监听音频电平

        if let recordingURL = recordingURL {
            do {
                let fileSize = try FileManager.default.attributesOfItem(atPath: recordingURL.path)[FileAttributeKey.size] as? Int64
                print("録音文件大小: \(fileSize ?? 0) bytes")
            } catch {
                print("无法获取文件大小: \(error.localizedDescription)")
            }
        }
        print("结束録音 \(Date())")
        recordingDuration = 0 // 録音结束后重置時长
        return recordingURL
    }
    
    func cancelRecording() {
        guard let recorder = audioRecorder else {
            print("音频録音器未正确初始化")
            return
        }
        recorder.stop()
        recordingDuration = 0 // 録音结束后重置時长
        stopMonitoringAudioLevels() // 停止监听音频电平

        // 删除録音文件
        if let recordingURL = recordingURL {
            do {
                try FileManager.default.removeItem(at: recordingURL)
                print("録音已取消并删除文件")
            } catch {
                print("无法删除録音文件: \(error.localizedDescription)")
            }
        }
    }
    
    private func startMonitoringAudioLevels() {
        audioPower = []
        // 确保没有旧的定時器正在运行
        stopMonitoringAudioLevels()
        
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            if let recorder = self.audioRecorder, recorder.isRecording {
                recorder.updateMeters()
                let power = recorder.averagePower(forChannel: 0) // 获取音量电平
                self.audioPower.append(power) // 更新波形数据
                if self.audioPower.count > 45 { // 控制波形显示的点数，限制最大数目
                    self.audioPower.removeFirst()
                }
            } else {
                self.stopMonitoringAudioLevels()
            }
        }
    }

    private func stopMonitoringAudioLevels() {
        // 停止并释放定時器，停止监听音频电平
        timer?.invalidate()
        timer = nil // 置为nil，確保不再使用
    }
}
