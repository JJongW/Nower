//
//  ForceUpdateViewController.swift
//  Nower-iOS
//
//  강제 업데이트 차단 화면. 닫을 수 없으며 App Store 로만 빠져나갈 수 있다.
//  설치 버전이 최소 요구 버전 미만일 때 표시한다.
//

import UIKit
import SnapKit

final class ForceUpdateViewController: UIViewController {

    private let appStoreURL: URL

    init(appStoreURL: URL) {
        self.appStoreURL = appStoreURL
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .fullScreen
        // 시트 끌어내림 등으로 닫히지 않도록
        isModalInPresentation = true
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    // MARK: - UI

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "업데이트가 필요해요"
        label.font = .systemFont(ofSize: 22, weight: .bold)
        label.textColor = AppColors.textPrimary
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    private let messageLabel: UILabel = {
        let label = UILabel()
        label.text = "원활한 사용을 위해 최신 버전으로 업데이트해 주세요.\n업데이트 후 계속 이용할 수 있어요."
        label.font = .systemFont(ofSize: 15, weight: .regular)
        label.textColor = AppColors.textMain
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    private lazy var updateButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("지금 업데이트", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        button.setTitleColor(AppColors.contrastingTextColor(for: AppColors.buttonColor), for: .normal)
        button.backgroundColor = AppColors.buttonColor
        button.layer.cornerRadius = 14
        button.addTarget(self, action: #selector(didTapUpdate), for: .touchUpInside)
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = AppColors.background
        setupUI()
    }

    private func setupUI() {
        let textStack = UIStackView(arrangedSubviews: [titleLabel, messageLabel])
        textStack.axis = .vertical
        textStack.spacing = 12
        textStack.alignment = .center

        view.addSubview(textStack)
        view.addSubview(updateButton)

        textStack.snp.makeConstraints { make in
            make.centerY.equalToSuperview().offset(-40)
            make.leading.trailing.equalToSuperview().inset(32)
        }

        updateButton.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(24)
            make.bottom.equalTo(view.safeAreaLayoutGuide).inset(24)
            make.height.equalTo(52) // 44pt 이상 터치 타겟
        }
    }

    @objc private func didTapUpdate() {
        UIApplication.shared.open(appStoreURL)
    }
}
