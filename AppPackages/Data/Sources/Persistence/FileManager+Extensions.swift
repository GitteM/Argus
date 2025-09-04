import Foundation

extension FileManager {
    func createCacheDirectory(at url: URL) throws {
        try createDirectory(at: url, withIntermediateDirectories: true)
    }

    func removeItemSafely(at url: URL) {
        try? removeItem(at: url)
    }

    func clearCacheFiles(in directory: URL) throws {
        guard fileExists(atPath: directory.path) else {
            // Directory doesn't exist - nothing to clear, consider this success
            return
        }

        let cacheFiles = try contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: nil
        )
        for fileURL in cacheFiles where fileURL.pathExtension == "cache" {
            do {
                try removeItem(at: fileURL)
            } catch CocoaError.fileNoSuchFile {
                // File was already deleted, ignore this error
                continue
            }
        }
    }

    func cacheFileExists(at url: URL) -> Bool {
        fileExists(atPath: url.path)
    }
}
