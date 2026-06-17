//
//  DepartureSettingsViewController.swift
//  Nower-iOS
//
//  출발 알림 설정 화면.
//  - 집/회사 위치 저장(지도 검색)
//  - 준비 버퍼·안전 여유 분 조정
//  - 출근 의존규칙(회사 일정은 집에서 출발) 토글
//  데이터는 SavedPlacesManager(iCloud)로 저장된다.
//

import UIKit
import SnapKit

final class DepartureSettingsViewController: UIViewController {

    private let manager = SavedPlacesManager.shared
    private var settings: DepartureSettings = .initial

    // MARK: - Sections

    private enum Section: Int, CaseIterable {
        case places
        case timing
    }

    private enum TimingRow: Int, CaseIterable {
        case buffer
        case safety
        case commuteOrigin
    }

    // MARK: - UI

    private let tableView = UITableView(frame: .zero, style: .insetGrouped)

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "출발 알림"
        view.backgroundColor = AppColors.background

        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .close,
            target: self,
            action: #selector(didTapClose)
        )

        settings = manager.currentSettings()

        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "value")
        view.addSubview(tableView)
        tableView.snp.makeConstraints { $0.edges.equalToSuperview() }

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(reloadFromStore),
            name: SavedPlacesManager.didUpdateNotification,
            object: nil
        )
    }

    deinit { NotificationCenter.default.removeObserver(self) }

    @objc private func didTapClose() {
        dismiss(animated: true)
    }

    @objc private func reloadFromStore() {
        settings = manager.currentSettings()
        tableView.reloadData()
    }

    // MARK: - Place rows

    private func fixedPlace(at row: Int) -> SavedPlace {
        let kind: PlaceKind = (row == 0) ? .home : .work
        return settings.fixedPlace(kind) ?? .emptyFixed(kind)
    }

    private func openSearch(for kind: PlaceKind) {
        let title = kind.fixedName ?? "장소"
        let searchVC = PlaceSearchViewController(placeTitle: title)
        searchVC.onPick = { [weak self] lat, lng, address in
            self?.manager.updateFixedCoordinate(kind, latitude: lat, longitude: lng, address: address)
            self?.settings = self?.manager.currentSettings() ?? .initial
            self?.tableView.reloadData()
        }
        navigationController?.pushViewController(searchVC, animated: true)
    }

    private func handlePlaceTap(_ kind: PlaceKind) {
        let place = settings.fixedPlace(kind) ?? .emptyFixed(kind)
        guard place.hasCoordinate else {
            openSearch(for: kind)
            return
        }
        let sheet = UIAlertController(title: place.name, message: place.address, preferredStyle: .actionSheet)
        sheet.addAction(UIAlertAction(title: "위치 변경", style: .default) { [weak self] _ in
            self?.openSearch(for: kind)
        })
        sheet.addAction(UIAlertAction(title: "위치 삭제", style: .destructive) { [weak self] _ in
            self?.manager.clearFixedCoordinate(kind)
            self?.settings = self?.manager.currentSettings() ?? .initial
            self?.tableView.reloadData()
        })
        sheet.addAction(UIAlertAction(title: "취소", style: .cancel))
        present(sheet, animated: true)
    }

    // MARK: - Timing rows

    @objc private func bufferChanged(_ stepper: UIStepper) {
        manager.setDefaultBuffer(minutes: Int(stepper.value))
        settings.defaultBufferMinutes = Int(stepper.value)
        reloadTimingValueLabels()
    }

    @objc private func safetyChanged(_ stepper: UIStepper) {
        manager.setSafetyMargin(minutes: Int(stepper.value))
        settings.safetyMarginMinutes = Int(stepper.value)
        reloadTimingValueLabels()
    }

    @objc private func commuteOriginToggled(_ toggle: UISwitch) {
        manager.setCommuteOriginIsHome(toggle.isOn)
        settings.commuteOriginIsHome = toggle.isOn
    }

    private func reloadTimingValueLabels() {
        tableView.reloadSections(IndexSet(integer: Section.timing.rawValue), with: .none)
    }
}

// MARK: - UITableViewDataSource / Delegate

extension DepartureSettingsViewController: UITableViewDataSource, UITableViewDelegate {

    func numberOfSections(in tableView: UITableView) -> Int { Section.allCases.count }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch Section(rawValue: section) {
        case .places: return 2 // 집, 회사
        case .timing: return TimingRow.allCases.count
        case .none: return 0
        }
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch Section(rawValue: section) {
        case .places: return "저장 장소"
        case .timing: return "출발 알림 설정"
        case .none: return nil
        }
    }

    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        switch Section(rawValue: section) {
        case .places:
            return "집·회사 위치를 넣으면 ‘회사 미팅’ 같은 일정에 맞춰 출발 시각을 알려드려요."
        case .timing:
            return "출발 알림 = 약속시간 − 이동시간 − 준비 버퍼 − 안전 여유"
        case .none: return nil
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch Section(rawValue: indexPath.section) {
        case .places:
            let cell = UITableViewCell(style: .value1, reuseIdentifier: nil)
            let place = fixedPlace(at: indexPath.row)
            var config = cell.defaultContentConfiguration()
            config.text = place.kind.fixedName ?? place.name
            config.secondaryText = place.hasCoordinate ? (place.address ?? "위치 설정됨") : "위치 미설정"
            config.textProperties.color = AppColors.textPrimary
            config.secondaryTextProperties.color = place.hasCoordinate
                ? AppColors.coralred
                : AppColors.textFieldPlaceholder
            cell.contentConfiguration = config
            cell.accessoryType = .disclosureIndicator
            return cell

        case .timing:
            return timingCell(for: indexPath.row)

        case .none:
            return UITableViewCell()
        }
    }

    private func timingCell(for row: Int) -> UITableViewCell {
        let cell = UITableViewCell(style: .value1, reuseIdentifier: nil)
        cell.selectionStyle = .none
        var config = cell.defaultContentConfiguration()
        config.textProperties.color = AppColors.textPrimary

        switch TimingRow(rawValue: row) {
        case .buffer:
            config.text = "준비 버퍼"
            config.secondaryText = "\(settings.defaultBufferMinutes)분"
            cell.contentConfiguration = config
            let stepper = UIStepper()
            stepper.minimumValue = 0
            stepper.maximumValue = 120
            stepper.stepValue = 5
            stepper.value = Double(settings.defaultBufferMinutes)
            stepper.addTarget(self, action: #selector(bufferChanged(_:)), for: .valueChanged)
            cell.accessoryView = stepper

        case .safety:
            config.text = "안전 여유"
            config.secondaryText = "\(settings.safetyMarginMinutes)분"
            cell.contentConfiguration = config
            let stepper = UIStepper()
            stepper.minimumValue = 0
            stepper.maximumValue = 30
            stepper.stepValue = 5
            stepper.value = Double(settings.safetyMarginMinutes)
            stepper.addTarget(self, action: #selector(safetyChanged(_:)), for: .valueChanged)
            cell.accessoryView = stepper

        case .commuteOrigin:
            config.text = "출근 일정은 집에서 출발"
            cell.contentConfiguration = config
            let toggle = UISwitch()
            toggle.isOn = settings.commuteOriginIsHome
            toggle.onTintColor = AppColors.coralred
            toggle.addTarget(self, action: #selector(commuteOriginToggled(_:)), for: .valueChanged)
            cell.accessoryView = toggle

        case .none:
            break
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard Section(rawValue: indexPath.section) == .places else { return }
        handlePlaceTap(indexPath.row == 0 ? .home : .work)
    }
}
