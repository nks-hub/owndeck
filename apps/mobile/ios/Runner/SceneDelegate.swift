import Flutter
import UIKit

class SceneDelegate: FlutterSceneDelegate {
  private var appDelegate: AppDelegate? { UIApplication.shared.delegate as? AppDelegate }

  /// Share URLs go to sharing; only `ncdeck://open` links are card links.
  private func route(_ url: URL) {
    if appDelegate?.shares.receive(url) == true { return }
    _ = appDelegate?.cardLinks.receive(url)
  }

  override func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
    for context in connectionOptions.urlContexts { route(context.url) }
    super.scene(scene, willConnectTo: session, options: connectionOptions)
  }

  override func sceneDidBecomeActive(_ scene: UIScene) {
    super.sceneDidBecomeActive(scene)
    appDelegate?.shares.drain()
  }

  override func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
    for context in URLContexts { route(context.url) }
    super.scene(scene, openURLContexts: URLContexts)
  }
}
