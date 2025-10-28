import UIKit

final class PushPermissionViewController: UIViewController {
    private let onAllow: () -> Void
    private let onLater: () -> Void

    init(onAllow: @escaping () -> Void, onLater: @escaping () -> Void) {
        self.onAllow = onAllow
        self.onLater = onLater
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .formSheet
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        let title = UILabel()
        title.text = "Stay in the loop"
        title.font = .systemFont(ofSize: 22, weight: .bold)

        let subtitle = UILabel()
        subtitle.text = "Enable notifications for updates and offers."
        subtitle.numberOfLines = 0
        subtitle.textAlignment = .center

        let allow = UIButton(type: .system)
        allow.setTitle("Allow", for: .normal)
        allow.addTarget(self, action: #selector(tapAllow), for: .touchUpInside)

        let later = UIButton(type: .system)
        later.setTitle("Later", for: .normal)
        later.addTarget(self, action: #selector(tapLater), for: .touchUpInside)

        for v in [title, subtitle, allow, later] { v.translatesAutoresizingMaskIntoConstraints = false; view.addSubview(v) }

        NSLayoutConstraint.activate([
            title.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24),
            title.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            subtitle.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 12),
            subtitle.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            subtitle.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),

            allow.topAnchor.constraint(equalTo: subtitle.bottomAnchor, constant: 24),
            allow.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            later.topAnchor.constraint(equalTo: allow.bottomAnchor, constant: 8),
            later.centerXAnchor.constraint(equalTo: view.centerXAnchor),
        ])
    }

    @objc private func tapAllow() {
        dismiss(animated: true)
        onAllow()
    }
    @objc private func tapLater() {
        dismiss(animated: true)
        onLater()
    }
}
