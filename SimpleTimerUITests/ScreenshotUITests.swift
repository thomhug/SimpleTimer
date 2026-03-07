import XCTest

final class ScreenshotUITests: XCTestCase {
    let app = XCUIApplication()

    override func setUpWithError() throws {
        continueAfterFailure = false
        app.launch()
        // Dismiss notification dialog if present
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let allowButton = springboard.buttons["Allow"]
        if allowButton.waitForExistence(timeout: 3) {
            allowButton.tap()
        }
    }

    func testScreenshots() throws {
        sleep(1)

        // 1: Home screen (timers)
        takeScreenshot(named: "01_timers")

        // 2: Log view with statistics
        app.buttons["log-button"].tap()
        sleep(1)
        takeScreenshot(named: "02_log")

        // Dismiss log
        app.buttons["Done"].tap()
        sleep(1)

        // 3: Settings
        app.buttons["settings-button"].tap()
        sleep(1)
        takeScreenshot(named: "03_settings")

        // Dismiss settings
        app.buttons["Done"].tap()
        sleep(1)
    }

    private func takeScreenshot(named name: String) {
        let screenshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
