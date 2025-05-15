//
//  ChatInputView.swift
//  iChatGPT
//
//  Created by EKI KOUKA on R 6/10/03.
//

import SwiftUI
import PhotosUI

struct ChatInputView: View {
    @Binding var inputText: String
    @StateObject private var audioRecorder = AudioRecorder()
    private let whisperService = OpenAIWhisperService()
    @State private var isRecording = false
    @State private var isLoading = false
    @State private var showMicroAlert = false
    @State private var showCameraAlert = false
    
    @Environment(\.colorScheme) var colorScheme //dark mode
    var onSend: () -> Void

    @State private var imageSelection: PhotosPickerItem? = nil
    @State private var showPhotosPicker = false
    @State private var showDocumentPicker = false
    @State private var showCameraPicker = false
    @State private var imageSource: UIImagePickerController.SourceType = .photoLibrary
    @Binding var mediaFileOnlineAddress: String?
    
    var body: some View {
        ZStack {
            // 背景块
            RoundedRectangle(cornerRadius: 20)
                .fill(colorScheme == .dark ? Color(red: 31/255, green: 31/255, blue: 31/255) : Color(red: 245/255, green: 245/255, blue: 245/255))
                .frame(height: 100) // 设置背景块的高度

            VStack {
                // input
                TextField("メッセージ", text: $inputText, onCommit: {
                    onSend()
                })
//                .padding(.vertical, 15)
                .padding(.horizontal, 22) // 左右
//                .background(colorScheme == .dark ? Color(red: 31/255, green: 31/255, blue: 31/255) : Color(red: 245/255, green: 245/255, blue: 245/255))
//                .cornerRadius(30)

                HStack {
                    if isRecording {
                        // record left close button
                        Button(action: {
                            audioRecorder.cancelRecording()
                            isRecording = false
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 27))
                                .foregroundColor(colorScheme == .dark ? .white : .black)
                        }

                        // Wave 錄音波形試圖
                        WaveformView(audioPower: audioRecorder.audioPower)
                            .frame(height: 40) // 傳遞 audioRecored實例
//                            .padding(.leading, 48)
//                            .padding(.trailing, 0)

                        Text(formatDuration(audioRecorder.recordingDuration))
//                            .padding(.leading, 0)
//                            .padding(.trailing, 47)

                        // record right check button
                        Button(action: {
                            isLoading = true
                            if let audioURL = audioRecorder.stopRecording() {
                                whisperService.uploadAudio(fileURL: audioURL) { transcription in
                                    if let result = transcription {
                                        isLoading = false
                                        self.inputText = result
                                    }
                                }
                            } else {
                                print("録音ファイル不可用")
                            }
                            isRecording = false
                        }) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 27))
                                .foregroundColor(colorScheme == .dark ? .white : .black)
                        }
                    } else if isLoading {
                        // loading button
                        Spacer()
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                            .frame(width: 27, height: 27)
                            .foregroundColor(.blue)
                    } else {
                        // plus メーニュー
                        ChatInputFileTypeMenu(
                            showPhotosPicker: $showPhotosPicker,
                            showDocumentPicker: $showDocumentPicker,
                            showCameraPicker: $showCameraPicker,
                            imageSource: $imageSource,
                            showCameraAlert: $showCameraAlert
                        )
                        .photosPicker(isPresented: $showPhotosPicker, selection: $imageSelection, matching: .images)
                        .onChange(of: imageSelection) { newItem in
                            guard let newItem else { return }
                            Task {
                                if let data = try? await newItem.loadTransferable(type: Data.self) {
                                    print("data: ", data)
                                    onlineFileAddress(fileData: data)
                                }
                            }
                        }
                        .sheet(isPresented: $showDocumentPicker) {
                            DocumentPicker { data in
                                print("data: ", data)
                                onlineFileAddress(fileData: data)
                            }
                        }
                        .fullScreenCover(isPresented: $showCameraPicker) {
                            ZStack {
                                // 黑色覆蓋層
                                VStack {
                                    Color.black
                                        .ignoresSafeArea(edges: .top) // 僅忽略頂部安全區域
                                    Spacer()
                                    Color.black
                                        .ignoresSafeArea(edges: .bottom) // 僅忽略底部安全區域
                                }
                                CameraPicker(completion: { image in
                                    if let data = image.jpegData(compressionQuality: 0.8) {
                                        print("data: ", data)
                                        onlineFileAddress(fileData: data)
                                        showCameraPicker = false
                                    }
                                })
                            }
                        }
                        Spacer()
                        
                        // Mic 録音ボタン
                        Button(action: {
                            audioRecorder.startRecording { granted in
                                if !granted {
                                    showMicroAlert = true
                                } else {
                                    isRecording = true
                                }
                            }
                        }) {
                            Image(systemName: "mic")
                                .font(.system(size: 16))
                                .foregroundColor(colorScheme == .dark ? .white : .black)
                                .padding()
                                .opacity(inputText.trimmingCharacters(in: .whitespaces).isEmpty ? 1.0 : 0.5)
                        }
                        .disabled(!inputText.trimmingCharacters(in: .whitespaces).isEmpty)
                        
                        // send button
                        Button(action: onSend) {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.system(size: 26))
                                .foregroundColor(colorScheme == .dark ? .white : .black)
                                .opacity(
                                    inputText.trimmingCharacters(in: .whitespaces).isEmpty &&
                                    mediaFileOnlineAddress == nil
                                    ? 0.5 : 1.0)
                        }
                        .disabled(inputText.trimmingCharacters(in: .whitespaces).isEmpty && mediaFileOnlineAddress == nil)
                    }
                }
                .padding(.horizontal, 16)
            }
            .permissionAlert(
                isPresented: $showMicroAlert,
                title: "マイクへのアクセスが必要です",
                message: "マイクのアクセスが拒否されました。音声認識機能を使用するには、設定でマイクのアクセスを有効にしてください。"
            )
            .permissionAlert(
                isPresented: $showCameraAlert,
                title: "カメラへのアクセスが必要です",
                message: "カメラのアクセスが拒否されました。画像の分析をするには、設定でカメラのアクセスを有効にしてください。"
            )
        }
        .padding(EdgeInsets(top: 0, leading: 10, bottom: 10, trailing: 10))
    }

    // 格式化时长的函数
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%2d:%02d", minutes, seconds)
    }
    
    private func onlineFileAddress(fileData: Data? = nil) -> Void {
        print("fileData: ", fileData)
        guard let fileData else { return }
        isLoading = true
        MediaFileOnlineAddress().upload(fileData: fileData) { searchResult in
            guard let searchResult = searchResult else {
                isLoading = false
                return
            }
            isLoading = false
            mediaFileOnlineAddress = searchResult
        }
    }
}
