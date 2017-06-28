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

class StreamsTableViewController: UITableViewController, UICollectionViewDelegate, UICollectionViewDataSource {
    
    @IBOutlet var friendsCollectionView: UICollectionView!
    var friends: [Models.User] = []
    var streams: [Models.Stream] = []
    let socketManager = SocketManager.sharedInstance
    let defaultImage = CircleFilter().filter(UIImage(named: "juke_icon")!)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Available streams"
        self.friendsCollectionView.delegate = self
        self.friendsCollectionView.dataSource = self

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.friends.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell",
                                                      for: indexPath) as! FriendCollectionViewCell
        let friend = friends[indexPath.item]
        if let urlString = friend.imageURL {
            cell.friendImage.af_setImage(withURL: URL(string: urlString)!, placeholderImage: defaultImage, filter: CircleFilter())
        } else {
            cell.friendImage.image = defaultImage
        }
      
        return cell
    }
    
    override func viewWillAppear(_ animated: Bool) {
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

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
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
        if stream.songs.count > 0 {
            let song = stream.songs[0]
            cell.coverArt.af_setImage(withURL: URL(string: song.coverArtURL)!, placeholderImage: #imageLiteral(resourceName: "jukedef"))
        }
        // load owner icon
        setImage(cell: cell, url: stream.owner.imageURL, index: 0)
        // load member icons
        let numIconsToDisplay = stream.members.count - 1
        if numIconsToDisplay > 0 {
            for i in 1...numIconsToDisplay {
                setImage(cell: cell, url: stream.members[i].imageURL, index: i)
            }
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

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "StreamCell", for: indexPath) as! StreamCell
        let stream = streams[indexPath.row]
        loadCellImages(cell: cell, stream: stream)
        cell.username.text = stream.owner_name.components(separatedBy: " ").first! + "'s stream"
        if stream.songs.count > 0 {
            let song = stream.songs[0]
            cell.artist.text = song.artistName
            cell.song.text = song.songName
        }
        cell.setMusicIndicator(play: stream.isPlaying)
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        HUD.show(.progress)
        let stream = self.streams[indexPath.row]
        socketManager.joinStream(userID: CurrentUser.user.id, streamID: stream.streamID) { unparsedStream in
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
    
    func fetchStreams() {
        Alamofire.request(ServerConstants.kJukeServerURL + ServerConstants.kFetchStreamsPath, method: .get).validate().responseJSON { response in
            switch response.result {
            case .success:
                if let unparsedStreams = response.result.value as? [UnboxableDictionary] {
                    self.streams = []    // clear groups that have already been fetched to avoid duplicate displays
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
