//
//  MenuBarIconHelperTests.swift
//  MagSafe Guard
//

import MagSafeGuardCore
import XCTest

@testable import MagSafeGuard

final class MenuBarIconHelperTests: XCTestCase {

  func testMonochromeHasNoContentTint() {
    for state: MenuBarIconHelper.VisualState in [
      .disarmed, .armed, .gracePeriod, .triggered,
    ] {
      XCTAssertNil(
        MenuBarIconHelper.contentTint(for: .monochrome, state: state),
        "Expected nil tint for \(state)"
      )
    }
  }

  func testAccentProvidesTintPerState() {
    XCTAssertNotNil(MenuBarIconHelper.contentTint(for: .accent, state: .armed))
    XCTAssertNotNil(MenuBarIconHelper.contentTint(for: .accent, state: .gracePeriod))
    XCTAssertNotNil(MenuBarIconHelper.contentTint(for: .accent, state: .triggered))
    XCTAssertNotNil(MenuBarIconHelper.contentTint(for: .accent, state: .disarmed))
  }

  func testAccentTintsDifferByState() {
    let armed = MenuBarIconHelper.accentTint(for: .armed)
    let grace = MenuBarIconHelper.accentTint(for: .gracePeriod)
    let triggered = MenuBarIconHelper.accentTint(for: .triggered)
    XCTAssertNotEqual(armed, grace)
    XCTAssertNotEqual(grace, triggered)
  }

  func testDefaultSettingsUseMonochromeMenuBarIcons() {
    XCTAssertEqual(Settings().menuBarIconAppearance, .monochrome)
  }
}
