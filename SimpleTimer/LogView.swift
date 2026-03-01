import SwiftUI
import Charts
import UniformTypeIdentifiers

// MARK: - Data Types

private enum TimeRange: String, CaseIterable {
    case week = "Week"
    case month = "Month"
    case year = "Year"
    case all = "All"
}

private struct BarSegment: Identifiable {
    let id = UUID()
    let date: Date
    let timerName: String
    let minutes: Double
}

private struct TrendPoint: Identifiable {
    let id: Date
    let minutes: Double
}

// MARK: - LogView

struct LogView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showDeleteConfirmation = false
    @State private var selectedRange: TimeRange = .week
    @State private var selectedBar: Date?
    private var log = TimerLog.shared

    private static let dateTimeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "dd.MM. HH:mm:ss"
        return f
    }()

    // MARK: - Filtered entries

    private var filteredEntries: [TimerLogEntry] {
        let calendar = Calendar.current
        let now = Date()
        switch selectedRange {
        case .week:
            let start = calendar.date(byAdding: .day, value: -6, to: calendar.startOfDay(for: now))!
            return log.entries.filter { $0.timestamp >= start }
        case .month:
            let start = calendar.date(byAdding: .month, value: -1, to: calendar.startOfDay(for: now))!
            return log.entries.filter { $0.timestamp >= start }
        case .year:
            let start = calendar.date(byAdding: .year, value: -1, to: calendar.startOfDay(for: now))!
            return log.entries.filter { $0.timestamp >= start }
        case .all:
            return log.entries
        }
    }

    // MARK: - Statistics

    private var totalSecondsThisWeek: Int {
        let calendar = Calendar.current
        let start = calendar.date(byAdding: .day, value: -6, to: calendar.startOfDay(for: Date()))!
        return log.entries.filter { $0.timestamp >= start }.reduce(0) { $0 + $1.seconds }
    }

    private var sessionsThisWeek: Int {
        let calendar = Calendar.current
        let start = calendar.date(byAdding: .day, value: -6, to: calendar.startOfDay(for: Date()))!
        return log.entries.filter { $0.timestamp >= start }.count
    }

    private var averageSessionSeconds: Int {
        guard sessionsThisWeek > 0 else { return 0 }
        return totalSecondsThisWeek / sessionsThisWeek
    }

    private var currentStreak: Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let entryDays = Set(log.entries.map { calendar.startOfDay(for: $0.timestamp) })

        var streak = 0
        var day = today
        while entryDays.contains(day) {
            streak += 1
            guard let prev = calendar.date(byAdding: .day, value: -1, to: day) else { break }
            day = prev
        }
        return streak
    }

    // MARK: - Per-timer stats

    private struct TimerStats: Identifiable {
        let id: String
        let name: String
        let totalSeconds: Int
        let count: Int
        let longest: Int
        let shortest: Int
    }

    private var perTimerStats: [TimerStats] {
        let grouped = Dictionary(grouping: filteredEntries) { $0.timerName }
        return grouped.map { name, entries in
            TimerStats(
                id: name,
                name: name,
                totalSeconds: entries.reduce(0) { $0 + $1.seconds },
                count: entries.count,
                longest: entries.map(\.seconds).max() ?? 0,
                shortest: entries.map(\.seconds).min() ?? 0
            )
        }.sorted { $0.totalSeconds > $1.totalSeconds }
    }

    // MARK: - Chart data

    private var chartSegments: [BarSegment] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: filteredEntries) { entry -> Date in
            calendar.startOfDay(for: entry.timestamp)
        }
        var segments: [BarSegment] = []
        for (day, entries) in grouped {
            let byTimer = Dictionary(grouping: entries) { $0.timerName }
            for (name, timerEntries) in byTimer {
                let total = timerEntries.reduce(0) { $0 + $1.seconds }
                segments.append(BarSegment(date: day, timerName: name, minutes: Double(total) / 60.0))
            }
        }
        return segments.sorted { $0.date < $1.date }
    }

    private var trendPoints: [TrendPoint] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: filteredEntries) { entry -> Date in
            calendar.startOfDay(for: entry.timestamp)
        }
        let dailyTotals = grouped.map { day, entries in
            (day, entries.reduce(0) { $0 + $1.seconds })
        }.sorted { $0.0 < $1.0 }

        guard dailyTotals.count >= 3 else { return [] }

        var points: [TrendPoint] = []
        for i in 2..<dailyTotals.count {
            let avg = Double(dailyTotals[i-2].1 + dailyTotals[i-1].1 + dailyTotals[i].1) / 3.0 / 60.0
            points.append(TrendPoint(id: dailyTotals[i].0, minutes: avg))
        }
        return points
    }

    private var timerNames: [String] {
        Array(Set(filteredEntries.map(\.timerName))).sorted()
    }

    private static let timerColors: [Color] = [.blue, .green, .orange, .purple, .pink, .red]

    private func colorFor(_ name: String) -> Color {
        let index = timerNames.firstIndex(of: name) ?? 0
        return Self.timerColors[index % Self.timerColors.count]
    }

    // MARK: - Bar detail

    private var selectedDayEntries: [TimerLogEntry] {
        guard let day = selectedBar else { return [] }
        let calendar = Calendar.current
        let next = calendar.date(byAdding: .day, value: 1, to: day)!
        return log.entries.filter { $0.timestamp >= day && $0.timestamp < next }
    }

    // MARK: - CSV

    private func generateCSV() -> String {
        var csv = "Timestamp,Timer,Duration (seconds),Duration (formatted)\n"
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd HH:mm:ss"
        for entry in log.entries {
            let formatted = Self.format(entry.seconds)
            csv += "\(df.string(from: entry.timestamp)),\(entry.timerName),\(entry.seconds),\(formatted)\n"
        }
        return csv
    }

    private func exportCSV() {
        let csv = generateCSV()
        let tmpURL = FileManager.default.temporaryDirectory.appendingPathComponent("SimpleTimer_Log.csv")
        try? csv.write(to: tmpURL, atomically: true, encoding: .utf8)

        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = scene.windows.first,
              let root = window.rootViewController else { return }

        let activityVC = UIActivityViewController(activityItems: [tmpURL], applicationActivities: nil)
        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = window
            popover.sourceRect = CGRect(x: window.bounds.midX, y: window.bounds.midY, width: 0, height: 0)
        }
        root.present(activityVC, animated: true)
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Group {
                if log.entries.isEmpty {
                    ContentUnavailableView(
                        "No Log",
                        systemImage: "list.bullet.clipboard",
                        description: Text("Timer events will appear here.")
                    )
                } else {
                    List {
                        // Stats header
                        Section {
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                                StatCard(title: String(localized: "This Week"), value: Self.formatDuration(totalSecondsThisWeek))
                                StatCard(title: String(localized: "Sessions"), value: "\(sessionsThisWeek)")
                                StatCard(title: String(localized: "Average"), value: Self.formatDuration(averageSessionSeconds))
                                StatCard(title: String(localized: "Streak"), value: String(localized: "\(currentStreak) days"))
                            }
                            .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                            .listRowBackground(Color.clear)
                        }

                        // Chart
                        Section {
                            VStack(spacing: 8) {
                                Picker("Range", selection: $selectedRange) {
                                    ForEach(TimeRange.allCases, id: \.self) { range in
                                        Text(LocalizedStringKey(range.rawValue)).tag(range)
                                    }
                                }
                                .pickerStyle(.segmented)

                                if chartSegments.isEmpty {
                                    Text("No data for this period")
                                        .foregroundStyle(.secondary)
                                        .frame(height: 150)
                                } else {
                                    chartView
                                }
                            }
                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                        }

                        // Day detail
                        if selectedBar != nil {
                            Section {
                                dayDetailContent
                            }
                        }

                        // Per-timer breakdown
                        if !perTimerStats.isEmpty {
                            Section("Per Timer") {
                                ForEach(perTimerStats) { stat in
                                    VStack(alignment: .leading, spacing: 4) {
                                        HStack {
                                            Circle()
                                                .fill(colorFor(stat.name))
                                                .frame(width: 10, height: 10)
                                            Text(stat.name)
                                                .font(.subheadline.weight(.medium))
                                            Spacer()
                                            Text(Self.formatDuration(stat.totalSeconds))
                                                .font(.subheadline)
                                                .foregroundStyle(.secondary)
                                        }
                                        HStack {
                                            Text("\(stat.count) sessions")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                            Spacer()
                                            Text("Longest: \(Self.format(stat.longest))")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                            Text("Shortest: \(Self.format(stat.shortest))")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                }
                            }
                        }

                        // History
                        Section("History") {
                            ForEach(log.entries) { entry in
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(entry.timerName)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                        Text(Self.dateTimeFormatter.string(from: entry.timestamp))
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    Text(Self.format(entry.seconds))
                                        .font(.system(.body, design: .rounded))
                                }
                            }
                            .onDelete { offsets in
                                let idsToDelete = offsets.map { log.entries[$0].id }
                                withAnimation {
                                    for id in idsToDelete {
                                        log.delete(id: id)
                                    }
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Log")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if !log.entries.isEmpty {
                        Menu {
                            Button {
                                exportCSV()
                            } label: {
                                Label("Export CSV", systemImage: "square.and.arrow.up")
                            }
                            Button(role: .destructive) {
                                showDeleteConfirmation = true
                            } label: {
                                Label("Delete All", systemImage: "trash")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .confirmationDialog("Delete log?", isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
                Button("Delete", role: .destructive) {
                    log.clear()
                }
            }
        }
    }

    // MARK: - Chart view

    private var chartView: some View {
        Chart {
            ForEach(chartSegments) { segment in
                BarMark(
                    x: .value("Day", segment.date, unit: .day),
                    y: .value("Minutes", segment.minutes)
                )
                .foregroundStyle(by: .value("Timer", segment.timerName))
            }

            ForEach(trendPoints) { point in
                LineMark(
                    x: .value("Day", point.id, unit: .day),
                    y: .value("Trend", point.minutes)
                )
                .foregroundStyle(.gray.opacity(0.6))
                .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 3]))
                .interpolationMethod(.catmullRom)
            }
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .day)) { _ in
                AxisValueLabel(format: .dateTime.weekday(.abbreviated), centered: true)
            }
        }
        .chartOverlay { proxy in
            GeometryReader { geo in
                Rectangle()
                    .fill(.clear)
                    .contentShape(Rectangle())
                    .onTapGesture { location in
                        let x = location.x - geo[proxy.plotFrame!].origin.x
                        if let date: Date = proxy.value(atX: x) {
                            let calendar = Calendar.current
                            selectedBar = calendar.startOfDay(for: date)
                        }
                    }
            }
        }
        .frame(height: 180)
    }

    // MARK: - Day detail content

    private var dayDetailContent: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                if let day = selectedBar {
                    Text(day, format: .dateTime.weekday(.wide).month(.abbreviated).day())
                        .font(.headline)
                }
                Spacer()
                Button {
                    selectedBar = nil
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
            }

            ForEach(selectedDayEntries) { entry in
                HStack {
                    Text(entry.timerName)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(Self.format(entry.seconds))
                        .font(.system(.body, design: .rounded))
                }
            }
        }
    }

    // MARK: - Formatting helpers

    static func format(_ totalSeconds: Int) -> String {
        let m = totalSeconds / 60
        let s = totalSeconds % 60
        return String(format: "%02d:%02d", m, s)
    }

    static func formatDuration(_ totalSeconds: Int) -> String {
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)min"
        } else {
            return "\(minutes)min"
        }
    }
}

// MARK: - StatCard

private struct StatCard: View {
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2.weight(.semibold))
                .minimumScaleFactor(0.7)
                .lineLimit(1)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
