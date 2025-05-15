//
//  PermissionManager.swift
//  iChatGPT
//
//  Created by 宇都宮　誠 on R 7/05/11.
//

import AVFoundation
import UIKit

enum AppPermissionType {
    case microphone
    case camera
}

class PermissionManager {
    /// 検査権限（麥克風 / 相機）
    static func checkPermission(for type: AppPermissionType, completion: @escaping (Bool) -> Void) {
        switch type {
            case .microphone:
                let status = AVAudioApplication.shared.recordPermission
                switch status {
                    case .granted:
                        completion(true) // 用户已授予权限
                        print("麥克風權限已授予 \(Date())")
                    case .denied:
                        completion(false) // 用户拒绝了权限
                        print("麥克風權限被拒絕")
                    case .undetermined:
                        // 当权限状态是不确定時，请求权限
                        AVAudioApplication.requestRecordPermission { granted in
                            DispatchQueue.main.async {
                                completion(granted) // 授权结果会触发系统弹框
                                if granted {
                                    print("用戶同意了麥克風權限")
                                } else {
                                    print("用戶拒絕了麥克風權限")
                                }
                            }
                        }
                    @unknown default:
                        completion(false)
                }

            
            case .camera:
                let status = AVCaptureDevice.authorizationStatus(for: .video)
                switch status {
                    case .authorized:
                        completion(true) // 用户已授予权限
                    print("カメラ權限已授予 \(Date())")
                    case .denied, .restricted:
                        completion(false) // 用户拒绝了权限
                    print("カメラ權限被拒絕")
                    case .notDetermined:
                        AVCaptureDevice.requestAccess(for: .video) { granted in
                            DispatchQueue.main.async {
                                completion(granted) // 授权结果会触发系统弹框
                                if granted {
                                    print("用戶同意了カメラ權限")
                                } else {
                                    print("用戶拒絕了カメラ權限")
                                }
                            }
                        }
                    @unknown default:
                        completion(false)
                }
        }
    }

    /// 開啟系統設定畫面
//    static func openSettings() {
//        if let appSettingsURL = URL(string: UIApplication.openSettingsURLString),
//           UIApplication.shared.canOpenURL(appSettingsURL) {
//            UIApplication.shared.open(appSettingsURL)
//        }
//    }
}
