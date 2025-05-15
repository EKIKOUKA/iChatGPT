//
//  WaveformView.swift
//  iChatGPT
// 
//  Created by EKI KOUKA on R 6/10/14.
//

import SwiftUI

struct WaveformView: View {
    var audioPower: [Float] // AudioRecorderPower
    @Environment(\.colorScheme) var colorScheme //dark mode

    var body: some View {
        GeometryReader { geometry in
            Path { path in
                let width = geometry.size.width
                let height = geometry.size.height

                let barWidth: CGFloat = width / CGFloat(audioPower.count) // 每个波形条的宽度
                let midHeight = height / 2 // 波形中线

                for (index, power) in audioPower.enumerated() {
                    let normalizedPower = normalizePower(power)
                    let x = CGFloat(index) * barWidth
                    let barHeight = midHeight * normalizedPower

                    // 绘制波形条，向上和向下延伸
                    path.move(to: CGPoint(x: x, y: midHeight - barHeight))
                    path.addLine(to: CGPoint(x: x, y: midHeight + barHeight))
                }
            }
            .stroke(colorScheme == .dark ? Color.white : Color.black, lineWidth: 2) // 波形颜色和线宽
            //.animation(.linear(duration: 0.01), value: audioPower) // 动画效果
        }
    }

    // 将音频功率标准化到 0.0 到 1.0 的范围
    private func normalizePower(_ power: Float) -> CGFloat {
        // 在很安静的环境下，常见的音频功率标准一般在 -60dB 到 -40dB 之间。设置为-60.0 dB，这可以捕捉到更细微的声音。如果希望排除一些背景噪声，可以将 minPower 设置为 -50.0 dB 或 -55.0 dB，以确保在安静环境中仅捕获有效的声音输入。
        let minPower: Float = -60.0 // 设定最小功率值
        let maxPower: Float = 0.0 // 设定最大功率值

        // 将功率映射到 0 到 1 的范围
        let normalizedPower = min(max((power - minPower) / (maxPower - minPower), 0.0), 1.0)
        return CGFloat(normalizedPower)
    }
}
