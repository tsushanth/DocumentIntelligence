import StoreKit
import UIKit

/// Manages the app review prompt flow.
/// Shows a 2-step prompt: "Enjoying PDFGenius?" → Yes triggers SKStoreReviewRequest, No opens mailto feedback.
final class ReviewManager {
    static let shared = ReviewManager()
    private init() {}

    private enum Keys {
        static let launchCount = "reviewManager_launchCount"
        static let actionCount = "reviewManager_actionCount"
        static let lastPromptDate = "reviewManager_lastPromptDate"
    }

    private let minLaunches = 3
    private let minActions = 1
    private let cooldownDays = 90

    // MARK: - Public API

    func recordLaunch() {
        let count = UserDefaults.standard.integer(forKey: Keys.launchCount) + 1
        UserDefaults.standard.set(count, forKey: Keys.launchCount)
    }

    func recordAction() {
        let count = UserDefaults.standard.integer(forKey: Keys.actionCount) + 1
        UserDefaults.standard.set(count, forKey: Keys.actionCount)
        maybePrompt()
    }

    // MARK: - Private

    private func maybePrompt() {
        guard isEligible else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.showInitialAlert()
        }
    }

    private var isEligible: Bool {
        let launches = UserDefaults.standard.integer(forKey: Keys.launchCount)
        let actions = UserDefaults.standard.integer(forKey: Keys.actionCount)
        guard launches >= minLaunches, actions >= minActions else { return false }

        if let last = UserDefaults.standard.object(forKey: Keys.lastPromptDate) as? Date {
            let daysSince = Calendar.current.dateComponents([.day], from: last, to: Date()).day ?? 0
            guard daysSince >= cooldownDays else { return false }
        }
        return true
    }

    private func showInitialAlert() {
        guard let scene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
              let root = scene.keyWindow?.rootViewController else { return }

        let presenter = root.presentedViewController ?? root

        let alert = UIAlertController(
            title: "Enjoying PDFGenius?",
            message: "We'd love to hear what you think!",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Yes!", style: .default) { [weak self] _ in
            self?.recordPromptShown()
            Task { @MainActor [weak self] in self?.requestReview(in: scene) }
        })
        alert.addAction(UIAlertAction(title: "Not Really", style: .cancel) { [weak self] _ in
            self?.recordPromptShown()
            self?.openFeedbackEmail()
        })
        presenter.present(alert, animated: true)
    }

    @MainActor
    private func requestReview(in scene: UIWindowScene) {
        if #available(iOS 16.0, *) {
            AppStore.requestReview(in: scene)
        } else {
            SKStoreReviewController.requestReview(in: scene)
        }
    }

    private func openFeedbackEmail() {
        let subject = "PDFGenius Feedback".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "mailto:support@kreativekoala.llc?subject=\(subject)"
        guard let url = URL(string: urlString) else { return }
        UIApplication.shared.open(url)
    }

    private func recordPromptShown() {
        UserDefaults.standard.set(Date(), forKey: Keys.lastPromptDate)
    }
}
