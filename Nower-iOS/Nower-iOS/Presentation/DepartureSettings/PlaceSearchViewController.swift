//
//  PlaceSearchViewController.swift
//  Nower-iOS
//
//  저장 장소(집/회사)의 좌표를 지도 검색으로 고르는 화면.
//  MKLocalSearchCompleter로 자동완성, 선택 시 MKLocalSearch로 좌표를 확정한다.
//  위치 권한이 필요 없다(검색 기반).
//

import UIKit
import MapKit
import SnapKit

final class PlaceSearchViewController: UIViewController {

    /// 선택 완료 콜백: 좌표 + 사람이 읽는 주소.
    var onPick: ((_ latitude: Double, _ longitude: Double, _ address: String) -> Void)?

    private let placeTitle: String

    private let completer = MKLocalSearchCompleter()
    private var results: [MKLocalSearchCompletion] = []

    init(placeTitle: String) {
        self.placeTitle = placeTitle
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    // MARK: - UI

    private let searchBar: UISearchBar = {
        let bar = UISearchBar()
        bar.placeholder = "장소·주소 검색"
        bar.searchBarStyle = .minimal
        bar.autocapitalizationType = .none
        return bar
    }()

    private let tableView: UITableView = {
        let table = UITableView(frame: .zero, style: .plain)
        table.keyboardDismissMode = .onDrag
        table.register(UITableViewCell.self, forCellReuseIdentifier: "place")
        return table
    }()

    private let emptyLabel: UILabel = {
        let label = UILabel()
        label.text = "검색어를 입력하면 장소가 나와요."
        label.font = .systemFont(ofSize: 15, weight: .regular)
        label.textColor = AppColors.textFieldPlaceholder
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "\(placeTitle) 위치"
        view.backgroundColor = AppColors.background

        completer.delegate = self
        completer.resultTypes = [.address, .pointOfInterest]

        searchBar.delegate = self
        tableView.delegate = self
        tableView.dataSource = self

        view.addSubview(searchBar)
        view.addSubview(tableView)
        view.addSubview(emptyLabel)

        searchBar.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            $0.leading.trailing.equalToSuperview()
        }
        tableView.snp.makeConstraints {
            $0.top.equalTo(searchBar.snp.bottom)
            $0.leading.trailing.bottom.equalToSuperview()
        }
        emptyLabel.snp.makeConstraints {
            $0.center.equalTo(tableView)
            $0.leading.trailing.equalToSuperview().inset(32)
        }

        DispatchQueue.main.async { [weak self] in
            self?.searchBar.becomeFirstResponder()
        }
    }

    private func updateEmptyState() {
        emptyLabel.isHidden = !results.isEmpty
        emptyLabel.text = (searchBar.text ?? "").isEmpty
            ? "검색어를 입력하면 장소가 나와요."
            : "검색 결과가 없어요."
    }
}

// MARK: - UISearchBarDelegate

extension PlaceSearchViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            results = []
            tableView.reloadData()
            updateEmptyState()
            return
        }
        completer.queryFragment = trimmed
    }
}

// MARK: - MKLocalSearchCompleterDelegate

extension PlaceSearchViewController: MKLocalSearchCompleterDelegate {
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        results = completer.results
        tableView.reloadData()
        updateEmptyState()
    }

    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        results = []
        tableView.reloadData()
        updateEmptyState()
    }
}

// MARK: - UITableViewDataSource / Delegate

extension PlaceSearchViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        results.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "place", for: indexPath)
        let completion = results[indexPath.row]
        var config = cell.defaultContentConfiguration()
        config.text = completion.title
        config.secondaryText = completion.subtitle
        config.textProperties.color = AppColors.textPrimary
        cell.contentConfiguration = config
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let completion = results[indexPath.row]
        let request = MKLocalSearch.Request(completion: completion)
        let search = MKLocalSearch(request: request)
        search.start { [weak self] response, _ in
            guard let self = self,
                  let item = response?.mapItems.first else { return }
            let coord = item.placemark.coordinate
            let address = [completion.title, completion.subtitle]
                .filter { !$0.isEmpty }
                .joined(separator: ", ")
            DispatchQueue.main.async {
                self.onPick?(coord.latitude, coord.longitude, address)
                self.navigationController?.popViewController(animated: true)
            }
        }
    }
}
