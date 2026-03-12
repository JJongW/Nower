//
//  TemplateManagementViewController.swift
//  Nower-iOS
//
//  이벤트 템플릿 관리 화면 — 목록 조회 및 삭제
//

import UIKit
import SnapKit

#if canImport(NowerCore)
import NowerCore

final class TemplateManagementViewController: UIViewController {

    // MARK: - Properties

    private var templates: [EventTemplate] = []

    // MARK: - UI

    private let tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .insetGrouped)
        tv.register(UITableViewCell.self, forCellReuseIdentifier: "TemplateCell")
        return tv
    }()

    private let emptyLabel: UILabel = {
        let l = UILabel()
        l.text = "저장된 템플릿이 없습니다.\n일정 추가 화면에서 '템플릿 저장'을 탭해 추가하세요."
        l.numberOfLines = 0
        l.textAlignment = .center
        l.font = .systemFont(ofSize: 14)
        l.textColor = .secondaryLabel
        l.isHidden = true
        return l
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "이벤트 템플릿"
        view.backgroundColor = .systemGroupedBackground
        navigationItem.rightBarButtonItem = editButtonItem

        view.addSubview(tableView)
        view.addSubview(emptyLabel)

        tableView.snp.makeConstraints { $0.edges.equalToSuperview() }
        emptyLabel.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.leading.trailing.equalToSuperview().inset(32)
        }

        tableView.dataSource = self
        tableView.delegate = self
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadTemplates()
    }

    // MARK: - Data

    private func loadTemplates() {
        if case .success(let all) = DependencyContainer.shared.fetchTemplatesUseCase.executeAll() {
            templates = all
        }
        tableView.reloadData()
        emptyLabel.isHidden = !templates.isEmpty
        tableView.isHidden = templates.isEmpty
    }
}

// MARK: - UITableViewDataSource

extension TemplateManagementViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        templates.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TemplateCell", for: indexPath)
        let template = templates[indexPath.row]

        var content = cell.defaultContentConfiguration()
        content.text = template.name
        if template.name != template.title {
            content.secondaryText = template.title
        }
        if let rule = template.recurrenceRule {
            let recurrence = rule.displayString
            content.secondaryText = (content.secondaryText.map { $0 + " · " } ?? "") + recurrence
        }

        // 색상 도트
        let dot = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 12))
        dot.backgroundColor = AppColors.color(for: template.colorName)
        dot.layer.cornerRadius = 6
        cell.accessoryView = nil
        cell.imageView?.image = nil

        let dotImageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 12, height: 12))
        dotImageView.layer.cornerRadius = 6
        dotImageView.backgroundColor = AppColors.color(for: template.colorName)
        content.image = UIImage()

        cell.contentConfiguration = content
        return cell
    }

    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool { true }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let template = templates[indexPath.row]
            _ = DependencyContainer.shared.deleteTemplateUseCase.execute(template)
            templates.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .automatic)
            emptyLabel.isHidden = !templates.isEmpty
            tableView.isHidden = templates.isEmpty
        }
    }
}

// MARK: - UITableViewDelegate

extension TemplateManagementViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        "저장된 템플릿"
    }
}

#endif
