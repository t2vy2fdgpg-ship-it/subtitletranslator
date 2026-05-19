import SwiftUI

// MARK: - Main View
struct MainView: View {
    @EnvironmentObject var settings: AppSettings
    @EnvironmentObject var subtitleManager: SubtitleOverlayManager
    @EnvironmentObject var audioEngine: AudioCaptureEngine
    @EnvironmentObject var speechRecognizer: SpeechRecognizer

    @State private var showingSettings = false
    @State private var showingBroadcastPicker = false

    var body: some View {
        ZStack {
            // Background
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    // App Header
                    headerSection

                    // Toggle Switch Section
                    toggleSection

                    // Subtitle Style Section
                    styleSection

                    // Language Section
                    languageSection

                    // Status Section
                    statusSection

                    // Preview Section
                    previewSection

                    // Extra Settings
                    extraSection
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 24)
            }
        }
        .sheet(isPresented: $showingSettings) {
            NavigationStack {
                SettingsView()
                    .environmentObject(settings)
            }
        }
        .onAppear {
            if settings.isEnabled {
                startCapture()
            }
        }
    }

    // MARK: - Header
    private var headerSection: some View {
        VStack(spacing: 4) {
            Image(systemName: "captions.bubble.fill")
                .font(.system(size: 36))
                .foregroundStyle(.linearGradient(
                    colors: [.blue, .purple],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))

            Text("悬浮字幕")
                .font(.title2)
                .fontWeight(.bold)

            Text("实时中英双语字幕")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.top, 16)
    }

    // MARK: - Toggle Section
    private var toggleSection: some View {
        VStack(spacing: 0) {
            HStack(spacing: 16) {
                // Status indicator
                Circle()
                    .fill(settings.isEnabled ? Color.green : Color.gray.opacity(0.4))
                    .frame(width: 12, height: 12)

                VStack(alignment: .leading, spacing: 2) {
                    Text(settings.isEnabled ? "字幕运行中" : "字幕已关闭")
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text(settings.isEnabled ? "悬浮窗已显示，正在监听音频" : "点击开关启动字幕服务")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Toggle("", isOn: Binding(
                    get: { settings.isEnabled },
                    set: { newValue in
                        withAnimation(.easeInOut(duration: 0.2)) {
                            settings.isEnabled = newValue
                            if newValue {
                                startCapture()
                                subtitleManager.showOverlay()
                            } else {
                                stopCapture()
                                subtitleManager.hideOverlay()
                            }
                        }
                    }
                ))
                .tint(.blue)
                .labelsHidden()
                .scaleEffect(1.2)
            }
            .padding(20)
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
        )
    }

    // MARK: - Style Section
    private var styleSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "textformat.size")
                    .foregroundColor(.blue)
                Text("字幕样式")
                    .font(.headline)
            }

            VStack(spacing: 16) {
                // Font Size
                VStack(alignment: .leading, spacing: 6) {
                    Text("字体大小: \(Int(settings.appearance.fontSize))pt")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Slider(value: Binding(
                        get: { settings.appearance.fontSize },
                        set: { settings.appearance.fontSize = $0 }
                    ), in: 12...36, step: 1)
                    .tint(.blue)
                }

                // Opacity
                VStack(alignment: .leading, spacing: 6) {
                    Text("字幕透明度: \(Int(settings.appearance.opacity * 100))%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Slider(value: Binding(
                        get: { settings.appearance.opacity },
                        set: { settings.appearance.opacity = $0 }
                    ), in: 0.3...1.0, step: 0.05)
                    .tint(.blue)
                }

                // Font Color
                HStack {
                    Text("字体颜色")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    ColorPicker("", selection: Binding(
                        get: { settings.appearance.fontColor.color },
                        set: { settings.appearance.fontColor = CodableColor($0) }
                    ))
                    .labelsHidden()
                    .scaleEffect(0.8)
                }

                // Background Color
                HStack {
                    Text("背景颜色")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    ColorPicker("", selection: Binding(
                        get: { settings.appearance.backgroundColor.color },
                        set: { settings.appearance.backgroundColor = CodableColor($0) }
                    ))
                    .labelsHidden()
                    .scaleEffect(0.8)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
        )
    }

    // MARK: - Language Section
    private var languageSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "globe")
                    .foregroundColor(.blue)
                Text("语言设置")
                    .font(.headline)
            }

            VStack(spacing: 12) {
                // Source Language
                HStack {
                    Text("识别语言")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    Spacer()
                    Picker("", selection: Binding(
                        get: { settings.sourceLanguage },
                        set: { settings.sourceLanguage = $0 }
                    )) {
                        ForEach(SubtitleLanguage.allCases, id: \.self) { lang in
                            Text(lang.displayName).tag(lang)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 140)
                }

                // Target Language
                HStack {
                    Text("翻译语言")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    Spacer()
                    Picker("", selection: Binding(
                        get: { settings.targetLanguage },
                        set: { settings.targetLanguage = $0 }
                    )) {
                        ForEach(SubtitleLanguage.allCases, id: \.self) { lang in
                            Text(lang.displayName).tag(lang)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 140)
                }

                Divider()

                // Language Order
                HStack {
                    Text("显示顺序")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    Spacer()
                    Picker("", selection: Binding(
                        get: { settings.languageOrder },
                        set: { settings.languageOrder = $0 }
                    )) {
                        ForEach(LanguageOrder.allCases, id: \.self) { order in
                            Text(order.displayName).tag(order)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 140)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
        )
    }

    // MARK: - Status Section
    private var statusSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(.blue)
                Text("运行状态")
                    .font(.headline)
                Spacer()
                Text(audioEngine.captureMode.rawValue)
                    .font(.caption)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(settings.isEnabled ? Color.green.opacity(0.15) : Color.gray.opacity(0.15))
                    )
                    .foregroundColor(settings.isEnabled ? .green : .secondary)
            }

            // Audio level meter
            if settings.isEnabled {
                HStack(spacing: 2) {
                    ForEach(0..<20, id: \.self) { i in
                        RoundedRectangle(cornerRadius: 1)
                            .fill(
                                audioEngine.audioLevel > Float(i) / 20.0
                                    ? Color.green
                                    : Color.gray.opacity(0.2)
                            )
                            .frame(height: 8)
                    }
                }
                .animation(.easeInOut(duration: 0.1), value: audioEngine.audioLevel)
            }

            if speechRecognizer.isRecognizing {
                HStack {
                    ProgressView()
                        .scaleEffect(0.7)
                    Text("正在识别中...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            if !speechRecognizer.interimResult.isEmpty {
                Text("识别: \(speechRecognizer.interimResult)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
        )
    }

    // MARK: - Preview Section
    private var previewSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "eye.fill")
                    .foregroundColor(.blue)
                Text("字幕预览")
                    .font(.headline)
            }

            // Preview of how subtitles look
            VStack(spacing: 6) {
                if settings.languageOrder == .originalFirst {
                    previewLine(text: subtitleManager.currentOriginal.isEmpty ? "原文将显示在此" : subtitleManager.currentOriginal, isOriginal: true)
                    previewLine(text: subtitleManager.currentTranslation.isEmpty ? "Translation appears here" : subtitleManager.currentTranslation, isOriginal: false)
                } else {
                    previewLine(text: subtitleManager.currentTranslation.isEmpty ? "Translation appears here" : subtitleManager.currentTranslation, isOriginal: false)
                    previewLine(text: subtitleManager.currentOriginal.isEmpty ? "原文将显示在此" : subtitleManager.currentOriginal, isOriginal: true)
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: settings.appearance.cornerRadius)
                    .fill(settings.appearance.backgroundColor.color)
            )
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
        )
    }

    private func previewLine(text: String, isOriginal: Bool) -> some View {
        Text(text)
            .font(.system(size: settings.appearance.fontSize * 0.7))
            .foregroundColor(settings.appearance.fontColor.color)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity, alignment: .center)
    }

    // MARK: - Extra Section
    private var extraSection: some View {
        VStack(spacing: 12) {
            // Offline Mode Toggle
            HStack {
                Image(systemName: "wifi.slash")
                    .foregroundColor(settings.offlineMode ? .green : .secondary)
                Text("离线模式")
                    .font(.subheadline)
                Spacer()
                Toggle("", isOn: Binding(
                    get: { settings.offlineMode },
                    set: { settings.offlineMode = $0 }
                ))
                .labelsHidden()
                .tint(.blue)
            }

            Divider()

            // Auto Split
            HStack {
                Image(systemName: "text.alignleft")
                    .foregroundColor(settings.autoSplitSentence ? .green : .secondary)
                Text("自动断句")
                    .font(.subheadline)
                Spacer()
                Toggle("", isOn: Binding(
                    get: { settings.autoSplitSentence },
                    set: { settings.autoSplitSentence = $0 }
                ))
                .labelsHidden()
                .tint(.blue)
            }

            Divider()

            // Clear History
            Button(action: {
                withAnimation {
                    subtitleManager.clearHistory()
                }
            }) {
                HStack {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                    Text("清除字幕记录")
                        .font(.subheadline)
                        .foregroundColor(.red)
                    Spacer()
                }
            }

            Divider()

            // Advanced Settings
            Button(action: {
                showingSettings = true
            }) {
                HStack {
                    Image(systemName: "gearshape.fill")
                        .foregroundColor(.blue)
                    Text("高级设置")
                        .font(.subheadline)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
        )

        // Version
        Text("v1.0.0 · 纯本地处理 · 无需联网")
            .font(.caption2)
            .foregroundColor(.secondary)
            .padding(.top, 8)
            .padding(.bottom, 40)
    }

    // MARK: - Actions
    private func startCapture() {
        do {
            try audioEngine.startMicrophoneCapture()
        //} catch {
            print("[MainView] Failed to start capture: \(error)")
        }

        do {
            try speechRecognizer.startRecognition(offlineMode: settings.offlineMode)
        } catch {
            print("[MainView] Failed to start recognition: \(error)")
        }

        // Wire audio → speech
        audioEngine.onAudioChunk = { pcmBuffer in
            speechRecognizer.appendAudioBuffer(pcmBuffer)
        }
    //}
let mockText = "This is a mock text for demonstration purposes."
speechRecognizer.appendtext(mockText)
    }
    private func stopCapture() {
        audioEngine.stopMicrophoneCapture()
        speechRecognizer.stopRecognition()
        audioEngine.onAudioChunk = nil
    }
}

// MARK: - Preview
#Preview {
    MainView()
        .environmentObject(AppSettings.shared)
        .environmentObject(SubtitleOverlayManager.shared)
        .environmentObject(AudioCaptureEngine.shared)
        .environmentObject(SpeechRecognizer.shared)
        .preferredColorScheme(.dark)
}
