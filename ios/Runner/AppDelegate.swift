import UIKit
import Flutter
import flutter_local_notifications
import workmanager_apple

private let messagesSyncTaskId = "com.whitenoise.messages_sync"
private let invitesSyncTaskId = "com.whitenoise.invites_sync"
private let metadataRefreshTaskId = "com.whitenoise.metadata_refresh"

@main
@objc class AppDelegate: FlutterAppDelegate {

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {    
    FlutterLocalNotificationsPlugin.setPluginRegistrantCallback { (registry) in
        GeneratedPluginRegistrant.register(with: registry)
    }
    SwiftFlutterForegroundTaskPlugin.setPluginRegistrantCallback { registry in
      GeneratedPluginRegistrant.register(with: registry)
    }
  
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self as UNUserNotificationCenterDelegate
    }

    WorkmanagerPlugin.setPluginRegistrantCallback { registry in
      GeneratedPluginRegistrant.register(with: registry)
    }
    WorkmanagerPlugin.registerPeriodicTask(
      withIdentifier: messagesSyncTaskId,
      frequency: NSNumber(value: 15 * 60)
    )
    WorkmanagerPlugin.registerPeriodicTask(
      withIdentifier: invitesSyncTaskId,
      frequency: NSNumber(value: 15 * 60)
    )
    WorkmanagerPlugin.registerPeriodicTask(
      withIdentifier: metadataRefreshTaskId,
      frequency: NSNumber(value: 24 * 60 * 60)
    )

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}