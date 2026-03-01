import ActivityKit
import SwiftUI
import WidgetKit

struct TimerLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TimerActivityAttributes.self) { context in
            // Lock Screen presentation
            HStack {
                Text(context.attributes.timerName)
                    .font(.headline)
                Spacer()
                Text(timerInterval: Date.now...context.state.endDate, countsDown: true)
                    .font(.system(size: 28, weight: .thin, design: .rounded))
                    .monospacedDigit()
                    .frame(width: 100)
                    .multilineTextAlignment(.trailing)
            }
            .padding()
            .activityBackgroundTint(.black.opacity(0.7))
            .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Text(context.attributes.timerName)
                        .font(.headline)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(timerInterval: Date.now...context.state.endDate, countsDown: true)
                        .font(.system(size: 22, weight: .thin, design: .rounded))
                        .monospacedDigit()
                        .frame(width: 90)
                        .multilineTextAlignment(.trailing)
                }
            } compactLeading: {
                Image(systemName: "timer")
            } compactTrailing: {
                Text(timerInterval: Date.now...context.state.endDate, countsDown: true)
                    .font(.system(size: 13, weight: .thin, design: .rounded))
                    .monospacedDigit()
                    .frame(width: 50)
                    .multilineTextAlignment(.trailing)
            } minimal: {
                Image(systemName: "timer")
            }
        }
    }
}

@main
struct SimpleTimerWidgets: WidgetBundle {
    var body: some Widget {
        TimerLiveActivity()
    }
}
