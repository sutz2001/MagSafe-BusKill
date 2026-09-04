//
//  MenuBarIconHelperTests.swift
//  MagSafe Guard
//

import MagSafeGuardCore
import XCTest

@testable import MagSafeGuard

final class MenuBarIconHelperTests: XCTestCase {

  func testMonochromeUsesTemplateStyleImage() {
    let image = MenuBarIconHelper.assetImage(
      named: "MenuBarIconArmed",
      appearance: .monochrome,
      state: .armed
    )
    XCTAssertNotNil(image)
    XCTAssertTrue(image?.isTemplate == true)
  }

  func testAccentBakesTintIntoImage() {
    let image = MenuBarIconHelper.assetImage(
      named: "MenuBarIconArmed",
      appearance: .accent,
      state: .armed
    )
    XCTAssertNotNil(image)
    XCTAssertFalse(image?.isTemplate == true)
  }

  func testAccentTintsDifferByState() {
    let armed = MenuBarIconHelper.accentTint(for: .armed)
    let grace = MenuBarIconHelper.accentTint(for: .gracePeriod)
    let triggered = MenuBarIconHelper.accentTint(for: .triggered)
    let paranoid = MenuBarIconHelper.accentTint(for: .paranoid)
    XCTAssertNotEqual(armed, grace)
    XCTAssertNotEqual(grace, triggered)
    XCTAssertNotEqual(triggered, paranoid)
  }

  func testDefaultSettingsUseMonochromeMenuBarIcons() {
    XCTAssertEqual(Settings().menuBarIconAppearance, .monochrome)
  }
}
