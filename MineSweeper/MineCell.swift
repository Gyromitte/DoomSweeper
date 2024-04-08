//
//  MineCell.swift
//  MineSweeper
//
//  Created by Ricardo A Gallegos Rodríguez on 26/03/24.
//

import UIKit

class MineCell: UICollectionViewCell {
    static let identifier = "MineCell"
    @IBOutlet weak var btnCell: UIButton!
    
    @IBOutlet weak var imageCell: UIImageView!
    override func awakeFromNib() {
        super.awakeFromNib()
        
        
    }
}
