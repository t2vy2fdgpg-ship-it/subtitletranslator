import SwiftUI

// MARK: - Main Content View
struct ContentView: View {
    @EnvironmentObject var settings: AppSettings
    @EnvironmentObject var subtitleManager: SubtitleOverlayManager
    @EnvironmentObject var audioEngine: AudioCaptureEngine
    @EnvironmentObject var speechRecognizer: SpeechRecognizer

    var body: some View {
        MainView()
    }
}
