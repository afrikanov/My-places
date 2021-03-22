//
//  StarsStackView.swift
//  MyPlacesApp
//
//  Created by  Aleksandr Afrikanov on 19.03.2021.
//

import Foundation
import UIKit

@IBDesignable class StarStackView : UIStackView {
    
    var starsCount = 5
    @IBInspectable var starSize: CGFloat = 44 {
        didSet {
            self.configureStarButtons()
        }
    }
    @IBInspectable var isEditable: Bool = false {
        didSet {
            self.configureStarButtons()
        }
    }
    var currentRating: Int = 0 {
        didSet {
            for (index, button) in self.arrangedSubviews.enumerated() {
                guard let button = button as? UIButton else { return }
                button.isSelected = index < currentRating
            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.configureStarButtons()
    }
    
    required init(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    private func configureStarButtons() {
        let bundle = Bundle(for: type(of: self))
        let emptyStar = UIImage(named: "emptyStar", in: bundle, compatibleWith: self.traitCollection)
        let highlightedStar = UIImage(named: "highlightedStar", in: bundle, compatibleWith: self.traitCollection)
        let filledStar = UIImage(named: "filledStar", in: bundle, compatibleWith: self.traitCollection)
        
        for view in self.subviews {
            view.removeFromSuperview()
        }
        
        for _ in 1 ... starsCount {
            let star = UIButton()
            star.translatesAutoresizingMaskIntoConstraints = false
            star.heightAnchor.constraint(equalToConstant: self.starSize).isActive = true
            star.widthAnchor.constraint(equalToConstant: self.starSize).isActive = true
            
            star.setImage(emptyStar, for: .normal)
            star.setImage(highlightedStar, for: .highlighted)
            star.setImage(filledStar, for: .selected)
            star.setImage(highlightedStar, for: [.highlighted, .selected])
            star.isUserInteractionEnabled = self.isEditable
            
            star.addTarget(self, action: #selector(starActionUpInside(button:)), for: .touchUpInside)
            star.addTarget(self, action: #selector(starActionDown(button:)), for: .touchDown)
            star.addTarget(self, action: #selector(starActionUpOutside(button:)), for: .touchUpOutside)
            
            self.addArrangedSubview(star)
        }
    }
    
    @objc func starActionUpOutside(button: UIButton) {
        for button in self.arrangedSubviews {
            guard let button = button as? UIButton else { return }
            button.isSelected = false
            button.isHighlighted = false
        }
        currentRating = 0
    }
    
    @objc func starActionDown(button: UIButton) {
        guard let newRating = self.arrangedSubviews.firstIndex(of: button) else {
            return
        }
        
        for button in self.arrangedSubviews {
            guard let button = button as? UIButton else { return }
            button.isSelected = false
            button.isHighlighted = false
        }
        
        for (index, button) in self.arrangedSubviews.enumerated() {
            guard let button = button as? UIButton else { return }
            button.isHighlighted = index <= newRating
        }
    }
    
    @objc func starActionUpInside(button: UIButton) {
        button.isSelected.toggle()

        guard let newRating = self.arrangedSubviews.firstIndex(of: button) else {
            return
        }

        for button in self.arrangedSubviews {
            guard let button = button as? UIButton else { return }
            button.isSelected = false
            button.isHighlighted = false
        }

        guard currentRating < newRating + 1 else {
            currentRating = 0
            return
        }

        for (index, button) in self.arrangedSubviews.enumerated() {
            guard let button = button as? UIButton else { return }
            button.isSelected = index <= newRating
        }
        currentRating = newRating + 1
    }
}
