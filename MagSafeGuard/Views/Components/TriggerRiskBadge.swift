//
//  TriggerRiskBadge.swift
//  MagSafe Guard
//

import MagSafeGuardCore
import SwiftUI

struct TriggerRiskBadge: View {
  let level: TriggerRiskLevel
  var compact: Bool = false

  var body: some View {
    Text(label)
      .font(compact ? .caption2 : .caption)
      .fontWeight(.medium)
      .padding(.horizontal, compact ? 6 : 8)
      .padding(.vertical, compact ? 2 : 3)
      .foregroundColor(foreground)
      .background(background)
      .clipShape(Capsule())
      .accessibilityLabel(accessibilityLabel)
  }

  private var label: String {
    switch level {
    case .low:
      return L10n.tr("risk.level.low.short")
    case .moderate:
      return L10n.tr("risk.level.moderate.short")
    case .severe:
      return L10n.tr("risk.level.severe.short")
    }
  }

  private var accessibilityLabel: String {
    switch level {
    case .low:
      return L10n.tr("risk.level.low.accessibility")
    case .moderate:
      return L10n.tr("risk.level.moderate.accessibility")
    case .severe:
      return L10n.tr("risk.level.severe.accessibility")
    }
  }

  private var foreground: Color {
    switch level {
    case .low: return .green
    case .moderate: return .orange
    case .severe: return .red
    }
  }

  private var background: Color {
    foreground.opacity(0.15)
  }
}

struct TriggerRiskLegendView: View {
  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text(l10n: "risk.legend.title")
        .font(.caption)
        .fontWeight(.semibold)
        .foregroundColor(.secondary)

      ForEach(TriggerRiskLevel.allCases, id: \.self) { level in
        HStack(alignment: .top, spacing: 8) {
          TriggerRiskBadge(level: level, compact: true)
          Text(legendDescription(for: level))
            .font(.caption)
            .foregroundColor(.secondary)
            .fixedSize(horizontal: false, vertical: true)
        }
      }
    }
    .padding(.vertical, 4)
  }

  private func legendDescription(for level: TriggerRiskLevel) -> String {
    switch level {
    case .low:
      return L10n.tr("risk.legend.low")
    case .moderate:
      return L10n.tr("risk.legend.moderate")
    case .severe:
      return L10n.tr("risk.legend.severe")
    }
  }
}
