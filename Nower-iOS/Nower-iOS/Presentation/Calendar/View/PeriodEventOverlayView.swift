//
//  PeriodEventOverlayView.swift
//  Nower-iOS
//
//  Created by AI Assistant on 9/25/25.
//

import UIKit
import SnapKit

/// 기간별 일정의 개별 세그먼트 정보
struct PeriodEventSegment {
    let frame: CGRect
    let isFirstSegment: Bool
    let isLastSegment: Bool
}

/// 기간별 일정을 캘린더 전체에 걸쳐 연결된 형태로 표시하는 오버레이 뷰
final class PeriodEventOverlayView: UIView {
    
    // MARK: - UI Components
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 10, weight: .medium)
        label.textColor = AppColors.textMain
        label.textAlignment = .left
        label.numberOfLines = 1
        label.lineBreakMode = .byTruncatingTail
        return label
    }()
    
    // MARK: - Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        layer.cornerRadius = 10
        layer.masksToBounds = true
        
        addSubview(titleLabel)
        titleLabel.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(8)
            $0.centerY.equalToSuperview()
            $0.trailing.lessThanOrEqualToSuperview().offset(-8)
        }
    }
    
    // MARK: - Configuration
    
    /// 기간별 일정 오버레이를 설정합니다.
    /// - Parameters:
    ///   - todo: 기간별 일정 아이템
    ///   - segments: 기간별 일정의 각 세그먼트 정보 (여러 행에 걸칠 수 있음)
    ///   - row: 해당 일정이 표시될 행 (0부터 시작, 다른 일정들과 겹치지 않도록)
    func configure(todo: TodoItem, segments: [PeriodEventSegment], row: Int) {
        print("🎨 [PeriodEventOverlayView] 오버레이 설정: \(todo.text), 세그먼트 수: \(segments.count)")
        
        // 기존 서브뷰들 제거 (titleLabel 제외)
        subviews.filter { $0 != titleLabel }.forEach { $0.removeFromSuperview() }
        
        // 전체 오버레이 뷰의 배경을 투명하게 설정
        backgroundColor = .clear
        
        // 각 세그먼트에 대해 개별 뷰 생성
        for segment in segments {
            createSegmentView(for: segment, isFirst: false, todo: todo, containerFrame: self.frame)
        }
    }
    
    /// 개별 세그먼트 뷰를 생성합니다.
    private func createSegmentView(for segment: PeriodEventSegment, isFirst: Bool, todo: TodoItem, containerFrame: CGRect) {
        let segmentView = UIView()
        segmentView.backgroundColor = AppColors.color(for: todo.colorName)
        
        // 컨테이너 프레임을 기준으로 상대적 위치 계산
        let relativeFrame = CGRect(
            x: segment.frame.minX - containerFrame.minX,
            y: segment.frame.minY - containerFrame.minY,
            width: segment.frame.width,
            height: segment.frame.height
        )
        
        segmentView.frame = relativeFrame
        
        // 연결된 형태로 표시하기 위해 cornerRadius 설정
        // 첫 번째 세그먼트: 왼쪽만 둥글게
        // 마지막 세그먼트: 오른쪽만 둥글게
        // 중간 세그먼트: 직각
        segmentView.layer.cornerRadius = 6
        segmentView.layer.masksToBounds = true
        
        if segment.isFirstSegment && segment.isLastSegment {
            // 단일 세그먼트인 경우 (한 주 안에 모두 포함)
            segmentView.layer.maskedCorners = [
                .layerMinXMinYCorner,
                .layerMinXMaxYCorner,
                .layerMaxXMinYCorner,
                .layerMaxXMaxYCorner
            ]
        } else if segment.isFirstSegment {
            // 첫 번째 세그먼트: 왼쪽만 둥글게
            segmentView.layer.maskedCorners = [
                .layerMinXMinYCorner,
                .layerMinXMaxYCorner
            ]
        } else if segment.isLastSegment {
            // 마지막 세그먼트: 오른쪽만 둥글게
            segmentView.layer.maskedCorners = [
                .layerMaxXMinYCorner,
                .layerMaxXMaxYCorner
            ]
        } else {
            // 중간 세그먼트: 직각
            segmentView.layer.cornerRadius = 0
            segmentView.layer.maskedCorners = []
        }
        
        addSubview(segmentView)
        
        // 첫 번째 세그먼트에만 제목 라벨 추가
        if segment.isFirstSegment {
            let titleLabel = UILabel()
            titleLabel.text = todo.text
            titleLabel.font = UIFont.systemFont(ofSize: 10, weight: .medium)
            titleLabel.textColor = AppColors.textMain
            titleLabel.textAlignment = .left
            titleLabel.numberOfLines = 1
            titleLabel.lineBreakMode = .byTruncatingTail
            
            segmentView.addSubview(titleLabel)
            titleLabel.snp.makeConstraints {
                $0.leading.equalToSuperview().offset(6)
                $0.centerY.equalToSuperview()
                $0.trailing.lessThanOrEqualToSuperview().offset(-6)
            }
        }
    }
}
