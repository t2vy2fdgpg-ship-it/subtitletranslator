import SwiftUI
import WidgetKit

// MARK: - Widget Bundle
@main
struct SubtitleWidgetBundle: WidgetBundle {
    var body: some Widget {
        SubtitleLiveActivity()
        SubtitleStatusWidget()
    }
}

// MARK: - Live Activity (Dynamic Island + Lock Screen)
struct SubtitleLiveActivity: Widget {
    let kind: String = "SubtitleLiveActivity"

    var body: some WidgetConfiguration {
        ActivityConfiguration(for: SubtitleActivityAttributes.self) { context in
            // Lock Screen / Banner
            LockScreenLiveActivityView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded
                DynamicIslandExpandedRegion(.leading) {
                    Label("字幕", systemImage: "captions.bubble")
                        .font(.caption2)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(context.state.sourceLanguage)
                        .font(.caption2)
                }
                DynamicIslandExpandedRegion(.center) {
                    VStack(spacing: 2) {
                        Text(context.state.originalText)
                            .font(.caption)
                            .lineLimit(2)
                            .multilineTextAlignment(.center)
                        if !context.state.translatedText.isEmpty {
                            Text(context.state.translatedText)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    HStack {
                        Image(systemName: "waveform")
                        Text("实时字幕")
                            .font(.caption2)
                    }
                }
            } compactLeading: {
                Image(systemName: "captions.bubble.fill")
                    .font(.caption2)
            } compactTrailing: {
                Text(context.state.originalText)
                    .font(.caption2)
                    .lineLimit(1)
            } minimal: {
                Image(systemName: "captions.bubble.fill")
            }
        }
    }
}

// MARK: - Lock Screen Live Activity View
struct LockScreenLiveActivityView: View {
    let context: ActivityViewContext<SubtitleActivityAttributes>

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: "captions.bubble.fill")
                    .foregroundColor(.blue)
                Text("实时字幕")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text(context.state.sourceLanguage)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Text(context.state.originalText)
                .font(.subheadline)
                .fontWeight(.medium)
                .lineLimit(2)

            if !context.state.translatedText.isEmpty {
                Text(context.state.translatedText)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
        }
        .padding()
    }
}

// MARK: - Live Activity Attributes
struct SubtitleActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var originalText: String
        var translatedText: String
        var sourceLanguage: String
        var targetLanguage: String
    }

    var sessionID: UUID
}

// MARK: - Home Screen Widget
struct SubtitleStatusWidget: Widget {
    let kind: String = "SubtitleStatusWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: kind,
            provider: SubtitleWidgetProvider()
        ) { entry in
            SubtitleWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("悬浮字幕状态")
        .description("在主屏幕查看字幕运行状态和最近记录")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Widget Timeline Provider
struct SubtitleWidgetProvider: TimelineProvider {
    typealias Entry = SubtitleWidgetEntry

    func placeholder(in context: Context) -> SubtitleWidgetEntry {
        SubtitleWidgetEntry(
            date: Date(),
            isActive: false,
            recentText: "等待启动...",
            recentTranslation: ""
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (SubtitleWidgetEntry) -> Void) {
        completion(fetchCurrentEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SubtitleWidgetEntry>) -> Void) {
        let entry = fetchCurrentEntry()
        let timeline = Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(5)))
        completion(timeline)
    }

    private func fetchCurrentEntry() -> SubtitleWidgetEntry {
        let defaults = UserDefaults(suiteName: AppGroupConstants.groupIdentifier)
        let active = defaults?.bool(forKey: "isCapturing") ?? false
        var recentText = "等待启动..."
        var recentTranslation = ""

        if let dict = defaults?.dictionary(forKey: AppGroupConstants.subtitleUpdateKey) {
            recentText = dict["originalText"] as? String ?? ""
            recentTranslation = dict["translatedText"] as? String ?? ""
        }

        return SubtitleWidgetEntry(
            date: Date(),
            isActive: active,
            recentText: recentText.isEmpty ? "等待启动..." : recentText,
            recentTranslation: recentTranslation
        )
    }
}

// MARK: - Widget Entry
struct SubtitleWidgetEntry: TimelineEntry {
    let date: Date
    let isActive: Bool
    let recentText: String
    let recentTranslation: String
}

// MARK: - Widget Entry View
struct SubtitleWidgetEntryView: View {
    var entry: SubtitleWidgetEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: "captions.bubble.fill")
                    .foregroundColor(entry.isActive ? .green : .gray)
                Text("悬浮字幕")
                    .font(.caption)
                    .fontWeight(.semibold)
                Spacer()
                Circle()
                    .fill(entry.isActive ? Color.green : Color.gray)
                    .frame(width: 6, height: 6)
            }

            Text(entry.recentText)
                .font(.caption2)
                .foregroundColor(.primary)
                .lineLimit(3)

            if !entry.recentTranslation.isEmpty {
                Text(entry.recentTranslation)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(12)
        .containerBackground(.fill.tertiary, for: .widget)
    }
}
