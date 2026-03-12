//
//  TemplateAutocompleteView.swift
//  Nower-iOS
//
//  이벤트 템플릿 자동완성 드롭다운 뷰 (iOS / UIKit)
//

import UIKit
import SnapKit

#if canImport(NowerCore)
import NowerCore

/// 이벤트 템플릿 자동완성 드롭다운 — 최대 5개 행, 각 44pt 높이
final class TemplateAutocompleteView: UIView {

    // MARK: - Properties

    var suggestions: [EventTemplate] = [] {
        didSet { tableView.reloadData() }
    }
    var onSelect: ((EventTemplate) -> Void)?

    // MARK: - UI

    private let tableView: UITableView = {
        let tv = UITableView()
        tv.backgroundColor = .clear
        tv.separatorStyle = .none
        tv.isScrollEnabled = false
        tv.register(TemplateAutocompleteCell.self, forCellReuseIdentifier: TemplateAutocompleteCell.reuseId)
        return tv
    }()

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        backgroundColor = AppColors.popupBackground
        layer.cornerRadius = 8
        layer.masksToBounds = true

        // 그림자는 masksToBounds가 false일 때만 동작하므로 컨테이너에 추가
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.12
        layer.shadowOffset = CGSize(width: 0, height: 4)
        layer.shadowRadius = 8
        layer.masksToBounds = false

        addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        tableView.dataSource = self
        tableView.delegate = self
    }

    // MARK: - Height

    static let rowHeight: CGFloat = 44

    var preferredHeight: CGFloat {
        CGFloat(min(suggestions.count, 5)) * Self.rowHeight
    }
}

// MARK: - UITableViewDataSource

extension TemplateAutocompleteView: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        min(suggestions.count, 5)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: TemplateAutocompleteCell.reuseId, for: indexPath) as! TemplateAutocompleteCell
        cell.configure(with: suggestions[indexPath.row])
        return cell
    }
}

// MARK: - UITableViewDelegate

extension TemplateAutocompleteView: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        Self.rowHeight
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        onSelect?(suggestions[indexPath.row])
    }
}

// MARK: - Cell

private final class TemplateAutocompleteCell: UITableViewCell {
    static let reuseId = "TemplateAutocompleteCell"

    private let colorDot: UIView = {
        let v = UIView()
        v.layer.cornerRadius = 5
        v.clipsToBounds = true
        return v
    }()

    private let nameLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 14)
        l.textColor = AppColors.textPrimary
        return l
    }()

    private let recurrenceLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 12)
        l.textColor = AppColors.textFieldPlaceholder
        return l
    }()

    private let separatorLine: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor.separator
        return v
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        selectionStyle = .default

        let selectedBg = UIView()
        selectedBg.backgroundColor = AppColors.textFieldBackground
        selectedBackgroundView = selectedBg

        [colorDot, nameLabel, recurrenceLabel, separatorLine].forEach { contentView.addSubview($0) }

        colorDot.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(14)
            make.centerY.equalToSuperview()
            make.size.equalTo(CGSize(width: 10, height: 10))
        }
        nameLabel.snp.makeConstraints { make in
            make.leading.equalTo(colorDot.snp.trailing).offset(8)
            make.centerY.equalToSuperview()
        }
        recurrenceLabel.snp.makeConstraints { make in
            make.leading.equalTo(nameLabel.snp.trailing).offset(8)
            make.centerY.equalToSuperview()
            make.trailing.lessThanOrEqualToSuperview().offset(-14)
        }
        separatorLine.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(14)
            make.trailing.equalToSuperview()
            make.bottom.equalToSuperview()
            make.height.equalTo(0.5)
        }
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(with template: EventTemplate) {
        colorDot.backgroundColor = AppColors.color(for: template.colorName)
        nameLabel.text = template.name
        if let rule = template.recurrenceRule {
            recurrenceLabel.text = rule.displayString
            recurrenceLabel.isHidden = false
        } else {
            recurrenceLabel.isHidden = true
        }
    }
}

#endif
