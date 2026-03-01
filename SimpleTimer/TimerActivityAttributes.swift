import Foundation
import ActivityKit

struct TimerActivityAttributes: ActivityAttributes {
    let timerName: String

    struct ContentState: Codable, Hashable {
        let endDate: Date
    }
}
