//
//  MyLibraryTableViewController.swift
//  Juke
//
//  Created by Conner Smith on 9/12/17.
//  Copyright © 2017 csmith. All rights reserved.
//

import UIKit
import Alamofire
import Unbox

class MyLibraryTableViewController: JukeSearchTableViewController {
    
    @IBOutlet var searchBar: UISearchBar!
    
    override var cellName: String {
        get {
            return "MyLibrarySearchCell"
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadSavedTracks()
        NotificationCenter.default.addObserver(self, selector: #selector(self.libraryChanged), name: Notification.Name("libraryChanged"), object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.searchBar.text = ""
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func hideKeyboard() {
        print("\n my lib exec search")
        self.view.endEditing(true)
        searchBar.setShowsCancelButton(false, animated: true)
    }
    
    override func execSearch(keywords: String) {
        if keywords.isEmpty {
            displayedResults = allResults
        } else {
            displayedResults = allResults.filter({ (song) -> Bool in
                return song.songName.lowercased().contains(keywords) || song.artistName.lowercased().contains(keywords)
            })
        }
        threadSafeReloadView()
    }
    
    func libraryChanged(notification: Notification) {
        guard let song = notification.object as? Models.FirebaseSong else { return }
        guard let firstSong = allResults.first else { return }
        if firstSong.spotifyID == song.spotifyID {
            allResults.remove(at: 0)    // song was already in lib -- remove it
        } else {
            // song wasn't in lib -- insert at first index
            let spotifySong = Models.SpotifySong(songName: song.songName,
                                                 artistName: song.artistName,
                                                 spotifyID: song.spotifyID,
                                                 duration: song.duration,
                                                 coverArtURL: song.coverArtURL)
            allResults.insert(spotifySong, at: 0)
        }
        DispatchQueue.main.async {
            self.threadSafeReloadView()
        }
    }

    func loadSavedTracks() {
        self.allResults.removeAll()
        let url = "https://api.spotify.com/v1/me/tracks"
        let headers = [
            "Authorization": "Bearer " + Current.accessToken
        ]
        let params: Parameters = ["limit": 50, "offset": 0]
        Alamofire.request(url, parameters: params, headers: headers).responseJSON { response in
            do {
                var serializedJSON = try JSONSerialization.jsonObject(with: response.data!, options: .mutableContainers) as! JSONStandard
                if let items = serializedJSON["items"] as? [JSONStandard] {
                    for i in 0..<items.count {
                        let item = items[i]["track"]
                        let curr = item as! UnboxableDictionary
                        do {
                            let spotifySong: Models.SpotifySong = try unbox(dictionary: curr)
                            self.allResults.append(spotifySong)
                        } catch {
                            print("error unboxing spotify song: ", error)
                        }
                    }
                    
                    // to make UI more responsive, display first 50 immediately
                    // then load the rest
                    self.displayedResults = self.allResults
                    DispatchQueue.main.async {
                        self.threadSafeReloadView()
                    }
                    self.recursiveLoadTracks(urlString: serializedJSON["next"] as? String, headers: headers)
                }
            } catch {
                print("error unboxing JSON")
            }
        }
    }
    
    private func recursiveLoadTracks(urlString: String?, headers: HTTPHeaders) {
        if let urlString = urlString, let url = URL(string: urlString) {
            Alamofire.request(url, headers: headers).validate().responseJSON { response in
                do {
                    var serializedJSON = try JSONSerialization.jsonObject(with: response.data!, options: .mutableContainers) as! JSONStandard
                    if let items = serializedJSON["items"] as? [JSONStandard] {
                        objc_sync_enter(self.allResults)
                        for item in items {
                            let curr = item["track"] as! UnboxableDictionary
                            do {
                                let spotifySong: Models.SpotifySong = try unbox(dictionary: curr)
                                self.allResults.append(spotifySong)
                            } catch {
                                print("error unboxing spotify song: ", error)
                            }
                        }
                        objc_sync_exit(self.allResults)
                        self.recursiveLoadTracks(urlString: serializedJSON["next"] as? String, headers: headers)
                    }
                } catch {
                    print("error unboxing JSON")
                }
            }
        } else {
            // url is nil -- all songs have been loaded, so update table on main thread
            self.displayedResults = self.allResults
            DispatchQueue.main.async {
                self.threadSafeReloadView()
            }
        }
    }

}
