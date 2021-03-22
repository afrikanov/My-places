//
//  CustomTableViewCell.swift
//  MyPlacesApp
//
//  Created by  Aleksandr Afrikanov on 04.03.2021.
//

import UIKit

class CustomTableViewCell: UITableViewCell {
    
    @IBOutlet weak var placeImage: UIImageView!
    @IBOutlet weak var placeName: UILabel!
    @IBOutlet weak var placeLocation: UILabel!
    @IBOutlet weak var placeType: UILabel!
    @IBOutlet weak var starStackView: StarStackView!

}
