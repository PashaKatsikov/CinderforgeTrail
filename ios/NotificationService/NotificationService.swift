import UserNotifications
#if canImport(FirebaseMessaging)
import FirebaseMessaging
#endif

/// Notification Service Extension. Lets iOS attach FCM rich-media images to a
/// push while the app is backgrounded or killed. When Firebase is not linked
/// (e.g. before the extension target has its dependency wired), it passes the
/// content through unchanged.
class NotificationService: UNNotificationServiceExtension {
  var contentHandler: ((UNNotificationContent) -> Void)?
  var bestAttemptContent: UNMutableNotificationContent?

  override func didReceive(
    _ request: UNNotificationRequest,
    withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void
  ) {
    self.contentHandler = contentHandler
    bestAttemptContent = request.content.mutableCopy() as? UNMutableNotificationContent
    guard let best = bestAttemptContent else {
      contentHandler(request.content)
      return
    }
    #if canImport(FirebaseMessaging)
    Messaging.serviceExtension().populateNotificationContent(
      best, withContentHandler: contentHandler)
    #else
    contentHandler(best)
    #endif
  }

  override func serviceExtensionTimeWillExpire() {
    if let handler = contentHandler, let content = bestAttemptContent {
      handler(content)
    }
  }
}
