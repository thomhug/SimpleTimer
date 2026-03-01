import SwiftUI
import UserNotifications

@main
struct SimpleTimerApp: App {
    @AppStorage("appearance") private var appearance: String = "system"
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(colorScheme)
                .onAppear {
                    UNUserNotificationCenter.current().requestAuthorization(
                        options: [.alert, .sound]
                    ) { _, _ in }
                }
                .sheet(isPresented: .init(
                    get: { !hasSeenOnboarding },
                    set: { if !$0 { hasSeenOnboarding = true } }
                )) {
                    OnboardingView {
                        hasSeenOnboarding = true
                    }
                    .interactiveDismissDisabled()
                }
        }
    }

    private var colorScheme: ColorScheme? {
        switch appearance {
        case "light": return .light
        case "dark": return .dark
        default: return nil
        }
    }
}

struct OnboardingView: View {
    var onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            Image(systemName: "timer")
                .font(.system(size: 64))
                .foregroundStyle(.tint)

            Text("SimpleTimer")
                .font(.largeTitle.weight(.bold))

            VStack(alignment: .leading, spacing: 20) {
                OnboardingRow(
                    icon: "hand.tap",
                    text: String(localized: "Tap to start/stop")
                )
                OnboardingRow(
                    icon: "stopwatch",
                    text: String(localized: "Set to 0:00 for stopwatch mode")
                )
                OnboardingRow(
                    icon: "hand.tap.fill",
                    text: String(localized: "Long-press to configure")
                )
            }
            .padding(.horizontal, 32)

            Spacer()

            Button {
                onDismiss()
            } label: {
                Text("Got it")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal, 32)
            .padding(.bottom, 32)
        }
    }
}

private struct OnboardingRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.tint)
                .frame(width: 32)
            Text(text)
                .font(.body)
        }
    }
}
