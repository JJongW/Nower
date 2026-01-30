//
//  ConflictResolutionViewController.swift
//  Nower-iOS
//
//  Created for Nower Calendar App.
//  Copyright © 2025 Nower. All rights reserved.
//

import UIKit
#if canImport(NowerCore)
import NowerCore
#endif

final class ConflictResolutionViewController: UIViewController {

    // MARK: - Properties

    private let viewModel: SyncStatusViewModel
    private var conflicts: [SyncConflict]

    // MARK: - UI Components

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "일정 동기화 충돌"
        label.font = .systemFont(ofSize: 20, weight: .bold)
        label.textColor = AppColors.textPrimary
        return label
    }()

    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.text = "이 기기와 다른 기기에서 같은 일정을 수정했습니다.\n유지할 버전을 선택하세요."
        label.font = .systemFont(ofSize: 13)
        label.textColor = AppColors.textFieldPlaceholder
        label.numberOfLines = 0
        return label
    }()

    private let resolveAllButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("일괄 처리", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
        button.tintColor = .systemBlue
        return button
    }()

    private lazy var tableView: UITableView = {
        let table = UITableView(frame: .zero, style: .insetGrouped)
        table.dataSource = self
        table.delegate = self
        table.register(ConflictCell.self, forCellReuseIdentifier: ConflictCell.identifier)
        table.backgroundColor = AppColors.background
        table.rowHeight = UITableView.automaticDimension
        table.estimatedRowHeight = 200
        return table
    }()

    // MARK: - Initialization

    init(viewModel: SyncStatusViewModel) {
        self.viewModel = viewModel
        self.conflicts = viewModel.syncState.conflicts
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupActions()
    }

    // MARK: - Setup

    private func setupUI() {
        view.backgroundColor = AppColors.background

        view.addSubview(titleLabel)
        view.addSubview(descriptionLabel)
        view.addSubview(resolveAllButton)
        view.addSubview(tableView)

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        resolveAllButton.translatesAutoresizingMaskIntoConstraints = false
        tableView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),

            resolveAllButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            resolveAllButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            descriptionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 6),
            descriptionLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            descriptionLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            tableView.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 12),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    private func setupActions() {
        resolveAllButton.addTarget(self, action: #selector(didTapResolveAll), for: .touchUpInside)

        viewModel.onStateChange = { [weak self] vm in
            guard let self = self else { return }
            self.conflicts = vm.syncState.conflicts
            self.tableView.reloadData()

            if self.conflicts.isEmpty {
                self.dismiss(animated: true)
            }
        }
    }

    // MARK: - Actions

    @objc private func didTapResolveAll() {
        let alert = UIAlertController(title: "일괄 처리", message: "모든 충돌을 한 번에 처리합니다.", preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "모두 이 기기 버전 사용", style: .default) { [weak self] _ in
            self?.viewModel.resolveAllConflicts(resolution: .keepLocal)
        })
        alert.addAction(UIAlertAction(title: "모두 다른 기기 버전 사용", style: .default) { [weak self] _ in
            self?.viewModel.resolveAllConflicts(resolution: .keepRemote)
        })
        alert.addAction(UIAlertAction(title: "모두 복제하여 보관", style: .default) { [weak self] _ in
            self?.viewModel.resolveAllConflicts(resolution: .keepBoth)
        })
        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        present(alert, animated: true)
    }

    private func resolveConflict(at index: Int, resolution: ConflictResolution) {
        guard index < conflicts.count else { return }
        viewModel.resolveConflict(conflicts[index], resolution: resolution)
    }
}

// MARK: - UITableViewDataSource

extension ConflictResolutionViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        conflicts.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: ConflictCell.identifier, for: indexPath) as? ConflictCell else {
            return UITableViewCell()
        }
        let conflict = conflicts[indexPath.row]
        cell.configure(with: conflict)
        cell.onResolution = { [weak self] resolution in
            self?.resolveConflict(at: indexPath.row, resolution: resolution)
        }
        return cell
    }
}

// MARK: - UITableViewDelegate

extension ConflictResolutionViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

// MARK: - ConflictCell

private final class ConflictCell: UITableViewCell {
    static let identifier = "ConflictCell"

    var onResolution: ((ConflictResolution) -> Void)?

    // Local side
    private let localDot = UIView()
    private let localHeaderLabel: UILabel = {
        let label = UILabel()
        label.text = "이 기기"
        label.font = .systemFont(ofSize: 11, weight: .bold)
        label.textColor = .systemBlue
        return label
    }()
    private let localTitleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 13, weight: .medium)
        label.textColor = AppColors.textPrimary
        label.numberOfLines = 0
        return label
    }()
    private let localDateLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 11)
        label.textColor = AppColors.textFieldPlaceholder
        return label
    }()
    private let localColorSwatch = UIView()
    private let localColorLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 10)
        label.textColor = AppColors.textFieldPlaceholder
        return label
    }()

    // Remote side
    private let remoteDot = UIView()
    private let remoteHeaderLabel: UILabel = {
        let label = UILabel()
        label.text = "다른 기기"
        label.font = .systemFont(ofSize: 11, weight: .bold)
        label.textColor = .systemOrange
        return label
    }()
    private let remoteTitleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 13, weight: .medium)
        label.textColor = AppColors.textPrimary
        label.numberOfLines = 0
        return label
    }()
    private let remoteDateLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 11)
        label.textColor = AppColors.textFieldPlaceholder
        return label
    }()
    private let remoteColorSwatch = UIView()
    private let remoteColorLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 10)
        label.textColor = AppColors.textFieldPlaceholder
        return label
    }()

    // Divider
    private let dividerView: UIView = {
        let view = UIView()
        view.backgroundColor = AppColors.textFieldPlaceholder.withAlphaComponent(0.3)
        return view
    }()

    // Buttons
    private let keepLocalButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("이 기기 버전", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 12, weight: .semibold)
        button.tintColor = .systemBlue
        return button
    }()
    private let keepRemoteButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("다른 기기 버전", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 12, weight: .semibold)
        button.tintColor = .systemOrange
        return button
    }()
    private let keepBothButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("복제 보관", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 12, weight: .semibold)
        return button
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        selectionStyle = .none
        backgroundColor = AppColors.popupBackground

        // Configure dots
        localDot.backgroundColor = .systemBlue
        localDot.layer.cornerRadius = 4
        remoteDot.backgroundColor = .systemOrange
        remoteDot.layer.cornerRadius = 4

        // Configure color swatches
        localColorSwatch.layer.cornerRadius = 3
        remoteColorSwatch.layer.cornerRadius = 3

        // Local header row
        let localHeaderRow = UIStackView(arrangedSubviews: [localDot, localHeaderLabel])
        localHeaderRow.axis = .horizontal
        localHeaderRow.spacing = 4
        localHeaderRow.alignment = .center
        localDot.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            localDot.widthAnchor.constraint(equalToConstant: 8),
            localDot.heightAnchor.constraint(equalToConstant: 8),
        ])

        // Local color row
        let localColorRow = UIStackView(arrangedSubviews: [localColorSwatch, localColorLabel])
        localColorRow.axis = .horizontal
        localColorRow.spacing = 4
        localColorRow.alignment = .center
        localColorSwatch.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            localColorSwatch.widthAnchor.constraint(equalToConstant: 14),
            localColorSwatch.heightAnchor.constraint(equalToConstant: 14),
        ])

        let localStack = UIStackView(arrangedSubviews: [localHeaderRow, localTitleLabel, localDateLabel, localColorRow])
        localStack.axis = .vertical
        localStack.spacing = 4

        // Remote header row
        let remoteHeaderRow = UIStackView(arrangedSubviews: [remoteDot, remoteHeaderLabel])
        remoteHeaderRow.axis = .horizontal
        remoteHeaderRow.spacing = 4
        remoteHeaderRow.alignment = .center
        remoteDot.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            remoteDot.widthAnchor.constraint(equalToConstant: 8),
            remoteDot.heightAnchor.constraint(equalToConstant: 8),
        ])

        // Remote color row
        let remoteColorRow = UIStackView(arrangedSubviews: [remoteColorSwatch, remoteColorLabel])
        remoteColorRow.axis = .horizontal
        remoteColorRow.spacing = 4
        remoteColorRow.alignment = .center
        remoteColorSwatch.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            remoteColorSwatch.widthAnchor.constraint(equalToConstant: 14),
            remoteColorSwatch.heightAnchor.constraint(equalToConstant: 14),
        ])

        let remoteStack = UIStackView(arrangedSubviews: [remoteHeaderRow, remoteTitleLabel, remoteDateLabel, remoteColorRow])
        remoteStack.axis = .vertical
        remoteStack.spacing = 4

        let contentStack = UIStackView(arrangedSubviews: [localStack, dividerView, remoteStack])
        contentStack.axis = .horizontal
        contentStack.distribution = .fillEqually
        contentStack.spacing = 8
        contentStack.alignment = .top

        dividerView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            dividerView.widthAnchor.constraint(equalToConstant: 1),
        ])
        // Override fill equally for divider
        contentStack.distribution = .fill
        localStack.translatesAutoresizingMaskIntoConstraints = false
        remoteStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            localStack.widthAnchor.constraint(equalTo: remoteStack.widthAnchor),
        ])

        let buttonStack = UIStackView(arrangedSubviews: [keepLocalButton, keepRemoteButton, keepBothButton])
        buttonStack.axis = .horizontal
        buttonStack.distribution = .fillEqually
        buttonStack.spacing = 8

        let mainStack = UIStackView(arrangedSubviews: [contentStack, buttonStack])
        mainStack.axis = .vertical
        mainStack.spacing = 12

        contentView.addSubview(mainStack)
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            mainStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            mainStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),
            mainStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            mainStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
        ])

        keepLocalButton.addTarget(self, action: #selector(didTapKeepLocal), for: .touchUpInside)
        keepRemoteButton.addTarget(self, action: #selector(didTapKeepRemote), for: .touchUpInside)
        keepBothButton.addTarget(self, action: #selector(didTapKeepBoth), for: .touchUpInside)
    }

    func configure(with conflict: SyncConflict) {
        let titleDiffers = conflict.localTitle != conflict.remoteTitle
        let dateDiffers = conflict.localDate != conflict.remoteDate
        let colorDiffers = conflict.localColorName != conflict.remoteColorName

        // Local
        localTitleLabel.text = conflict.localTitle
        localTitleLabel.backgroundColor = titleDiffers ? UIColor.systemBlue.withAlphaComponent(0.1) : .clear
        localDateLabel.text = conflict.localDate
        localDateLabel.backgroundColor = dateDiffers ? UIColor.systemBlue.withAlphaComponent(0.1) : .clear
        localColorSwatch.backgroundColor = AppColors.color(for: conflict.localColorName)
        localColorSwatch.layer.borderWidth = colorDiffers ? 1.5 : 0
        localColorSwatch.layer.borderColor = UIColor.systemBlue.cgColor
        localColorLabel.text = conflict.localColorName

        // Remote
        remoteTitleLabel.text = conflict.remoteTitle
        remoteTitleLabel.backgroundColor = titleDiffers ? UIColor.systemOrange.withAlphaComponent(0.1) : .clear
        remoteDateLabel.text = conflict.remoteDate
        remoteDateLabel.backgroundColor = dateDiffers ? UIColor.systemOrange.withAlphaComponent(0.1) : .clear
        remoteColorSwatch.backgroundColor = AppColors.color(for: conflict.remoteColorName)
        remoteColorSwatch.layer.borderWidth = colorDiffers ? 1.5 : 0
        remoteColorSwatch.layer.borderColor = UIColor.systemOrange.cgColor
        remoteColorLabel.text = conflict.remoteColorName
    }

    @objc private func didTapKeepLocal() { onResolution?(.keepLocal) }
    @objc private func didTapKeepRemote() { onResolution?(.keepRemote) }
    @objc private func didTapKeepBoth() { onResolution?(.keepBoth) }
}
