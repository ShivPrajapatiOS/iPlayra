import SwiftUI
import Combine
import Foundation
import VLCMediaLibraryKit
import VLCKit

class MediaThumbnailManager: NSObject, ObservableObject, VLCMediaThumbnailerDelegate {
//    static let shared = MediaThumbnailManager()
    
    // Cache: thumbnail पहले से बना हो तो दोबारा fetch मत करो
    private static let thumbnailCache = NSCache<NSURL, UIImage>()
    
    // Semaphore: एक साथ कितने thumbnails allow हैं (जैसे 4)
    private static let semaphore = DispatchSemaphore(value: 4)
    
    @Published var thumbnail: UIImage? = nil
    @Published var isLoading: Bool = false
    private var thumbnailer: VLCMediaThumbnailer?
    private var media: VLCMLMedia?
    private var currentMediaURL: NSURL?
    
    func loadThumbnail(for media: VLCMLMedia, atTime time: Float = 0.2) {
        isLoading = true
        self.media = media
        guard let url = media.mainFile()?.mrl else { return }
        let nsURL = url as NSURL
        self.currentMediaURL = nsURL
        
        // Cache check करें
        if let cached = Self.thumbnailCache.object(forKey: nsURL) {
            self.thumbnail = cached
            self.isLoading = false
            return
        }
        
        // एक साथ thumbnailing लिमिट के लिए semaphore wait
        DispatchQueue.global(qos: .utility).async {
            Self.semaphore.wait()
            DispatchQueue.main.async {
                // VLCMediaThumbnailer बनाएँ
                guard let vlcMedia = VLCMedia(url: url) else { return }
                self.thumbnailer = VLCMediaThumbnailer(media: vlcMedia, andDelegate: self)
                self.thumbnailer?.thumbnailHeight = 80
                self.thumbnailer?.thumbnailWidth = UIScreen.main.bounds.width * 0.375
                self.thumbnailer?.fetchThumbnail()
            }
        }
    }
    
    func cancelAndClear() {
        thumbnailer?.delegate = nil
        thumbnailer = nil
        thumbnail = nil
        isLoading = false
        // Semaphore को release करें ताकि blocking ना हो
        Self.semaphore.signal()
    }
    
    // MARK: - Delegate
    func mediaThumbnailer(_ mediaThumbnailer: VLCMediaThumbnailer, didFinishThumbnail thumbnail: CGImage) {
        DispatchQueue.main.async {
            let img = UIImage(cgImage: thumbnail)
            self.thumbnail = img
            self.isLoading = false
            // Cache में डालें
            if let url = self.currentMediaURL {
                Self.thumbnailCache.setObject(img, forKey: url)
            }
            // Semaphore release
            Self.semaphore.signal()
        }
    }
    
    func mediaThumbnailerDidTimeOut(_ mediaThumbnailer: VLCMediaThumbnailer) {
        print("Thumbnail timeout")
        DispatchQueue.main.async {
            self.isLoading = false
            self.thumbnail = nil
            // Semaphore release
            Self.semaphore.signal()
        }
    }
}


class MediaThumbnailerCache: NSObject, ObservableObject, VLCMediaThumbnailerDelegate {
    
    func getVideoThumbnail(_ videoURL: NSString) {
        if getThumbnailURL(videoURL) != nil { return }
        
        guard let media = VLCMedia(url: URL(fileURLWithPath: videoURL.removingPercentEncoding!)) else { return }
        
        let thumbnailer = VLCMediaThumbnailer(media: media, andDelegate: self)
        let thumbSize = CGSize(width: 800, height: 600)
        thumbnailer.thumbnailWidth = thumbSize.width
        thumbnailer.thumbnailHeight = thumbSize.height
        
        thumbnailer.fetchThumbnail()
    }
    
    // MARK: - VLCMediaThumbnailer data source
    func mediaThumbnailer(_ mediaThumbnailer: VLCMediaThumbnailer, didFinishThumbnail thumbnail: CGImage) {
        let thumbnailImage: UIImage? = UIImage.init(cgImage: thumbnail)
        if thumbnailImage != nil {
            guard let mediaURL = mediaThumbnailer.media.url else {
                return
            }
            saveThumbnail(thumbnailImage!, mediaURL: mediaURL)
            NotificationCenter.default.post(name: Notification.Name("thumbnailIComplete"), object: nil)
        }
    }

    func mediaThumbnailerDidTimeOut(_ mediaThumbnailer: VLCMediaThumbnailer) {
        print("Time out : \(String(describing: mediaThumbnailer.media.url))")
    }
    
    // MARK: -
    private func getThumbnailDirectory() -> NSString {
        let paths = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)[0] as NSString
        let thumbnailDirectory = paths.appendingPathComponent("thumbnail")
        return thumbnailDirectory.removingPercentEncoding! as NSString
    }
    
    func getThumbnailURL(_ mediaPath: NSString) -> URL? {
        let thumbnailDir = getThumbnailDirectory()
        let thumbnailPath = String(format: "%@/%@.%@", thumbnailDir, (mediaPath.lastPathComponent as NSString).deletingPathExtension.removingPercentEncoding!, "png")

        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: thumbnailPath) {
            return URL.init(fileURLWithPath: thumbnailPath)
        }
        return nil
    }
    
    func removeThumbnail(_ mediaPath: NSString? = nil) {
        var thumbnailPath = getThumbnailDirectory()
        
        if mediaPath != nil {
            thumbnailPath = NSString(format: "%@/%@.%@", thumbnailPath, (mediaPath!.lastPathComponent as NSString ).deletingPathExtension.removingPercentEncoding!, "png")
        }
        
        let fileManager = FileManager.default
        var isDir = ObjCBool(false)
        if fileManager.fileExists(atPath: thumbnailPath as String, isDirectory: &isDir) {
            do {
                try fileManager.removeItem(atPath: thumbnailPath as String)
                //print("removed : \(String(describing: thumbnailPath))")
            }
            catch let error as NSError {
                print("error remove : \(error)")
            }
        }
    }
    
    func saveThumbnail(_ thumbnail: UIImage, mediaURL: URL) {
        let imageData = thumbnail.pngData()
        
        let pngSize: Int = imageData?.count ?? 0
        if pngSize > getFreeDiskSpace() ?? 0 {
            return
        }

        let thumbnailDir = getThumbnailDirectory()
        let thumbnailPath = NSString(format: "%@/%@.%@", thumbnailDir, ((mediaURL.relativePath.removingPercentEncoding! as NSString).lastPathComponent as NSString).deletingPathExtension, "png")

        let fileManager = FileManager.default
        if !fileManager.fileExists(atPath: thumbnailDir as String) {
            do {
                try fileManager.createDirectory(atPath: thumbnailDir as String, withIntermediateDirectories: true, attributes: nil)
            }
            catch let error as NSError {
                print("error creating directory: \(error)")
            }
        }
        if !fileManager.fileExists(atPath: thumbnailPath as String) {
            do {
                try imageData?.write(to: URL(fileURLWithPath: thumbnailPath.standardizingPath, relativeTo: nil))
            } catch let error as NSError {
                print("error writing thumbnail : \(error)")
            }
        }
    }
    
    func getFreeDiskSpace() -> Int? {
        let fileURL = URL(fileURLWithPath:"/")
        do {
            let values = try fileURL.resourceValues(forKeys: [.volumeAvailableCapacityKey])
            if let capacity = values.volumeAvailableCapacity {
                //print("Available capacity for important usage: \(capacity)")
                return capacity
            } else {
                print("Capacity is unavailable")
            }
        } catch {
            print("Error retrieving capacity")
        }
        return nil
    }
}
