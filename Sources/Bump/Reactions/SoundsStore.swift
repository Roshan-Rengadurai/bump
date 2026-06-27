import Foundation
import Combine

/// Manages user-supplied combo sound clips stored in
/// `~/Library/Application Support/Bump/Sounds/`.
/// Files are copied in on `add()` and deleted on `remove()`.
@MainActor
final class SoundsStore: ObservableObject {
    @Published private(set) var files: [String] = []

    private let dir: URL

    init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        dir = appSupport.appendingPathComponent("Bump/Sounds", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        reload()
    }

    func reload() {
        let exts = Set(["wav", "mp3", "m4a", "aiff", "aif", "caf"])
        let all = (try? FileManager.default.contentsOfDirectory(atPath: dir.path)) ?? []
        files = all.filter { exts.contains(($0 as NSString).pathExtension.lowercased()) }.sorted()
    }

    func add(url: URL) throws {
        let dest = dir.appendingPathComponent(url.lastPathComponent)
        if FileManager.default.fileExists(atPath: dest.path) {
            try FileManager.default.removeItem(at: dest)
        }
        try FileManager.default.copyItem(at: url, to: dest)
        reload()
    }

    func remove(_ name: String) {
        let target = dir.appendingPathComponent(name)
        try? FileManager.default.removeItem(at: target)
        reload()
    }

    func urls() -> [URL] {
        files.map { dir.appendingPathComponent($0) }
    }
}
