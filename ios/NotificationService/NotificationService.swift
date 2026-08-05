import UserNotifications

/// Rich-media push handler. FCM delivers the image URL in `fcm_options.image`
/// (and sets `mutable-content: 1` so this extension runs). We download it and
/// attach it so the notification shows the picture. No Firebase dependency is
/// linked into the extension — the project is SPM-based and a manual download
/// produces the same result without adding the SDK to this target.
class NotificationService: UNNotificationServiceExtension {
  private var contentHandler: ((UNNotificationContent) -> Void)?
  private var bestAttempt: UNMutableNotificationContent?

  override func didReceive(
    _ request: UNNotificationRequest,
    withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void
  ) {
    self.contentHandler = contentHandler
    bestAttempt = request.content.mutableCopy() as? UNMutableNotificationContent

    guard let best = bestAttempt else {
      contentHandler(request.content)
      return
    }

    guard let imageURL = Self.imageURL(from: request.content.userInfo) else {
      contentHandler(best)
      return
    }

    Self.download(imageURL) { attachment in
      if let attachment = attachment {
        best.attachments = [attachment]
      }
      contentHandler(best)
    }
  }

  override func serviceExtensionTimeWillExpire() {
    if let handler = contentHandler, let best = bestAttempt {
      handler(best)
    }
  }

  private static func imageURL(from info: [AnyHashable: Any]) -> URL? {
    if let fcm = info["fcm_options"] as? [AnyHashable: Any],
       let raw = fcm["image"] as? String,
       let url = URL(string: raw) {
      return url
    }
    for key in ["image", "image_url", "imageUrl", "media-url", "media_url"] {
      if let raw = info[key] as? String, let url = URL(string: raw) {
        return url
      }
    }
    return nil
  }

  private static func download(
    _ url: URL,
    completion: @escaping (UNNotificationAttachment?) -> Void
  ) {
    let task = URLSession.shared.downloadTask(with: url) { location, response, _ in
      guard let location = location else {
        completion(nil)
        return
      }
      let ext = Self.fileExtension(for: response, fallbackURL: url)
      let tmp = URL(fileURLWithPath: NSTemporaryDirectory())
        .appendingPathComponent(ProcessInfo.processInfo.globallyUniqueString + ext)
      do {
        try FileManager.default.moveItem(at: location, to: tmp)
        let attachment = try UNNotificationAttachment(
          identifier: "image", url: tmp, options: nil)
        completion(attachment)
      } catch {
        completion(nil)
      }
    }
    task.resume()
  }

  private static func fileExtension(for response: URLResponse?, fallbackURL: URL) -> String {
    let pathExt = fallbackURL.pathExtension
    if !pathExt.isEmpty {
      return "." + pathExt
    }
    switch response?.mimeType {
    case "image/jpeg": return ".jpg"
    case "image/gif": return ".gif"
    case "image/png": return ".png"
    default: return ".png"
    }
  }
}
