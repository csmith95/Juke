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

class StreamsTableViewController: UIViewController, UICollectionViewDelegate, UITableViewDelegate, UITableViewDataSource, UICollectionViewDataSource {
    
    @IBOutlet var backgroundImage: UIImageView!
    @IBOutlet var tableView: UITableView!
    @IBOutlet var friendsCollectionView: UICollectionView!
    var friends: [Models.User] = []
    var streams: [Models.Stream] = []
    let socketManager = SocketManager.sharedInstance
    let defaultImage = CircleFilter().filter(UIImage(named: "juke_icon")!)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.friendsCollectionView.delegate = self
        self.friendsCollectionView.dataSource = self
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.title = "Discover Streams"
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.friends.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell",
                                                      for: indexPath) as! FriendCollectionViewCell
        let friend = friends[indexPath.row]
        let filter = AspectScaledToFillSizeCircleFilter(size: cell.friendImage.frame.size)
        if let urlString = friend.imageURL {
            cell.friendImage.af_setImage(withURL: URL(string: urlString)!, placeholderImage: defaultImage, filter: filter) { response in
                self.friends[indexPath.row].image = response.value
            }
        } else {
            cell.friendImage.image = defaultImage
        }
      
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let friend = self.friends[indexPath.row]
        let username = (friend.username == nil) ? "???" : friend.username!
        let appearance = SCLAlertView.SCLAppearance(
            kCircleHeight: 50, kCircleIconHeight: 50
        )
        let alertView = SCLAlertView(appearance: appearance)
        alertView.addButton("Join stream") {
            self.joinStream(streamID: friend.tunedInto!)
        }
        
        alertView.showSuccess(username, subTitle: "", circleIconImage: friend.image)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        backgroundImage.image = #imageLiteral(resourceName: "jukedef")
        self.navigationController?.title = "Discover"
        fetchStreams()
        fetchFriends()
    }
    
    private func fetchFriends() {
        Alamofire.request(ServerConstants.kJukeServerURL + ServerConstants.kFetchFriends, method: .get)
            .validate().responseJSON { response in
            switch response.result {
            case .success:
                if let unparsedFriends = response.result.value as? [UnboxableDictionary] {
                    self.friends = []
                    for unparsedStream in unparsedFriends {
                        do {
                            let friend: Models.User = try unbox(dictionary: unparsedStream)
                            if (friend.id != CurrentUser.user.id) {
                                self.friends.append(friend)  // if not tuned into this stream, display it
                            }
                        } catch {
                            print("Error trying to unbox friend: \(error)")
                        }
                    }
                    
                    DispatchQueue.main.async {
                        self.friendsCollectionView.reloadData()
                    }
                    
                }
            case .failure(let error):
                print(error)
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return streams.count
    }
    
    private func setImage(cell: StreamCell, url: String?, index: Int) {
        let imageView = cell.getImageViewForMember(index: index)
        if let unwrappedUrl = url {
            imageView.af_setImage(withURL: URL(string: unwrappedUrl)!, placeholderImage: defaultImage)
        } else {
            imageView.image = defaultImage
        }
    }
    
    private func loadCellImages(cell: StreamCell, stream: Models.Stream) {
        // load coverArt
        let filter = AspectScaledToFillSizeWithRoundedCornersFilter(
            size: cell.coverArt.frame.size,
            radius: 20.0
        )
        if stream.songs.count > 0 {
            let song = stream.songs[0]
            cell.coverArt.af_setImage(withURL: URL(string: song.coverArtURL)!, placeholderImage: #imageLiteral(resourceName: "jukedef"), filter: filter)
        } else {
            cell.coverArt.image = filter.filter(#imageLiteral(resourceName: "jukedef"))
        }
        
        // load owner icon
        setImage(cell: cell, url: stream.owner.imageURL, index: 0)
        // load member icons
        let numIconsToDisplay = stream.members.count - 1
        if numIconsToDisplay > 0 {
            for i in 1...numIconsToDisplay {
                setImage(cell: cell, url: stream.members[i].imageURL, index: i)
            }
        } else {
            cell.clearMemberIcons()
        }
        // if there are more members than we're displaying, show a label
        let remainder = stream.members.count - 5;
        if remainder > 0 {
            cell.moreMembersLabel.text = "+ \(remainder) more member" + ((remainder > 1) ? "s" : "")
            cell.moreMembersLabel.isHidden = false
        } else {
            cell.moreMembersLabel.isHidden = true
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "StreamCell", for: indexPath) as! StreamCell
        let stream = streams[indexPath.row]
        loadCellImages(cell: cell, stream: stream)
        if let owner = stream.owner.username {
            cell.username.text = owner.components(separatedBy: " ").first! + "'s stream"
        } else {
            cell.username.text = "???"
        }
        if stream.songs.count > 0 {
            let song = stream.songs[0]
            cell.artist.text = song.artistName
            cell.song.text = song.songName
            cell.blurredBgImage.af_setImage(withURL: URL(string: song.coverArtURL)!)
        } else {
            cell.artist.text = ""
            cell.song.text = ""
            cell.blurredBgImage.image = #imageLiteral(resourceName: "jukedef")
        }
        cell.setMusicIndicator(play: stream.isPlaying)
        return cell
    }
    
    func joinStream(streamID: String) {
        HUD.show(.progress)
        socketManager.joinStream(userID: CurrentUser.user.id, streamID: streamID) { unparsedStream in
            do {
                let stream: Models.Stream = try unbox(dictionary: unparsedStream)
                CurrentUser.user.tunedInto = stream.streamID
                CurrentUser.stream = stream
                HUD.flash(.success, delay: 1.0) { success in
                    self.tabBarController?.selectedIndex = 1
                }
            } catch {
                print("Error unboxing new stream: ", error)
            }
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        joinStream(streamID: self.streams[indexPath.row].streamID)
    }
    
    func fetchStreams() {
        self.streams.removeAll()
        Alamofire.request(ServerConstants.kJukeServerURL + ServerConstants.kFetchStreamsPath, method: .get).validate().responseJSON { response in
            switch response.result {
            case .success:
                if let unparsedStreams = response.result.value as? [UnboxableDictionary] {
                    for unparsedStream in unparsedStreams {
                        do {
                            let fetchedStream: Models.Stream = try unbox(dictionary: unparsedStream)
                            if (fetchedStream.streamID != CurrentUser.stream?.streamID) {
                                self.streams.append(fetchedStream)  // if not tuned into this stream, display it
                            }
                        } catch {
                            print("Error trying to unbox stream: \(error)")
                        }
                    }
                    
                    DispatchQueue.main.async {
                        self.tableView.reloadData()
                    }
                
                }
            case .failure(let error):
                print(error)
            }
        }
    }

}
