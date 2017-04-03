//
//  SearchTableViewController.swift
//  Juke
//
//  Created by Conner Smith on 3/7/17.
//  Copyright © 2017 csmith. All rights reserved.
//

import UIKit
import Alamofire
import Unbox

class SearchTableViewController: UITableViewController, UISearchBarDelegate {
    
    var results:[Models.SpotifySong] = []
    let kNumResultsToStore = 20
    let searchController = UISearchController(searchResultsController: nil)
    
    @IBOutlet var searchBar: UISearchBar!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        searchBar.delegate = self
        tableView.delegate = self
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        search(query: searchBar.text!)
        self.searchBar.endEditing(true)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return results.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = self.tableView.dequeueReusableCell(withIdentifier: "searchCell", for: indexPath) as! SearchCell
        let song = results[(indexPath as NSIndexPath).row]
        cell.songLabel!.text = song.songName
        cell.artistLabel!.text = song.artistName
        // Assign the tap action which will be executed when the user taps the UIButton
        cell.tapAction = { (cell) in
            // post to server
            self.addSongToStream(song: self.results[indexPath.row], stream: CurrentUser.currStream!)
            
            // animate button text change from "+" to "Added!"
            cell.addButton!.setTitle("Added!", for: .normal)
            cell.addButton!.titleLabel?.font = UIFont(name: "System", size: 16)
        }
        return cell
    }
    
    func addSongToStream(song: Models.SpotifySong, stream: Models.Stream) {
        let params: Parameters = ["streamID": stream.streamID, "spotifyID": song.spotifyID, "songName": song.songName, "artistName": song.artistName, "duration": song.duration, "coverArtURL": song.coverArtURL]
        Alamofire.request(ServerConstants.kJukeServerURL + ServerConstants.kAddSongPath, method: .post, parameters: params).validate().responseJSON { response in
            switch response.result {
            case .success:
                do {
                    let unparsedStream = response.result.value as! UnboxableDictionary
                    let stream: Models.Stream = try unbox(dictionary: unparsedStream)
                    CurrentUser.currStream = stream
                    print("added song")
                } catch {
                    print("error unboxing stream after adding song: ", error)
                }
                
            case .failure(let error):
                print("Error adding song to current stream: ", error)
            }
        }
    }
    
    // Code to send GET request and parse json response into results array
    func fillItems(json: NSDictionary) {
        let tracks = json["tracks"] as! NSDictionary
        let items = tracks["items"] as! NSArray
        let numItemsToCache = min(kNumResultsToStore, items.count)
        for i in 0 ..< numItemsToCache {
            let curr = items[i] as! UnboxableDictionary
            
            do {
                let spotifySong: Models.SpotifySong = try unbox(dictionary: curr)
                self.results.append(spotifySong)
            } catch {
                print("error unboxing spotify song: ", error)
            }
        }
    }
    
    func search(query: String) {
        if query == "" {
            return
        }
        
        self.results = []
        let params: Parameters = [
            "query" : query,
            "type" : "track",
            "market" : "US",
            "offset" : "00",
            "limit" : "20"
        ]
    
        Alamofire.request(ServerConstants.kSpotifySearchURL, method: .get, parameters: params).validate().responseJSON { response in
            switch response.result {
            case .success:
                if let response = response.result.value as? NSDictionary {
                    self.fillItems(json: response)
                }
                // update UI on main thread
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            case .failure(let error):
                print(error)
            }
        }
    }
    
}




