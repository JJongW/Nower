//
//  SchedulePanelView.swift
//  Nower-iOS
//
//  하단 인라인 일정 패널의 크롬(grabber + 둥근 상단 + 그림자)을 담고,
//  내부에 기존 EventListView 콘텐츠를 임베드한다. (모달 시트 대체)
//

import UIKit
import SnapKit

final class SchedulePanelView: UIView {

    /// 끌어올리기 손잡이
    let grabber: UIView = {
        let view = UIView()
        view.backgroundColor = AppColors.textFieldPlaceholder.withAlphaComponent(0.4)
        view.layer.cornerRadius = 2.5
        return view
    }()

    /// 기존 일정 리스트 콘텐츠 재사용 (날짜 헤더 + 테이블 + 플로팅 "+" + 빈 상태)
    let listView = EventListView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = AppColors.popupBackground
        layer.cornerRadius = 20
        layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        layer.masksToBounds = true // 그림자 없이 둥근 상단만

        addSubview(grabber)
        addSubview(listView)

        // 내부 콘텐츠 배경을 패널 배경에 맞춤 (EventListView 기본은 background 토큰)
        listView.backgroundColor = .clear
        listView.eventTableView.backgroundColor = .clear

        grabber.snp.makeConstraints {
            $0.top.equalToSuperview().offset(8)
            $0.centerX.equalToSuperview()
            $0.width.equalTo(36)
            $0.height.equalTo(5)
        }
        grabber.isAccessibilityElement = true
        grabber.accessibilityTraits = .adjustable
        grabber.accessibilityLabel = "일정 패널"
        grabber.accessibilityHint = "위로 끌어 캘린더를 접고, 아래로 끌어 펼칩니다"

        listView.snp.makeConstraints {
            $0.top.equalTo(grabber.snp.bottom).offset(8)
            $0.leading.trailing.bottom.equalToSuperview()
        }
    }
}
