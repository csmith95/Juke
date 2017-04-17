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

class StreamsTableViewController: UITableViewController {
    
    var streams: [Models.Stream] = []
    let socketManager = SocketManager.sharedInstance
    let defaultImage = UIImage(named: "juke_icon")!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.backgroundColor = UIColor(red: 240/255.0, green: 240/255.0, blue: 240/255.0, alpha: 1.0)
        self.title = "Jams"

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false
    }
    
    override func viewWillAppear(_ animated: Bool) {
        fetchStreams()
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
        let imageFilter = CircleFilter()
        var imageView:UIImageView!
        if index == 0 {
            imageView = cell.ownerIcon
        } else {
            imageView = cell.getImageViewForMember(index: index)
        }
        
        if let unwrappedUrl = url {
            imageView.af_setImage(withURL: URL(string: unwrappedUrl)!, placeholderImage: nil, filter: imageFilter)
        } else {
            imageView.image = imageFilter.filter(defaultImage)
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "StreamCell", for: indexPath) as! StreamCell
        let stream = streams[indexPath.row]
        let song = stream.songs[0]
        cell.artist.text = song.artistName
        cell.coverArt.af_setImage(withURL: URL(string: song.coverArtURL)!, placeholderImage: nil, filter: RoundedCornersFilter(radius: 20.0)) { response in
            self.streams[indexPath.row].songs[0].coverArt = response.result.value
        }
        
        setImage(cell: cell, url: stream.owner.imageURL, index: 0)
        let numIconsToDisplay = stream.members.count - 1
        if numIconsToDisplay > 0 {
            for i in 1...numIconsToDisplay {
                setImage(cell: cell, url: stream.members[i].imageURL, index: i)
            }
        }
        let remainder = stream.members.count - 5;
        if remainder > 0 {
            cell.moreMembersLabel.text = "+ \(remainder) more member" + ((remainder > 1) ? "s" : "")
            cell.moreMembersLabel.isHidden = false
        } else {
            cell.moreMembersLabel.isHidden = true
        }

        cell.song.text = song.songName
        cell.setMusicIndicator(play: stream.isPlaying)
        cell.updateUI()
        return cell
    }
    
//    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
//        if (segue.identifier == "displayStream") {
//            let vc = segue.destination as! StreamController
//            vc.stream = self.streams[self.tableView.indexPathForSelectedRow!.row]
//        }
//    }
    
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
                            if (fetchedStream.songs.count > 0 && fetchedStream.streamID != CurrentUser.stream?.streamID) {
                                self.streams.append(fetchedStream)
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
