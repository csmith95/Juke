//
//  SpotifySearchTableViewController.swift
//  Juke
//
//  Created by Conner Smith on 9/12/17.
//  Copyright © 2017 csmith. All rights reserved.
//

import UIKit
import Alamofire
import Unbox
import Crashlytics

class SpotifySearchTableViewController: UIViewController {
    
    @IBOutlet var tableView: UITableView!
    @IBOutlet var searchBar: UISearchBar!
    
    var allResults:[Models.SpotifySong] = []           // all results
    var displayedResults:[Models.SpotifySong] = []  // filtered results
    typealias JSONStandard = [String: Any]
    
    
    // MARK: view life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(hideKeyboard))
        self.tableView.addGestureRecognizer(tapRecognizer)
        checkEmptyState()
        self.fetchRecentlyPlayed()
        
        // track views of this page
        Answers.logContentView(withName: "Search Page", contentType: "Search Page", contentId: "\(Current.user?.spotifyID ?? "noname"))|searchpageview")
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // reset
        searchBar.text = ""
        execSearch(keywords: "")
        SongKeeper.addedSongs.removeAll()
    }
    
    func threadSafeReloadView() {
        objc_sync_enter(tableView)
        tableView.reloadData()
        checkEmptyState()
        objc_sync_exit(tableView)
    }
    
    func hideKeyboard() {
        self.view.endEditing(true)
        searchBar.setShowsCancelButton(false, animated: true)
    }
    
    func execSearch(keywords: String) {
        displayedResults.removeAll()
        if keywords.isEmpty {
            threadSafeReloadView()
            return
        }
        searchSpotify(keywords: keywords)
    }
    
    func searchSpotify(keywords: String) {
        SessionManager.executeWithToken { (token) in
            let params: Parameters = [
                "query" : keywords + "*",
                "type" : "track,artist",
                "offset": "00",
                "limit": "20",
                "market": "US"
            ]
            
            guard let token = SessionManager.accessToken else { return }
            let headers = [
                "Authorization": "Bearer " + token
            ]
            
            Alamofire.request(Constants.kSpotifySearchURL, method: .get, parameters: params, headers: headers)
                .validate().responseJSON { response in
                    switch response.result {
                    case .success:
                        self.parseSearchData(JSONData: response.data!)
                    case .failure(let error):
                        print("error searching spotify: ", error)
                    }
            }
        }
    }
    
    func parseSearchData(JSONData: Data) {
        self.allResults.removeAll()
        do {
            var readableJSON = try JSONSerialization.jsonObject(with: JSONData, options: .mutableContainers) as! JSONStandard
            if let tracks = readableJSON["tracks"] as? JSONStandard{
                if let items = tracks["items"] as? [JSONStandard] {
                    for item in items {
                        // convert to models.spotifySong so we can add to stream.
                        let curr = item as UnboxableDictionary
                        do {
                            let spotifySong: Models.SpotifySong = try unbox(dictionary: curr)
                            self.allResults.append(spotifySong)
                        } catch {
                            print("error unboxing spotify song: ", error)
                        }
                    }
                }
            }

            self.displayedResults = self.allResults
            DispatchQueue.main.async {
                self.threadSafeReloadView()
            }
        }
        catch {
            print("error", error)
        }
    }
    
    func fetchRecentlyPlayed() {
        SessionManager.executeWithToken { (token) in

            guard let token = SessionManager.accessToken else { return }
            let headers = [
                "Authorization": "Bearer " + token
            ]
            
            Alamofire.request(Constants.kRecentlyPlayedURL, method: .get, headers: headers)
                .responseJSON { response in
                    switch response.result {
                    case .success:
                        //self.parseSearchData(JSONData: response.data!)
                        print("success in fetch recently played")
                        if let json = response.result.value {
                            print("JSON: \(json)") // serialized json response
                        }
                    case .failure(let error):
                        print("error searching spotify: ", error)
                    }
            }
        }
    }
    
    // set status bar text to white
    override var preferredStatusBarStyle: UIStatusBarStyle { return .lightContent }
}

extension SpotifySearchTableViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        execSearch(keywords: searchText.lowercased())
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchBar.setShowsCancelButton(true, animated: true)
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        if let searchText = searchBar.text {
            execSearch(keywords: searchText.lowercased())
        } else {
            execSearch(keywords: "")
        }
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        execSearch(keywords: "")
        hideKeyboard()
    }
}

extension SpotifySearchTableViewController: UITableViewDataSource, UITableViewDelegate {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        hideKeyboard()
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return displayedResults.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SpotifySearchCell", for: indexPath)
        return cell
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let cell = cell as! SearchCell
        cell.populateCell(song: self.displayedResults[indexPath.row])
    }
    
    func checkEmptyState() {
        if tableView.visibleCells.isEmpty {
            let emptyStateLabel = UILabel(frame: self.tableView.frame)
            emptyStateLabel.text = "Search for songs on Spotify"
            emptyStateLabel.textColor = UIColor.white
            emptyStateLabel.textAlignment = .center
            emptyStateLabel.numberOfLines = 0
            self.tableView.backgroundView = emptyStateLabel
        } else {
            self.tableView.backgroundView = nil
        }
    }
}
