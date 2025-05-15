//
//  OpenAIWhisperService.swift
//  音频上传和语音识别
//
//  Created by EKI KOUKA on R 6/10/13.
//

import Foundation
import AVFoundation

class OpenAIWhisperService {
    // 从配置文件中获取 API 密钥
    let CHATGPT_API_KEY = Bundle.main.object(forInfoDictionaryKey: "CHATGPT_API_KEY") as? String
    
    func recognizeAudio(from videoURL: URL, completion: @escaping (String?) -> Void) {
        let asset = AVAsset(url: videoURL)
        let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetAppleM4A)

        let audioURL = FileManager.default.temporaryDirectory.appendingPathComponent("extractedAudio.m4a")

        exportSession?.outputURL = audioURL
        exportSession?.outputFileType = .m4a

        exportSession?.exportAsynchronously {
            switch exportSession?.status {
            case .completed:
                // 调用 Whisper API 进行音频识别
                self.uploadAudio(fileURL: audioURL, completion: completion)
            case .failed:
                print("音频提取失败: \(String(describing: exportSession?.error))")
                completion(nil)
            case .cancelled:
                print("音频提取被取消")
                completion(nil)
            default:
                break
            }
        }
    }
    
    func uploadAudio(fileURL: URL, completion: @escaping (String?) -> Void) {
        guard let CHATGPT_API_KEY = CHATGPT_API_KEY else {
            print("CHATGPT_API_KEY API key not found")
            return
        }
        
        let boundary = "Boundary-\(UUID().uuidString)"
        var request = URLRequest(url: URL(string: "https://api.openai.com/v1/audio/transcriptions")!)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(CHATGPT_API_KEY)", forHTTPHeaderField: "Authorization")
        var data = Data()
        
        data.append("\r\n--\(boundary)\r\n".data(using: .utf8)!)
        data.append("Content-Disposition: form-data; name=\"file\"; filename=\"recording.wav\"\r\n".data(using: .utf8)!)
        data.append("Content-Type: audio/wav\r\n\r\n".data(using: .utf8)!)
        
        // 读取 .wav 文件的数据并附加到请求中
        if let fileData = try? Data(contentsOf: fileURL) {
            data.append(fileData)
            print("音频文件加载成功")
        } else {
            print("无法加载音频文件: \(fileURL.absoluteString)")
        }

        data.append("\r\n--\(boundary)\r\n".data(using: .utf8)!)
        data.append("Content-Disposition: form-data; name=\"model\"\r\n\r\n".data(using: .utf8)!)
        data.append("whisper-1".data(using: .utf8)!)

        data.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)

        let task = URLSession.shared.uploadTask(with: request, from: data) { responseData, response, error in
            if let error = error {
                print("上传请求失败: \(error.localizedDescription)")
                completion(nil)
                return
            }

            guard let responseData = responseData else {
                print("没有收到服务器返回的数据 请求失败：\(error?.localizedDescription ?? "未知错误")")
                completion(nil)
                return
            }
            
            if let jsonResponse = try? JSONSerialization.jsonObject(with: responseData, options: []) as? [String: Any],
               let transcription = jsonResponse["text"] as? String {
                print("transcription: \(transcription)")
                completion(transcription)
                
                // 上传成功后删除录音文件
                self.deleteRecordingFile(at: fileURL)
            } else {
                print("无法解析服务器返回的数据: \(String(data: responseData, encoding: .utf8) ?? "未知格式")")
                completion(nil)
            }
        }

        print("开始上传音频文件到 OpenAI Whisper API")
        task.resume()
    }
    
    // 删除录音文件的函数
    func deleteRecordingFile(at url: URL) {
        if FileManager.default.fileExists(atPath: url.path) {
            do {
                try FileManager.default.removeItem(at: url)
            } catch {
                print("无法删除录音文件: \(error.localizedDescription)")
            }
        } else {
            print("录音文件不存在: \(url.absoluteString)")
        }
    }
}
