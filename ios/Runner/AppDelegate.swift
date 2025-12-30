import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var overlayView: UIView?
  private var isMinimized = false
  
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    
    // High security: Prevent screenshots and screen recording ALWAYS
    setupScreenshotProtection()
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  private func setupScreenshotProtection() {
    // Prevent screenshots by showing overlay when screenshot is detected
    NotificationCenter.default.addObserver(
      forName: UIApplication.userDidTakeScreenshotNotification,
      object: nil,
      queue: .main
    ) { [weak self] _ in
      // Screenshot detected - show overlay immediately and keep it
      self?.showProtectionOverlay()
    }
    
    // Prevent screen recording - HIGH SECURITY: Always show overlay when recording
    NotificationCenter.default.addObserver(
      forName: UIScreen.capturedDidChangeNotification,
      object: nil,
      queue: .main
    ) { [weak self] _ in
      if UIScreen.main.isCaptured {
        // Screen recording detected - show protection overlay immediately
        self?.showProtectionOverlay()
      } else {
        // Screen recording stopped - but keep overlay if minimized
        if self?.isMinimized == true {
          self?.showProtectionOverlay()
        } else {
          self?.hideProtectionOverlay()
        }
      }
    }
    
    // Check initial screen recording state
    if UIScreen.main.isCaptured {
      showProtectionOverlay()
    }
    
    // Monitor app state changes for additional protection
    NotificationCenter.default.addObserver(
      forName: UIApplication.didEnterBackgroundNotification,
      object: nil,
      queue: .main
    ) { [weak self] _ in
      self?.isMinimized = true
      // Always show overlay when minimized - HIGH SECURITY
      self?.showProtectionOverlay()
      // Also hide window content when minimized
      self?.window?.isHidden = true
    }
    
    NotificationCenter.default.addObserver(
      forName: UIApplication.willEnterForegroundNotification,
      object: nil,
      queue: .main
    ) { [weak self] _ in
      self?.isMinimized = false
      // Show window again
      self?.window?.isHidden = false
      // Keep overlay if screen recording is active
      if UIScreen.main.isCaptured {
        self?.showProtectionOverlay()
      } else {
        self?.hideProtectionOverlay()
      }
    }
  }
  
  private func showProtectionOverlay() {
    guard let window = self.window else { return }
    
    // Remove existing overlay if any
    hideProtectionOverlay()
    
    // Create overlay view - HIGH SECURITY: Solid black to hide all content
    let overlay = UIView(frame: window.bounds)
    overlay.backgroundColor = .black
    overlay.alpha = 1.0
    overlay.tag = 9999 // Tag to identify the overlay
    overlay.isUserInteractionEnabled = false // Allow touches to pass through when needed
    
    window.addSubview(overlay)
    window.bringSubviewToFront(overlay)
    self.overlayView = overlay
  }
  
  private func hideProtectionOverlay() {
    // Only hide if not minimized and not recording
    guard !isMinimized && !UIScreen.main.isCaptured else {
      return // Keep overlay if minimized or recording
    }
    overlayView?.removeFromSuperview()
    overlayView = nil
  }
  
  override func applicationWillResignActive(_ application: UIApplication) {
    // HIGH SECURITY: Always show overlay when app goes to background/minimized
    isMinimized = true
    showProtectionOverlay()
    // Hide window content completely when minimized
    window?.isHidden = true
    super.applicationWillResignActive(application)
  }
  
  override func applicationDidBecomeActive(_ application: UIApplication) {
    // Show window when app becomes active
    isMinimized = false
    window?.isHidden = false
    
    // Keep overlay if screen recording is active, otherwise hide
    if UIScreen.main.isCaptured {
      showProtectionOverlay()
    } else {
      hideProtectionOverlay()
    }
    super.applicationDidBecomeActive(application)
  }
  
  override func applicationDidEnterBackground(_ application: UIApplication) {
    // HIGH SECURITY: Ensure protection when entering background
    isMinimized = true
    showProtectionOverlay()
    window?.isHidden = true
    super.applicationDidEnterBackground(application)
  }
  
  override func applicationWillEnterForeground(_ application: UIApplication) {
    // Restore window visibility
    isMinimized = false
    window?.isHidden = false
    
    // Check if screen recording is active
    if UIScreen.main.isCaptured {
      showProtectionOverlay()
    } else {
      hideProtectionOverlay()
    }
    super.applicationWillEnterForeground(application)
  }
}
