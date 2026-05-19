import SwiftUI
import AVFoundation
import BackgroundTasks

@main
struct SubtitleTranslatorApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var settings = AppSettings.shared
    @StateObject private var subtitleManager = SubtitleOverlayManager.shared
    @StateObject private var audioEngine = AudioCaptureEngine.shared
    @StateObject private var speechRecognizer = SpeechRecognizer.shared

    var body: some Scene {
        WindowGroup {
            MainView()
                .environmentObject(settings)
                .environmentObject(subtitleManager)
                .environmentObject(audioEngine)
                .environmentObject(speechRecognizer)
                .preferredColorScheme(.dark)
        }
    }
}

// MARK: - App Delegate
final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // Configure audio session
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(
                .playAndRecord,
                mode: .videoRecording,
                options: [.allowBluetooth, .allowBluetoothA2DP, .mixWithOthers]
            )
            try session.setActive(true)
        } catch {
            print("[SubtitleApp] Audio session setup failed: \(error)")
        }

        // Register background task
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: "com.subtitletranslator.processing",
            using: nil
        ) { task in
            self.handleBackgroundTask(task as! BGProcessingTask)
        }

        return true
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        if AppSettings.shared.isEnabled {
            scheduleBackgroundTask()
        }
    }

    private func scheduleBackgroundTask() {
        let request = BGProcessingTaskRequest(identifier: "com.subtitletranslator.processing")
        request.requiresNetworkConnectivity = false
        request.requiresExternalPower = false
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("[SubtitleApp] Failed to schedule background task: \(error)")
        }
    }

    private func handleBackgroundTask(_ task: BGProcessingTask) {
        task.expirationHandler = { task.setTaskCompleted(success: false) }
        // Keep audio session alive
        task.setTaskCompleted(success: true)
        scheduleBackgroundTask()
    }
}
