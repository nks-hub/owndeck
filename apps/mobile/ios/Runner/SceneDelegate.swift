import Flutter
import UIKit

class SceneDelegate: FlutterSceneDelegate {
  private var cardLinks: CardLinkDelivery? { (UIApplication.shared.delegate as? AppDelegate)?.cardLinks }

  override func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
    for context in connectionOptions.urlContexts { _ = cardLinks?.receive(context.url) }
    super.scene(scene, willConnectTo: session, options: connectionOptions)
  }

  override func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
    for context in URLContexts { _ = cardLinks?.receive(context.url) }
    super.scene(scene, openURLContexts: URLContexts)
  }
}
