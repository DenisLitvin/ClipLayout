//
//  TwitterView.swift
//  DemoClipLayout
//
//  Created by Denis Litvin on 04.08.2018.
//  Copyright © 2018 Denis Litvin. All rights reserved.
//

import UIKit
import ClipLayout

struct TwitterData {
    let avatar: UIImage
    let title: String
    let name: String
    let text: String
    let date: String
    var image: UIImage
    let retweet: Bool
}

class TwitterCell: ClipCell, DataBinder {
    
    var avatarView: UIImageView!
    var textLabel: UILabel!
    var titleLabel: UILabel!
    var nameLabel: UILabel!
    var timeLabel: UILabel!
    var imageView: UIImageView!
    var disclosureButton: UIButton!
    var retweetLongView: UIImageView!
    
    var commentButton: UIButton!
    var retweetButton: UIButton!
    var likeButton: UIButton!
    var shareButton: UIButton!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = .white
        setUpViews()
        setUpLayout()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func set(data: TwitterData) {
        avatarView.image = data.avatar
        titleLabel.text = data.title
        nameLabel.text = data.name
        timeLabel.text = data.date
        textLabel.text = data.text
        imageView.image = data.image
    }
    override func draw(_ rect: CGRect) {
        let path = UIBezierPath()
        path.move(to: CGPoint(x: 0, y: 1))
        path.addLine(to: CGPoint(x: UIScreen.main.bounds.width, y: 1))
        path.lineWidth = 0.5
        UIColor(white: 0.7, alpha: 1).set()
        path.stroke()
    }
    //MARK: - PRIVATE
    private func setUpViews() {
        avatarView = {
            let view = UIImageView()
            view.clip.enable = true
            view.clip.wantsSize = CGSize(width: 40, height: 40) //wrong implicit image size
            view.contentMode = .scaleAspectFit
            view.clipsToBounds = true
            view.layer.cornerRadius = 20
            return view
        }()
        titleLabel = {
            let view = UILabel()
            view.font = UIFont.boldSystemFont(ofSize: 16)
            view.clip.enable = true
            return view
        }()
        nameLabel = {
            let view = UILabel()
            view.textColor = .gray
            view.clip.enable = true
            return view
        }()
        disclosureButton = {
            let view = UIButton()
            view.clip.enable = true
            view.clip.wantsSize = CGSize(width: 25, height: 25) //wrong implicit image size
            view.imageEdgeInsets = UIEdgeInsetsMake(3, 3, 3, 3)
            view.setImage(#imageLiteral(resourceName: "d"), for: .normal)
            view.imageView?.contentMode = .scaleAspectFit
            return view
        }()
        timeLabel = {
            let view = UILabel()
            view.clip.enable = true
            view.textColor = .gray
            return view
        }()
        textLabel = {
            let view = UILabel()
            view.clip.enable = true
            view.font = UIFont.systemFont(ofSize: 16)
            view.numberOfLines = 0
            return view
        }()
        commentButton = {
            let view = UIButton()
            view.clip.enable = true
            view.clip.wantsSize = CGSize(width: 35, height: 35) //wrong implicit image size
            view.imageEdgeInsets = UIEdgeInsetsMake(1, 1, 1, 1)
            view.setImage(#imageLiteral(resourceName: "comment"), for: .normal)
            view.imageView?.contentMode = .scaleAspectFit
            return view
        }()
        retweetButton = {
            let view = UIButton()
            view.clip.enable = true
            view.clip.wantsSize = CGSize(width: 35, height: 35) //wrong implicit image size
            view.setImage(#imageLiteral(resourceName: "retweet"), for: .normal)
            view.imageView?.contentMode = .scaleAspectFit
            return view
        }()
        shareButton = {
            let view = UIButton()
            view.clip.enable = true
            view.clip.wantsSize = CGSize(width: 35, height: 35) //wrong implicit image size
            view.imageEdgeInsets = UIEdgeInsetsMake(3, 3, 3, 3)
            view.setImage(#imageLiteral(resourceName: "share"), for: .normal)
            view.imageView?.contentMode = .scaleAspectFit
            return view
        }()
        likeButton = {
            let view = UIButton()
            view.clip.enable = true
            view.clip.wantsSize = CGSize(width: 35, height: 35) //wrong implicit image size
            view.imageEdgeInsets = UIEdgeInsetsMake(1, 1, 0, 1)
            view.setImage(#imageLiteral(resourceName: "like"), for: .normal)
            view.imageView?.contentMode = .scaleAspectFit
            return view
        }()
        imageView = {
            let view = UIImageView()
            view.clip.enable = true
            view.contentMode = .scaleAspectFill
            view.layer.cornerRadius = 15
            view.clipsToBounds = true
            return view
        }()
    }
    
    private func setUpLayout() {
        self.clip.alignment.horizontal = .stretch
        self.clip.distribution = .column
        
        //enclosing view
        let commonInsetsView = UIView()
        commonInsetsView.configureLayout { (clip) in
            clip.distribution = .row
            clip.alignment.horizontal = .stretch
            clip.insets = UIEdgeInsetsMake(10, 10, 0, 10)
        }
        addSubview(commonInsetsView)
        
        avatarView.clip.alignment.vertical = .head
        avatarView.clip.insets = UIEdgeInsetsMake(10, 5, 0, 10)
        commonInsetsView.addSubview(avatarView)
        
        //MAIN CONTENT
        let contentColumn = UIView()
        contentColumn.configureLayout { (clip) in
            clip.distribution = .column
            clip.alignment.horizontal = .stretch
        }
        commonInsetsView.addSubview(contentColumn)
        
        //title - name - time
        let topRow = UIView()
        topRow.clip.enabled().horizontallyAligned(.stretch).withDistribution(.row)
        contentColumn.addSubview(topRow)
        
        topRow.addSubview(titleLabel)
        nameLabel.clip.horizontallyAligned(.stretch).insetLeft(5)
        topRow.addSubview(nameLabel)
        topRow.addSubview(timeLabel)
        topRow.addSubview(disclosureButton)
        
        textLabel.clip.alignment.horizontal = .stretch
        contentColumn.addSubview(textLabel)
        imageView.clip.insets.top = 10
        contentColumn.addSubview(imageView)
        //controls
        let bottomRow = UIView()
        bottomRow.configureLayout { (clip) in
            clip.alignment.horizontal = .stretch
            clip.distribution = .row
            clip.wantsSize.height = 40
            clip.insets.right = 30
        }
        contentColumn.addSubview(bottomRow)
        bottomRow.addSubview(commentButton)
        bottomRow.addSubview(UIView().clip.enabled().aligned(v: .stretch, h: .stretch).tov)
        bottomRow.addSubview(retweetButton)
        bottomRow.addSubview(UIView.stretchedView())
        bottomRow.addSubview(likeButton)
        bottomRow.addSubview(UIView.stretchedView())
        bottomRow.addSubview(shareButton)
    }
    
}
class TwitterView: UIView {
    
    let collectionView: ClipCollectionView<TwitterCell>
    
    override init(frame: CGRect) {
        collectionView = {
            let view = ClipCollectionView<TwitterCell>(collectionViewLayout: UICollectionViewFlowLayout())
            let layout = view.collectionViewLayout as! UICollectionViewFlowLayout
            layout.minimumInteritemSpacing = 0
            layout.minimumLineSpacing = 0
            view.backgroundColor = .white
            return view
        }()
        collectionView.configureLayout { (clip) in
            clip.alignment.horizontal = .stretch
            clip.alignment.vertical = .stretch
        }
        super.init(frame: frame)
        addSubview(collectionView)
        collectionView.data = makeMockData()
    }
    
    private func makeMockData() -> [TwitterData] {
        var result = [TwitterData]()
        let titles = [
            "Philip Rucker",
            "StockTwits",
            "StevenSpencer",
            "GuilhermoRambo",
            "Brave New Coin"
        ]
        let names = [
            "@PhilipRucker",
            "@StockTwits",
            "@StevenSpencer",
            "@GuilhermoRambo",
            "@bravenewcoin"
        ]
        let texts = [
            "Remember the presidential commission on voter fraud? One member says it was extraordinarily opaque and it’s mission was to prove Trump’s made-up claims that 3 million to 5 million people voted illegally in 2016. It found no such evidence.",
            """
            The Run-up.
            
            The Shake-out.
            
            The Buy-back.
            
            Read about these three stages of markets, and other interesting things to learn about the stock market: mailchi.mp/stocktwits/how…
            """,
            "What are things you don't hear at a Trump rally for $1000?",
            "Would you hide the home indicator if iOS had a preference for that?",
            "Wealth 2.0 is Europe’s most senior gathering of pension fund, wealth and asset management decision makers. 28 -29 Nov 2018, London, UK.  bit.ly/2xkqZ3g"
        ]
        for i in 0 ..< 4 {
            result.append(
                TwitterData(
                    avatar: UIImage(named: "\(i)")!,
                    title: titles[i],
                    name: names[i],
                    text: texts[i],
                    date: "· 7h",
                    image: UIImage(named:"image_\(i)") ?? UIImage(),
                    retweet: i % 2 == 0
                )
            )
        }
        return result
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension UIView {
    public class func stretchedView(with subview: UIView? = nil) -> UIView {
        let view = UIView()
        view.configureLayout { (clip) in
            clip.alignment.horizontal = .stretch
            clip.alignment.vertical = .stretch
        }
        if let subview = subview {
            view.addSubview(subview)
        }
        return view
    }
}
