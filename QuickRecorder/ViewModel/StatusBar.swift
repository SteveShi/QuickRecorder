//
//  StatusBar.swift
//  QuickRecorder
//
//  Created by apple on 2024/4/16.
//

import SwiftUI

@MainActor
class PopoverState: ObservableObject {
    static let shared = PopoverState()
    @Published var isShowing: Bool = false
    @Published var isPaused: Bool = false
    @Published var isRecording: Bool = false
}

struct MenuBarLabel: View {
    @State private var recordingLength = "00:00"
    @ObservedObject private var popoverState = PopoverState.shared
    
    var body: some View {
        Group {
            if popoverState.isRecording {
                HStack(alignment: .center, spacing: 5) {
                    Image(systemName: popoverState.isPaused ? "pause.circle.fill" : "record.circle.fill")
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(popoverState.isPaused ? Color.yellow : Color.red, Color.white)
                        .font(.system(size: 11, weight: .bold))
                    
                    Text(recordingLength)
                        .font(.system(size: 12, weight: .semibold, design: .monospaced))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 2.5)
                .background(
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(Color.mypurple.opacity(0.85))
                        .shadow(color: .black.opacity(0.25), radius: 2, y: 1)
                )
                .fixedSize()
            } else {
                Image(systemName: "dot.circle.and.hand.point.up.left.fill")
                    .lineLimit(1)
            }
        }
        .onReceive(updateTimer) { t in
            let recording = (SCContext.streamType != nil)
            if popoverState.isRecording != recording {
                popoverState.isRecording = recording
            }
            if recording {
                recordingLength = SCContext.getRecordingLength()
                let timePassed = Date.now.timeIntervalSince(SCContext.startTime ?? t)
                if SCContext.autoStop != 0 && timePassed / 60 >= CGFloat(SCContext.autoStop) {
                    SCContext.stopRecording()
                }
            }
        }
    }
}

struct MenuBarContentView: View {
    @ObservedObject private var popoverState = PopoverState.shared
    
    var body: some View {
        if SCContext.streamType != nil {
            RecordingControlsView()
        } else {
            ContentViewNew()
                .onAppear {
                    closeAllWindow()
                }
        }
    }
}

struct RecordingControlsView: View {
    @ObservedObject private var popoverState = PopoverState.shared
    @State private var recordingLength = "00:00"
    @State private var isCameraPopoverShowing = false
    @State private var deviceWindowIsShowing = true
    
    var body: some View {
        VStack(spacing: 14) {
            HStack {
                Circle()
                    .fill(popoverState.isPaused ? Color.yellow : Color.red)
                    .frame(width: 10, height: 10)
                Text(popoverState.isPaused ? "Paused".local : "Recording".local)
                    .font(.headline)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(recordingLength)
                    .font(.system(size: 20, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.primary)
            }
            .padding(.horizontal, 4)
            
            Divider()
            
            HStack(spacing: 12) {
                // 停止录制
                Button(action: {
                    if SCContext.streamType == .idevice {
                        AVOutputClass.shared.stopRecording()
                    } else {
                        SCContext.stopRecording()
                    }
                }) {
                    Label("Stop".local, systemImage: "stop.circle.fill")
                        .foregroundStyle(.red)
                }
                .buttonStyle(.borderedProminent)
                .tint(.red.opacity(0.15))
                
                // 暂停/继续
                if SCContext.streamType != .idevice {
                    Button(action: {
                        SCContext.pauseRecording()
                    }) {
                        Label(
                            popoverState.isPaused ? "Resume".local : "Pause".local,
                            systemImage: popoverState.isPaused ? "play.circle.fill" : "pause.circle.fill"
                        )
                    }
                    .buttonStyle(.bordered)
                }
                
                // 摄像头控制
                if SCContext.streamType != .systemaudio && SCContext.streamType != .idevice && SCContext.streamType != .window {
                    Button(action: {
                        isCameraPopoverShowing.toggle()
                    }) {
                        Label("Camera".local, systemImage: "camera.circle.fill")
                    }
                    .buttonStyle(.bordered)
                    .popover(isPresented: $isCameraPopoverShowing, arrowEdge: .bottom) {
                        CameraPopoverView(closePopover: {
                            isCameraPopoverShowing = false
                        })
                    }
                }
                
                // 移动设备镜像窗口切换
                if SCContext.streamType == .idevice {
                    Button(action: {
                        DispatchQueue.main.async {
                            if deviceWindow.isVisible {
                                deviceWindow.close()
                            } else {
                                deviceWindow.orderFront(nil)
                            }
                            deviceWindowIsShowing = deviceWindow.isVisible
                        }
                    }) {
                        Label("Preview".local, systemImage: deviceWindowIsShowing ? "eye.circle.fill" : "eye.slash.circle.fill")
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
        .padding(16)
        .frame(minWidth: 280)
        .onReceive(updateTimer) { _ in
            recordingLength = SCContext.getRecordingLength()
        }
    }
}
