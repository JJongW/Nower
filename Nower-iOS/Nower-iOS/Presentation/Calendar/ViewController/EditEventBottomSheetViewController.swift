//
//  EditEventBottomSheetViewController.swift
//  Nower-iOS
//
//  Created by 신종원 on 4/16/25.
//

import UIKit
import SnapKit

final class EditEventBottomSheetViewController: UIViewController {

    var todo: TodoItem!
    var selectedDate: Date!
    var onEdit: ((TodoItem) -> Void)?
    var onDelete: ((TodoItem) -> Void)?

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 18, weight: .semibold)
        label.textColor = .black
        return label
    }()
    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = .darkGray
        return label
    }()
    private let editButton: UIButton = {
        let button = UIButton()
        button.setTitle("✏️ 수정하기", for: .normal)
        button.setTitleColor(.systemBlue, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        return button
    }()
    private let deleteButton: UIButton = {
        let button = UIButton()
        button.setTitle("🗑 삭제하기", for: .normal)
        button.setTitleColor(.red, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        applyData()
    }

    private func setupUI() {
        view.backgroundColor = .white
        view.layer.cornerRadius = 16

        view.addSubview(titleLabel)
        view.addSubview(subtitleLabel)
        view.addSubview(deleteButton)
        view.addSubview(editButton)

        editButton.addTarget(self, action: #selector(didTapEdit), for: .touchUpInside)
        deleteButton.addTarget(self, action: #selector(didTapDelete), for: .touchUpInside)

        titleLabel.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(20)
            $0.leading.trailing.equalToSuperview().inset(20)
        }

        subtitleLabel.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(4)
            $0.leading.trailing.equalToSuperview().inset(20)
        }

        editButton.snp.makeConstraints {
            $0.top.equalTo(subtitleLabel.snp.bottom).offset(30)
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.height.equalTo(44)
        }

        deleteButton.snp.makeConstraints {
            $0.top.equalTo(editButton.snp.bottom).offset(12)
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.height.equalTo(44)
        }
    }

    private func applyData() {
        titleLabel.text = todo.text
        subtitleLabel.text = todo.date
    }

    @objc private func didTapEdit() {
        dismiss(animated: true) {
            self.onEdit?(self.todo)
        }
    }

    @objc private func didTapDelete() {
        let alert = UIAlertController(title: "삭제 확인", message: "이 일정을 삭제하시겠습니까?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "삭제", style: .destructive) { _ in
            self.dismiss(animated: true) {
                self.onDelete?(self.todo)
                NotificationCenter.default.post(name: .init("TodosUpdated"), object: nil)
            }
        })
        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        present(alert, animated: true)
    }
}
