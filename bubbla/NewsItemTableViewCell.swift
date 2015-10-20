//
//  NewsItemTableViewCell.swift
//  bubbla
//
//  Created by Sami Purmonen on 20/10/15.
//  Copyright © 2015 Sami Purmonen. All rights reserved.
//

import UIKit

class NewsItemTableViewCell: UITableViewCell {

    @IBOutlet weak var titleLabel: UILabel!
    
    @IBOutlet weak var publicationDateLabel: UILabel!
    
    @IBOutlet weak var urlLabel: UILabel!
    @IBOutlet weak var categoryLabel: UILabel!
    
    @IBOutlet weak var unreadIndicator: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
