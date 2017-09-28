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

class SpotifySearchTableViewController: UITableViewController {
    
    @IBOutlet var searchBar: UISearchBar!
    
    var allResults:[Models.SpotifySong] = []           // all results
    var displayedResults:[Models.SpotifySong] = []  // filtered results
    typealias JSONStandard = [String: Any]
    
    
    // MARK: view life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(hideKeyboard))
        self.tableView.addGestureRecognizer(tapRecognizer)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // reset
        searchBar.text = ""
        execSearch(keywords: "")
        SongKeeper.addedSongs.removeAll()
    }
    
    // MARK: - Table view data source/delegate
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        hideKeyboard()
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return displayedResults.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SpotifySearchCell", for: indexPath)
        return cell
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let cell = cell as! SearchCell
        cell.populateCell(song: self.displayedResults[indexPath.row])
    }
    
    func threadSafeReloadView() {
        objc_sync_enter(tableView)
        tableView.reloadData()
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
        let finalKeywords = keywords.replacingOccurrences(of: " ", with: "+")
        searchSpotify(keywords: finalKeywords)
    }
    
    func searchSpotify(keywords: String) {
        let params: Parameters = [
            "query" : keywords + "*",
            "type" : "track,artist",
            "offset": "00",
            "limit": "20",
            "market": "US"
        ]
        
        print(params)
        
        let headers = [
            "Authorization": "Bearer " + SessionManager.accessToken
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
