//
//  PlaylistTableViewController.swift
//  Juke
//
//  Created by Conner Smith on 9/26/17.
//  Copyright © 2017 csmith. All rights reserved.
//

import UIKit
import Alamofire
import Unbox

class PlaylistTableViewController: UITableViewController {
    
    public var playlist: Models.SpotifyPlaylist!
    public var allSongs: [Models.SpotifySong] = []
    public var displayedSongs: [Models.SpotifySong] = []
    typealias JSONStandard = [String: Any]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(hideKeyboard))
        self.tableView.addGestureRecognizer(tapRecognizer)
    }
    
    func hideKeyboard() {
        NotificationCenter.default.post(name: Notification.Name("MyLibraryPager.hideKeyboard"), object: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        fetchSongs()
        super.viewWillAppear(animated)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        // reset
        allSongs.removeAll()
        displayedSongs.removeAll()
        super.viewDidDisappear(animated)
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
        return displayedSongs.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return tableView.dequeueReusableCell(withIdentifier: "SearchCell", for: indexPath)
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let cell = cell as! SearchCell
        cell.populateCell(song: self.displayedSongs[indexPath.row])
    }
    
    private func threadSafeReloadView() {
        objc_sync_enter(tableView)
        tableView.reloadData()
        objc_sync_exit(tableView)
    }
    
    private func fetchSongs() {
        let headers = [
            "Authorization": "Bearer " + SessionManager.accessToken
        ]
        let params: Parameters = ["limit": 50, "offset": 0]
        Alamofire.request(playlist.tracksURL, parameters: params, headers: headers).responseJSON { response in
            do {
                print(response.data)
                var serializedJSON = try JSONSerialization.jsonObject(with: response.data!, options: .mutableContainers) as! JSONStandard
                if let items = serializedJSON["items"] as? [JSONStandard] {
                    for i in 0..<items.count {
                        let item = items[i]["track"]
                        let curr = item as! UnboxableDictionary
                        do {
                            let spotifySong: Models.SpotifySong = try unbox(dictionary: curr)
                            self.allSongs.append(spotifySong)
                        } catch {
                            print("error unboxing spotify song: ", error)
                        }
                    }
                    
                    // to make UI more responsive, display first 50 immediately
                    // then load the rest
                    self.displayedSongs = self.allSongs
                    DispatchQueue.main.async {
                        self.threadSafeReloadView()
                    }
//                    self.recursiveLoadTracks(urlString: serializedJSON["next"] as? String, headers: headers)
                }
            } catch {
                print("error unboxing JSON")
            }
        }
    }
    
    // set status bar content to white text
    override var preferredStatusBarStyle: UIStatusBarStyle { return .lightContent }
}
