//
//  ContactsTableViewController.swift
//  Juke
//
//  Created by Conner Smith on 3/28/17.
//  Copyright © 2017 csmith. All rights reserved.
//

import UIKit
import AlamofireImage
import Alamofire
import Unbox
import PKHUD
import SCLAlertView
import Firebase
import FirebaseDatabaseUI

class StreamsTableViewController: UIViewController, UICollectionViewDelegate {
    
    @IBOutlet var backgroundImage: UIImageView!
    @IBOutlet var tableView: UITableView!
    @IBOutlet var friendsCollectionView: UICollectionView!
    let defaultImage = CircleFilter().filter(UIImage(named: "juke_icon")!)
    let firebaseRef = Database.database().reference()
    var dataSource: FUITableViewDataSource!

    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Discover Streams"
//        self.friendsCollectionView.delegate = self
//        self.friendsCollectionView.dataSource = self
        if let newDataSource = FirebaseAPI.addDiscoverStreamsTableViewListener(allStreamsTableView: tableView) {
            self.dataSource = newDataSource
        }
    }
    
    
    
//    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
//        return self.friends.count
//    }
//    
//    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
//        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell",
//                                                      for: indexPath) as! FriendCollectionViewCell
//        let friend = friends[indexPath.row]
//        let filter = AspectScaledToFillSizeCircleFilter(size: cell.friendImage.frame.size)
//        if let urlString = friend.imageURL {
//            cell.friendImage.af_setImage(withURL: URL(string: urlString)!, placeholderImage: defaultImage, filter: filter) { response in
//                self.friends[indexPath.row].image = response.value
//            }
//        } else {
//            cell.friendImage.image = defaultImage
//        }
//      
//        return cell
//    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
//        let friend = self.friends[indexPath.row]
//        let username = (friend.username == nil) ? "???" : friend.username!
//        let appearance = SCLAlertView.SCLAppearance(
//            kCircleHeight: 50, kCircleIconHeight: 50
//        )
//        let alertView = SCLAlertView(appearance: appearance)
//        alertView.addButton("Join stream") {
//            self.joinStream(streamID: friend.tunedInto!)
//        }
//        
//        alertView.showSuccess(username, subTitle: "", circleIconImage: friend.image)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        backgroundImage.image = #imageLiteral(resourceName: "jukedef")
        self.navigationController?.title = "Discover"
        FirebaseAPI.addDiscoverStreamsTableViewListener(allStreamsTableView: self.tableView)
//        fetchFriends()
    }
    
//    private func fetchFriends() {
//        Alamofire.request(ServerConstants.kJukeServerURL + ServerConstants.kFetchFriends, method: .get)
//            .validate().responseJSON { response in
//            switch response.result {
//            case .success:
//                if let unparsedFriends = response.result.value as? [UnboxableDictionary] {
//                    self.friends = []
//                    for unparsedStream in unparsedFriends {
//                        do {
//                            let friend: Models.User = try unbox(dictionary: unparsedStream)
//                            if (friend.id != Current.user.id && friend.tunedInto != Current.user.tunedInto) {
//                                self.friends.append(friend)  // if not tuned into this stream, display it
//                            }
//                        } catch {
//                            print("Error trying to unbox friend: \(error)")
//                        }
//                    }
//                    
//                    DispatchQueue.main.async {
//                        self.friendsCollectionView.reloadData()
//                    }
//                    
//                }
//            case .failure(let error):
//                print(error)
//            }
//        }
//    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        let selectedStream = streams.remove(at: indexPath.row)
//        joinStream(streamID: selectedStream.streamID)
        // TODO: join stream.... old implementation below
//        HUD.show(.progress)
//        socketManager.joinStream(userID: Current.user.id, streamID: streamID) { unparsedStream in
//            do {
//                let stream: Models.Stream = try unbox(dictionary: unparsedStream)
//                Current.user.tunedInto = stream.streamID
//                Current.stream = stream
//                HUD.flash(.success, delay: 0.75) { success in
//                    self.tabBarController?.selectedIndex = 1
//                }
//            } catch {
//                print("Error unboxing new stream: ", error)
//            }
//        }
    }

}
