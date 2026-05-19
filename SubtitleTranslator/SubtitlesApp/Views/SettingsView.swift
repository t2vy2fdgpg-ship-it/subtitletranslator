import SwiftUI

// MARK: - Advanced Settings View
struct SettingsView: View {
    @EnvironmentObject var settings: AppSettings
    @EnvironmentObject var speechRecognizer: SpeechRecognizer
    @Environment(\.dismiss) var dismiss

    var body: some View {
        List {
            // MARK: - Recognition Section
            Section {
                HStack {
                    Image(systemName: "brain.head.profile")
                        .foregroundColor(.purple)
                        .frame(width: 24)
                    Text("语音识别引擎")
                    Spacer()
                    Text("Apple SFSpeech")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                HStack {
                    Image(systemName: "antenna.radiowaves.left.and.right")
                        .foregroundColor(.blue)
                        .frame(width: 24)
                    Text("设备端识别支持")
                    Spacer()
                    Image(systemName: speechRecognizer.supportsOnDeviceRecognition ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(speechRecognizer.supportsOnDeviceRecognition ? .green : .red)
                }

                HStack {
                    Image(systemName: "checkmark.shield")
                        .foregroundColor(.green)
                        .frame(width: 24)
                    Text("语音权限")
                    Spacer()
                    Image(systemName: speechRecognizer.isAvailable ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(speechRecognizer.isAvailable ? .green : .red)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Label("离线模式说明", systemImage: "info.circle")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                    Text("开启离线模式后，语音识别和翻译将完全在设备本地处理。首次使用需在设置→通用→键盘→听写中下载对应语言包。中文和英文均已支持离线语音识别。")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.vertical, 4)
            } header: {
                Text("语音识别")
            }

            // MARK: - Translation Section
            Section {
                HStack {
                    Image(systemName: "text.bubble")
                        .foregroundColor(.orange)
                        .frame(width: 24)
                    Text("翻译引擎")
                    Spacer()
                    Text("Apple NLTranslator + 内置词库")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                HStack {
                    Image(systemName: "books.vertical")
                        .foregroundColor(.brown)
                        .frame(width: 24)
                    Text("内置词典词条")
                    Spacer()
                    Text("100+ 常用影视短语")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Label("翻译说明", systemImage: "info.circle")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                    Text("优先使用Apple NLTranslator进行本地离线翻译，支持中英双向互译。当NLTranslator不可用时自动降级为内置词典匹配翻译，确保基本可用性。所有翻译均在本地完成，无需联网。")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.vertical, 4)
            } header: {
                Text("翻译")
            }

            // MARK: - Subtitle Display Section
            Section {
                HStack {
                    Text("最大显示行数")
                    Spacer()
                    Stepper("\(settings.appearance.maxLines)", value: Binding(
                        get: { settings.appearance.maxLines },
                        set: { settings.appearance.maxLines = $0 }
                    ), in: 1...4)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Label("悬浮窗操作提示", systemImage: "hand.draw")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                    Text("- 拖动悬浮窗可改变位置\n- 所有设置实时生效\n- 悬浮窗层级高于所有APP\n- 支持竖屏/横屏自适应")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
            } header: {
                Text("字幕显示")
            }

            // MARK: - Audio Capture Section
            Section {
                HStack {
                    Image(systemName: "speaker.wave.2")
                        .foregroundColor(.teal)
                        .frame(width: 24)
                    Text("系统内录 (Broadcast)")
                    Spacer()
                    Text("iOS Broadcast 扩展")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                HStack {
                    Image(systemName: "mic")
                        .foregroundColor(.indigo)
                        .frame(width: 24)
                    Text("麦克风收音 (备用)")
                    Spacer()
                    Text("AVAudioEngine")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Label("音频捕获说明", systemImage: "info.circle")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                    Text("系统内录模式通过iOS Broadcast Upload Extension捕获设备内部播放的音频。从控制中心长按录屏按钮→选择「悬浮字幕」即可启动系统级音频捕获。备用麦克风模式直接录制环境声音。")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.vertical, 4)
            } header: {
                Text("音频捕获")
            }

            // MARK: - Data Section
            Section {
                Button(role: .destructive) {
                    SubtitleOverlayManager.shared.clearHistory()
                } label: {
                    HStack {
                        Image(systemName: "trash")
                        Text("清除所有字幕历史")
                    }
                }

                Button(role: .destructive) {
                    if let bundleID = Bundle.main.bundleIdentifier {
                        UserDefaults.standard.removePersistentDomain(forName: bundleID)
                    }
                    SubtitleOverlayManager.shared.clearHistory()
                } label: {
                    HStack {
                        Image(systemName: "arrow.triangle.2.circlepath")
                        Text("重置所有设置")
                    }
                }
            } header: {
                Text("数据管理")
            }

            // MARK: - About Section
            Section {
                HStack {
                    Text("版本")
                    Spacer()
                    Text("1.0.0")
                        .foregroundColor(.secondary)
                }

                HStack {
                    Text("最低系统")
                    Spacer()
                    Text("iOS 16.0")
                        .foregroundColor(.secondary)
                }

                HStack {
                    Text("隐私保护")
                    Spacer()
                    Text("纯本地处理 · 零数据上传")
                        .foregroundColor(.green)
                        .font(.caption)
                }
            } header: {
                Text("关于")
            }
        }
        .navigationTitle("高级设置")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("完成") { dismiss() }
            }
        }
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        SettingsView()
            .environmentObject(AppSettings.shared)
            .environmentObject(SpeechRecognizer.shared)
    }
}
