import Foundation
import Combine

final class BreakTimerViewModel: ObservableObject {
    let durations = [15 * 60, 30 * 60, 60 * 60]

    func durationTitle(_ seconds: Int) -> String {
        "\(seconds / 60) min"
    }
}
