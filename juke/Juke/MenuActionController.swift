import Foundation
import XLActionController

open class MenuCell: ActionCell {
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        initialize()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    open override func awakeFromNib() {
        super.awakeFromNib()
        initialize()
    }
    
    func initialize() {
        actionTitleLabel?.font = UIFont(name: "HelveticaNeue-Bold", size: 18)
        actionTitleLabel?.textColor = .white
        actionTitleLabel?.textAlignment = .center
        backgroundColor = .darkGray
        let backgroundView = UIView()
        backgroundView.backgroundColor = UIColor(red: 0.31, green: 0.42, blue: 0.54, alpha: 1.0)
        selectedBackgroundView = backgroundView
    }
}

open class MenuActionController: ActionController<MenuCell, String, UICollectionReusableView, Void, UICollectionReusableView, Void> {
    
    public override init(nibName nibNameOrNil: String? = nil, bundle nibBundleOrNil: Bundle? = nil) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        settings.animation.scale = nil
        settings.animation.present.duration = 0.6
        settings.animation.dismiss.duration = 0.6
        settings.animation.dismiss.offset = 30
        settings.animation.dismiss.options = .curveLinear
        
        cellSpec = .nibFile(nibName: "MenuCell", bundle: Bundle(for: MenuCell.self), height: { _  in 50 })
        
        onConfigureCellForAction = { [weak self] cell, action, indexPath in
            
            cell.setup(action.data, detail: nil, image: nil)
            let actions = self?.sectionForIndex(indexPath.section)?.actions
            let actionsCount = actions!.count
            cell.separatorView?.isHidden = indexPath.item == (self?.collectionView.numberOfItems(inSection: indexPath.section))! - 1
            cell.backgroundColor = action.style == .cancel ? UIColor(white: 0.23, alpha: 1.0) : .darkGray
            cell.alpha = action.enabled ? 1.0 : 0.5
            
            var corners = UIRectCorner()
            if indexPath.item == 0 {
                corners = [.topLeft, .topRight]
            }
            if indexPath.item == actionsCount - 1 {
                corners = corners.union([.bottomLeft, .bottomRight])
            }
            
            if corners == .allCorners {
                cell.layer.mask = nil
                cell.layer.cornerRadius = 8.0
            } else {
                let borderMask = CAShapeLayer()
                borderMask.frame = cell.bounds
                borderMask.path = UIBezierPath(roundedRect: cell.bounds, byRoundingCorners: corners, cornerRadii: CGSize(width: 8.0, height: 8.0)).cgPath
                cell.layer.mask = borderMask
            }
        }
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}
