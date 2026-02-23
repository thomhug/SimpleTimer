import XCTest

final class ScreenshotUITests: XCTestCase {
    let app = XCUIApplication()

    override func setUpWithError() throws {
        continueAfterFailure = false
        app.launch()
    }

    func testTakeAppStoreScreenshots() throws {
        // 1: Home screen (timers)
        sleep(1)
        takeScreenshot(named: "01_timers")

        // 2: Settings
        app.buttons["settings-button"].tap()
        sleep(1)
        takeScreenshot(named: "02_settings")

        // Dismiss settings
        app.buttons["Done"].tap()
        sleep(1)

        // 3: Log
        app.buttons["log-button"].tap()
        sleep(1)
        takeScreenshot(named: "03_log")

        // Dismiss log
        app.buttons["Done"].tap()
        sleep(1)
    }

    func testTakeAppStoreScreenshotsDark() throws {
        sleep(1)
        takeScreenshot(named: "04_timers_dark")
    }

    private func takeScreenshot(named name: String) {
        let screenshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
