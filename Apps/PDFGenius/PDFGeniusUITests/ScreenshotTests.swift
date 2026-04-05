import XCTest

@MainActor
class ScreenshotTests: XCTestCase {
    let app = XCUIApplication()

    override func setUp() {
        continueAfterFailure = false
        setupSnapshot(app)
        app.launch()
    }

    func testScreenshots() {
        sleep(3)
        snapshot("01_Documents")

        app.tabBars.buttons["Tools"].tap()
        sleep(1)
        snapshot("02_Tools")

        app.tabBars.buttons["Settings"].tap()
        sleep(1)
        snapshot("03_Settings")

        app.tabBars.buttons["Documents"].tap()
        sleep(1)
        snapshot("04_DocumentList")
    }
}
