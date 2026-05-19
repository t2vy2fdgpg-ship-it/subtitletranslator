import SwiftUI

// MARK: - Floating Overlay Window
/// A globally-topmost floating window that displays bilingual subtitles.
/// It can be dragged freely and overlays all other apps.
final class FloatingOverlayWindow: UIWindow {
    static let shared = FloatingOverlayWindow()

    private let hostingController: UIHostingController<OverlayView>
    private var initialTouchOffset: CGPoint = .zero

    init() {
        // Find the active window scene
        var windowScene: UIWindowScene?
        for scene in UIApplication.shared.connectedScenes {
            if scene.activationState == .foregroundActive,
               let ws = scene as? UIWindowScene {
                windowScene = ws
                break
            }
        }

        if let ws = windowScene {
            self.hostingController = UIHostingController(
                rootView: OverlayView()
            )
            super.init(windowScene: ws)
        } else {
            // Fallback: use first available scene
            let scene = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .first!
            self.hostingController = UIHostingController(
                rootView: OverlayView()
            )
            super.init(windowScene: scene)
        }

        setupWindow()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupWindow() {
        windowLevel = .alert + 1
        backgroundColor = .clear
        isOpaque = false
        isHidden = false

        // Position window
        let settings = AppSettings.shared
        frame = CGRect(
            x: settings.windowPosition.x,
            y: settings.windowPosition.y,
            width: UIScreen.main.bounds.width - 40,
            height: 120
        )

        rootViewController = hostingController
        hostingController.view.backgroundColor = .clear

        // Add pan gesture for dragging
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        hostingController.view.addGestureRecognizer(panGesture)
    }

    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard let view = gesture.view else { return }

        switch gesture.state {
        case .began:
            initialTouchOffset = gesture.location(in: view)
        case .changed:
            let location = gesture.location(in: nil) // Screen coordinates
            let newX = location.x - initialTouchOffset.x
            let newY = location.y - initialTouchOffset.y

            // Clamp to screen bounds
            let safeX = max(0, min(newX, UIScreen.main.bounds.width - frame.width))
            let safeY = max(44, min(newY, UIScreen.main.bounds.height - frame.height - 44))

            frame.origin = CGPoint(x: safeX, y: safeY)

            // Save position
            AppSettings.shared.windowPosition = WindowPosition(x: safeX, y: safeY)

        default:
            break
        }
    }

    func refreshSize() {
        // Adjust size based on content
        let settings = AppSettings.shared
        let width = UIScreen.main.bounds.width - 40
        let estimatedHeight: CGFloat = max(80, settings.appearance.fontSize * 4 + 40)
        frame.size = CGSize(width: width, height: estimatedHeight)
    }
}

// MARK: - Overlay View (SwiftUI)
struct OverlayView: View {
    @ObservedObject private var settings = AppSettings.shared
    @ObservedObject private var manager = SubtitleOverlayManager.shared

    var body: some View {
        VStack(spacing: 4) {
            if settings.languageOrder == .originalFirst {
                subtitleLine(
                    text: manager.currentOriginal.isEmpty ? "等待语音..." : manager.currentOriginal,
                    weight: .semibold
                )
                subtitleLine(
                    text: manager.currentTranslation.isEmpty ? "" : manager.currentTranslation,
                    weight: .regular
                )
            } else {
                subtitleLine(
                    text: manager.currentTranslation.isEmpty ? "" : manager.currentTranslation,
                    weight: .regular
                )
                subtitleLine(
                    text: manager.currentOriginal.isEmpty ? "等待语音..." : manager.currentOriginal,
                    weight: .semibold
                )
            }
        }
        .padding(settings.appearance.padding)
        .background(
            RoundedRectangle(cornerRadius: settings.appearance.cornerRadius)
                .fill(settings.appearance.backgroundColor.color)
        )
        .opacity(settings.appearance.opacity)
        .allowsHitTesting(true)
    }

    private func subtitleLine(text: String, weight: Font.Weight) -> some View {
        Text(text)
            .font(.system(size: settings.appearance.fontSize, weight: weight))
            .foregroundColor(settings.appearance.fontColor.color)
            .multilineTextAlignment(.center)
            .lineLimit(2)
            .frame(maxWidth: .infinity, alignment: .center)
    }
}

// MARK: - Overlay Window Manager
final class OverlayWindowManager: ObservableObject {
    static let shared = OverlayWindowManager()
    @Published var isShowing = false

    private init() {}

    func show() {
        guard !isShowing else { return }
        FloatingOverlayWindow.shared.isHidden = false
        FloatingOverlayWindow.shared.refreshSize()
        isShowing = true
    }

    func hide() {
        FloatingOverlayWindow.shared.isHidden = true
        isShowing = false
    }

    func refresh() {
        FloatingOverlayWindow.shared.refreshSize()
    }
}
