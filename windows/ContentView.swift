import SwiftUI

struct ContentView: View {
    @State private var settings = AppSettings.shared
    @State private var accessibilityGranted = AccessibilityHelper.isGranted()

    var body: some View {
        Form {
            Section("Modifier Key") {
                Picker("Modifier", selection: $settings.modifierKey) {
                    ForEach(ModifierKey.allCases) { key in
                        Text("\(key.symbol) \(key.rawValue)").tag(key)
                    }
                }
                .pickerStyle(.segmented)
            }

            Section("Window Sizes") {
                VStack(alignment: .leading) {
                    HStack {
                        Text("Left width:")
                        Text("\(Int(settings.leftWidthPercent))%")
                            .monospacedDigit()
                            .frame(width: 40, alignment: .trailing)
                    }
                    Slider(value: $settings.leftWidthPercent, in: 20...80, step: 5)
                    Text(
                        "Left: \(Int(settings.leftWidthPercent))% / Right: \(Int(settings.rightWidthPercent))%"
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }

                VStack(alignment: .leading) {
                    HStack {
                        Text("Top height:")
                        Text("\(Int(settings.topHeightPercent))%")
                            .monospacedDigit()
                            .frame(width: 40, alignment: .trailing)
                    }
                    Slider(value: $settings.topHeightPercent, in: 20...80, step: 5)
                    Text(
                        "Top: \(Int(settings.topHeightPercent))% / Bottom: \(Int(settings.bottomHeightPercent))%"
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
            }

            Section("Preview") {
                SnapPreview(
                    leftPercent: settings.leftWidthPercent,
                    topPercent: settings.topHeightPercent
                )
                .frame(height: 120)
            }

            Section("Permissions") {
                HStack {
                    Circle()
                        .fill(accessibilityGranted ? .green : .red)
                        .frame(width: 10, height: 10)
                    Text("Accessibility")
                    Spacer()
                    if !accessibilityGranted {
                        Button("Grant") {
                            AccessibilityHelper.requestAccess()
                        }
                    } else {
                        Text("OK").foregroundStyle(.secondary)
                    }
                }

                Button("Refresh Status") {
                    accessibilityGranted = AccessibilityHelper.isGranted()
                }

                Toggle("Launch at Login", isOn: Binding(
                    get: { settings.launchAtLogin },
                    set: { settings.launchAtLogin = $0 }
                ))
            }

            Section("Hotkeys") {
                let mod = settings.modifierKey.symbol
                Grid(alignment: .leading, horizontalSpacing: 20, verticalSpacing: 6) {
                    GridRow {
                        Text("\(mod) + C")
                        Text("Center (60%)").foregroundStyle(.secondary)
                    }
                    GridRow {
                        Text("").gridCellColumns(2)
                    }
                    GridRow {
                        Text("\(mod) + \u{2190}")
                        Text("Left half").foregroundStyle(.secondary)
                    }
                    GridRow {
                        Text("\(mod) + \u{2192}")
                        Text("Right half").foregroundStyle(.secondary)
                    }
                    GridRow {
                        Text("\(mod) + \u{2191}")
                        Text("Top half").foregroundStyle(.secondary)
                    }
                    GridRow {
                        Text("\(mod) + \u{2193}")
                        Text("Bottom half").foregroundStyle(.secondary)
                    }
                    GridRow {
                        Text("\(mod) + \u{2190} + \u{2191}")
                        Text("Top left quarter").foregroundStyle(.secondary)
                    }
                    GridRow {
                        Text("\(mod) + \u{2190} + \u{2193}")
                        Text("Bottom left quarter").foregroundStyle(.secondary)
                    }
                    GridRow {
                        Text("\(mod) + \u{2192} + \u{2191}")
                        Text("Top right quarter").foregroundStyle(.secondary)
                    }
                    GridRow {
                        Text("\(mod) + \u{2192} + \u{2193}")
                        Text("Bottom right quarter").foregroundStyle(.secondary)
                    }
                    GridRow {
                        Text("").gridCellColumns(2)
                    }
                    GridRow {
                        Text("⇧ + \(mod) + \u{2190} + \u{2191}")
                        Text("Top left eighth").foregroundStyle(.secondary)
                    }
                    GridRow {
                        Text("⇧ + \(mod) + \u{2190} + \u{2193}")
                        Text("Bottom left eighth").foregroundStyle(.secondary)
                    }
                    GridRow {
                        Text("⇧ + \(mod) + \u{2192} + \u{2191}")
                        Text("Top right eighth").foregroundStyle(.secondary)
                    }
                    GridRow {
                        Text("⇧ + \(mod) + \u{2192} + \u{2193}")
                        Text("Bottom right eighth").foregroundStyle(.secondary)
                    }
                }
                .font(.system(.body, design: .monospaced))
            }
        }
        .formStyle(.grouped)
        .frame(minWidth: 420, maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Snap Preview

struct SnapPreview: View {
    let leftPercent: Double
    let topPercent: Double

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let splitX = w * leftPercent / 100
            let splitY = h * topPercent / 100

            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .stroke(.secondary, lineWidth: 1)

                Path { path in
                    path.move(to: CGPoint(x: splitX, y: 0))
                    path.addLine(to: CGPoint(x: splitX, y: h))
                }
                .stroke(.blue.opacity(0.6), style: StrokeStyle(lineWidth: 1, dash: [4, 3]))

                Path { path in
                    path.move(to: CGPoint(x: 0, y: splitY))
                    path.addLine(to: CGPoint(x: w, y: splitY))
                }
                .stroke(.blue.opacity(0.6), style: StrokeStyle(lineWidth: 1, dash: [4, 3]))

                VStack {
                    HStack {
                        Text("\(Int(leftPercent))%")
                            .frame(width: splitX, height: splitY)
                        Text("\(Int(100 - leftPercent))%")
                            .frame(width: w - splitX, height: splitY)
                    }
                    HStack {
                        Text("\(Int(leftPercent))%")
                            .frame(width: splitX, height: h - splitY)
                        Text("\(Int(100 - leftPercent))%")
                            .frame(width: w - splitX, height: h - splitY)
                    }
                }
                .font(.caption2)
                .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    ContentView()
}
