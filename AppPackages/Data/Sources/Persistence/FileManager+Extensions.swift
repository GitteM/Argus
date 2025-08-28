import Foundation

extension FileManager {
    func createCacheDirectory(at url: URL) throws {
        try createDirectory(at: url, withIntermediateDirectories: true)
    }

    func removeItemSafely(at url: URL) {
        try? removeItem(at: url)
    }

    func clearCacheFiles(in directory: URL) throws {
        let cacheFiles = try contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: nil
        )
        for fileURL in cacheFiles where fileURL.pathExtension == "cache" {
            try removeItem(at: fileURL)
        }
    }

    func cacheFileExists(at url: URL) -> Bool {
        fileExists(atPath: url.path)
    }
}
