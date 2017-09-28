//
//  MyPlaylistsTableViewController.swift
//  Juke
//
//  Created by Conner Smith on 9/26/17.
//  Copyright © 2017 csmith. All rights reserved.
//

import UIKit
import Alamofire
import Unbox
import XLPagerTabStrip

class MyPlaylistsTableViewController: UITableViewController, IndicatorInfoProvider {

    var allPlaylists: [Models.SpotifyPlaylist] = []
    var displayedPlaylists: [Models.SpotifyPlaylist] = []
    typealias JSONStandard = [String: Any]

    func indicatorInfo(for pagerTabStripController: PagerTabStripViewController) -> IndicatorInfo {
        return IndicatorInfo(title: "Playlists")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // note: this fucks up detecting cell selection
//        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(hideKeyboard))
//        self.tableView.addGestureRecognizer(tapRecognizer)
    }
    
    func hideKeyboard() {
        NotificationCenter.default.post(name: Notification.Name("MyLibraryPager.hideKeyboard"), object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        fetchPlaylists()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return tableView.dequeueReusableCell(withIdentifier: "PlaylistCell", for: indexPath)
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let cell = cell as! PlaylistTableViewCell
        cell.populateCell(playlist: self.displayedPlaylists[indexPath.row])
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return displayedPlaylists.count
    }
    
    private func threadSafeReloadView() {
        objc_sync_enter(tableView)
        tableView.reloadData()
        objc_sync_exit(tableView)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        print("prep")
        if segue.identifier == "ShowPlaylist" {
            print("1")
            if let row = tableView.indexPathForSelectedRow?.row, let dest = segue.destination as? PlaylistTableViewController  {
                print(self.displayedPlaylists[row])
                dest.playlist = self.displayedPlaylists[row]
            }
        }
    }

    private func fetchPlaylists() {
        if !allPlaylists.isEmpty { return } // alread fetched -- return
        
        let headers = [
            "Authorization": "Bearer " + SessionManager.accessToken
        ]
        let params: Parameters = ["limit": 50, "offset": 0]
        Alamofire.request(Constants.kSpotifyMyPlaylistsURL, parameters: params, headers: headers).responseJSON { response in
            do {
                var serializedJSON = try JSONSerialization.jsonObject(with: response.data!, options: .mutableContainers) as! JSONStandard
                if let items = serializedJSON["items"] as? [JSONStandard] {
                    for item in items {
                        do {
                            let playlist: Models.SpotifyPlaylist = try unbox(dictionary: item)
                            print(playlist.imageURL)
                            self.allPlaylists.append(playlist)
                        } catch {
                            print("error unboxing spotify song: ", error)
                        }
                    }
                    
                    // to make UI more responsive, display first 50 immediately
                    // then load the rest
                    self.displayedPlaylists = self.allPlaylists
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
    
    @IBAction func unwindToViewControllerNameHere(segue: UIStoryboardSegue) {
        //nothing goes here
    }

}