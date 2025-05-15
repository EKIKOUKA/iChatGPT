//
//  ChatInputFileTypeMenu.swift
//  iChatGPT
//
//  Created by 宇都宮　誠 on R 7/05/10.
//

import SwiftUI

struct ChatInputFileTypeMenu: View {
    @Binding var showPhotosPicker: Bool
    @Binding var showDocumentPicker: Bool
    @Binding var showCameraPicker: Bool
    @Binding var imageSource: UIImagePickerController.SourceType
    @Binding var showCameraAlert: Bool

    @Environment(\.colorScheme) var colorScheme //dark mode
    
    var body: some View {
        Menu {
            Button {
                showPhotosPicker = true
            } label: {
                Label("写真", systemImage: "photo")
            }
            /* PhotosPicker(selection: $imageSelection, matching: .images) {
                    Image(systemName: "photo")
                }
                .onChange(of: imageSelection) { newItem in
                    Task {}
            } */
            
            Button {
                PermissionManager.checkPermission(for: .camera) { granted in
                    if granted {
                        imageSource = .camera
                        showCameraPicker = true
                    } else {
                        showCameraAlert = true
                    }
                }
                
            } label: {
                Label("カメラ", systemImage: "camera")
            }
            
            Button {
                showDocumentPicker = true
            } label: {
                Label("ファイル", systemImage: "folder")
            }
            
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 20))
                .padding(10)
                .foregroundStyle(colorScheme == .dark ? Color.white : Color.black)
        }
    }
}
