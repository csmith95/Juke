//
//  FeaturedRow.swift
//  Juke
//
//  Created by Kojo Worai Osei on 3/21/18.
//  Copyright © 2018 csmith. All rights reserved.
//

import Foundation

class FeaturedRow: UITableViewCell {
    
    @IBOutlet weak var collectionView: UICollectionView!
    var featuredStreams: [Models.FirebaseStream]? = nil {
        didSet {
            collectionView.reloadData()
        }
    }
}

extension FeaturedRow: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return (featuredStreams?.count)!
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "featuredCell", for: indexPath) as! FeaturedCell
        if let featuredStreams = featuredStreams {
            cell.populateCell(stream: featuredStreams[indexPath.row])
        }
        return cell
    }
}

extension FeaturedRow: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 150, height: 200)
    }
}
