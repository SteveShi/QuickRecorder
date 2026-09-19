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
        HStack(spacing: 4) {
            if popoverState.isRecording {
                Image(systemName: popoverState.isPaused ? "pause.circle.fill" : "record.circle")
                Text(recordingLength)
            } else {
                Image(systemName: "dot.circle.and.hand.point.up.left.fill")
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

struct MenuBarMenuView: View {
    @ObservedObject private var popoverState = PopoverState.shared
    @State private var recordingLength = "00:00"
    
    var body: some View {
        if popoverState.isRecording || SCContext.streamType != nil {
            Text("Recording: ".local + recordingLength)
            
            Divider()
            
            Button("Stop Recording".local) {
                if SCContext.streamType == .idevice {
                    AVOutputClass.shared.stopRecording()
                } else {
                    SCContext.stopRecording()
                }
            }
            .keyboardShortcut("s", modifiers: [.command, .option])
            
            if SCContext.streamType != .idevice {
                Button(popoverState.isPaused ? "Resume".local : "Pause".local) {
                    SCContext.pauseRecording()
                }
                .keyboardShortcut("p", modifiers: [.command, .option])
            }
            
            Divider()
        } else {
            Button("Start".local) {
                closeAllWindow()
                AppDelegate.shared.createNewWindow(view: ScreenSelector(), title: "Screen Selector".local)
            }
            
            Button("Screen Area".local) {
                closeAllWindow()
                AppDelegate.shared.showAreaSelector(size: NSSize(width: 600, height: 450))
            }
            
            Button("Window".local) {
                closeAllWindow()
                AppDelegate.shared.createNewWindow(view: WinSelector(), title: "Window Selector".local)
            }
            
            Button("Application".local) {
                closeAllWindow()
                AppDelegate.shared.createNewWindow(view: AppSelector(), title: "App Selector".local)
            }
            
            Button("System Audio".local) {
                if let display = SCContext.getSCDisplayWithMouse() {
                    closeAllWindow()
                    AppDelegate.shared.createCountdownPanel(screen: display) {
                        AppDelegate.shared.prepRecord(type: "audio", screens: SCContext.getSCDisplayWithMouse(), windows: nil, applications: nil)
                    }
                }
            }
            
            Divider()
            
            Button("Open Main Panel".local) {
                _ = AppDelegate.shared.applicationShouldHandleReopen(NSApp, hasVisibleWindows: true)
                NSApp.activate()
            }
            
            Divider()
        }
        
        Button("Preferences…".local) {
            AppDelegate.shared.openSettingPanel()
        }
        .keyboardShortcut(",", modifiers: .command)
        
        Button("Check for Updates…".local) {
            updaterController.checkForUpdates(nil)
        }
        
        Divider()
        
        Button("Quit QuickRecorder".local) {
            NSApp.terminate(nil)
        }
        .keyboardShortcut("q", modifiers: .command)
    }
}

