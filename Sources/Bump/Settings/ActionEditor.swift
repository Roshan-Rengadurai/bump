import SwiftUI
import AppKit

/// Edits a single `ActionConfig` — kind picker plus the parameter controls the
/// chosen kind needs. Used for both global and per-app mappings.
struct ActionEditor: View {
    @Binding var config: ActionConfig
    var includeNone: Bool = true
    var onTest: (ActionConfig) -> Void

    private var kinds: [ActionKind] {
        ActionKind.allCases.filter { includeNone || $0 != .none }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Picker("", selection: $config.kind) {
                    ForEach(kinds) { kind in
                        Label(kind.label, systemImage: kind.symbol).tag(kind)
                    }
                }
                .labelsHidden()

                Spacer()

                if config.kind != .none {
                    Button {
                        onTest(config)
                    } label: {
                        Label("Test", systemImage: "play.fill")
                    }
                    .controlSize(.small)
                }
            }

            parameters
        }
    }

    @ViewBuilder private var parameters: some View {
        switch config.kind {
        case .launchApp:
            HStack {
                Text(appName).foregroundStyle(config.appPath == nil ? .secondary : .primary)
                    .lineLimit(1)
                Spacer()
                Button("Choose App…") { chooseApp() }.controlSize(.small)
            }
        case .runScript:
            VStack(alignment: .leading, spacing: 6) {
                Picker("Interpreter", selection: Binding(
                    get: { config.scriptKind ?? .shell },
                    set: { config.scriptKind = $0 }
                )) {
                    ForEach(ScriptKind.allCases) { Text($0.label).tag($0) }
                }
                .pickerStyle(.segmented)
                TextEditor(text: Binding(get: { config.script ?? "" },
                                         set: { config.script = $0 }))
                    .font(.system(.callout, design: .monospaced))
                    .frame(height: 70)
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(.quaternary))
            }
        case .runShortcut:
            TextField("Shortcut name", text: Binding(get: { config.shortcutName ?? "" },
                                                     set: { config.shortcutName = $0 }))
                .textFieldStyle(.roundedBorder)
        case .showText:
            TextField("Text to flash on screen", text: Binding(get: { config.text ?? "" },
                                                               set: { config.text = $0 }))
                .textFieldStyle(.roundedBorder)
        case .reaction:
            Picker("Effect", selection: Binding(get: { config.reaction ?? .screenFlash },
                                                set: { config.reaction = $0 })) {
                ForEach(ReactionKind.allCases) { Label($0.label, systemImage: $0.symbol).tag($0) }
            }
        default:
            EmptyView()
        }
    }

    private var appName: String {
        guard let path = config.appPath else { return "No app chosen" }
        return (path as NSString).lastPathComponent.replacingOccurrences(of: ".app", with: "")
    }

    private func chooseApp() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.application]
        panel.allowsMultipleSelection = false
        panel.directoryURL = URL(fileURLWithPath: "/Applications")
        if panel.runModal() == .OK, let url = panel.url {
            config.appPath = url.path
        }
    }
}
