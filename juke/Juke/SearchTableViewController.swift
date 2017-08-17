//
//  SearchTableViewController.swift
//  Juke
//
//  Created by Kojo Worai Osei on 4/14/17.
//  Copyright © 2017 csmith. All rights reserved.
//

import UIKit
import Alamofire
import AlamofireImage
import Unbox
import Firebase

class SearchTableViewController: UITableViewController, UISearchBarDelegate {
    @IBOutlet weak var searchBar: UISearchBar!
    var libraryResults:[Models.SpotifySong] = []       // saves list of user's library
    var spotifyResults:[Models.SpotifySong] = []    // saved spotify search results
    var displayedResults:[Models.SpotifySong] = [] // what is displayed to user
    
    var searchURL = String()
    typealias JSONStandard = [String: AnyObject]
    let firebaseRef = Database.database().reference()
    
    enum Scope: Int {
        case MyLibrary = 0, Spotify
    }
    
    func execSearch() {
        let keywords = searchBar.text!.lowercased()
        switch searchBar.selectedScopeButtonIndex {
        case Scope.MyLibrary.rawValue:
            filterLibrary(keywords: keywords)
        case Scope.Spotify.rawValue:
            if keywords.characters.count == 0 {
                displayedResults.removeAll()
                tableView.reloadData()
                return
            }
            let finalKeywords = keywords.replacingOccurrences(of: " ", with: "+")
            searchSpotify(keywords: finalKeywords)
        default:
            print("idk")
        }
    }
    
    func filterLibrary(keywords: String) {
        if keywords.characters.count == 0 {
            showMyLibrary()
        } else {
            displayedResults = libraryResults.filter({ (song) -> Bool in
                return song.songName.lowercased().contains(keywords) || song.artistName.lowercased().contains(keywords)
            })
            tableView.reloadData()
        }
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        execSearch()
    }
    
    func showMyLibrary() {
        displayedResults = libraryResults
        tableView.reloadData()
//        if libraryResults.count == 0 {
//            loadSavedTracks()   // if not already cached, load and display in this method
//        } else {
//            displayedResults = libraryResults // otherwise show cached results
//            tableView.reloadData()
//        }
    }
    
    func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        execSearch()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        execSearch()
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        switch searchBar.selectedScopeButtonIndex {
        case Scope.MyLibrary.rawValue:
            showMyLibrary()
        case Scope.Spotify.rawValue:
            spotifyResults.removeAll()
            displayedResults.removeAll()
            tableView.reloadData()
        default:
            print("idk")
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        searchBar.scopeButtonTitles = ["My Library", "Spotify"]
        searchBar.delegate = self
        tableView.delegate = self
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(hideKeyboard))
        self.tableView.addGestureRecognizer(tapRecognizer)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        // reset UI
        self.navigationItem.title = "Search"
        self.searchBar.text = ""
        self.view.endEditing(true)
        self.searchBar.selectedScopeButtonIndex = 0
        loadSavedTracks()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        self.tableView.reloadData() // to clear the "Added!" markers before user navigates back
    }
    
    func hideKeyboard() {
        self.view.endEditing(true)
    }
    
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        self.view.endEditing(true)
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
        return displayedResults.count
    }
    
    func searchSpotify(keywords: String) {
        let params: Parameters = [
            "query" : keywords,
            "type" : "track,artist,album",
            "offset": "00",
            "limit": "50",
            "market": "US"
        ]
        
        let headers = [
            "Authorization": "Bearer " + CurrentUser.accessToken
        ]
        
        Alamofire.request(ServerConstants.kSpotifySearchURL, method: .get, parameters: params, headers: headers)
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
        self.spotifyResults.removeAll()
        do {
            var readableJSON = try JSONSerialization.jsonObject(with: JSONData, options: .mutableContainers) as! JSONStandard
            if let tracks = readableJSON["tracks"] as? JSONStandard{
                if let items = tracks["items"] as? [JSONStandard] {
                    for item in items {
                        // convert to models.spotifySong so we can add to stream.
                        let curr = item as UnboxableDictionary
                        do {
                            let spotifySong: Models.SpotifySong = try unbox(dictionary: curr)
                            self.spotifyResults.append(spotifySong)
                        } catch {
                            print("error unboxing spotify song: ", error)
                        }
                    }
                }
            }
            
            DispatchQueue.main.async {
                self.displayedResults = self.spotifyResults
                self.tableView.reloadData()
            }
        }
        catch {
            print("error", error)
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SearchCell") as! SearchCell
        cell.addToStreamButton.isSelected = false
        cell.tapAction = { (cell) in
            // post to server
            self.addSongToStream(song: self.displayedResults[indexPath.row], stream: CurrentUser.stream!)
            
            // animate button text change from "+" to "Added!"
            cell.addToStreamButton.isSelected = true
        }
        
        
        let mainLabel = cell.viewWithTag(1) as! UILabel
        let artistLabel = cell.viewWithTag(2) as! UILabel
        
        mainLabel.text = displayedResults[indexPath.row].songName
        artistLabel.text = displayedResults[indexPath.row].artistName
        
        return cell
    }
 
    func addSongToStream(song: Models.SpotifySong, stream: Models.Stream) {
        let key = firebaseRef.child("songs/stream1").childByAutoId().key
        let post: [String: Any] = ["spotifyID": song.spotifyID,
                    "artistName": song.artistName,
                    "songName": song.songName,
                    "duration": song.duration,
                    "votes": 0,
                    "coverArtURL": song.coverArtURL]
        firebaseRef.child("/songs/stream1/\(key)").setValue(post)
    }
    
    func loadSavedTracks() {
        self.libraryResults.removeAll()
        let url = "https://api.spotify.com/v1/me/tracks"
        let headers = [
            "Authorization": "Bearer " + CurrentUser.accessToken
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
                            self.libraryResults.append(spotifySong)
                        } catch {
                            print("error unboxing spotify song: ", error)
                        }
                    }
                    
                    // to make UI more responsive, display first 50 immediately
                    // then load the rest
                    DispatchQueue.main.async {
                        self.displayedResults = self.libraryResults
                        self.tableView.reloadData()
                    }
                    self.recursiveLoadTracks(urlString: serializedJSON["next"] as? String, headers: headers)
                }
            }catch {
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
                        for item in items {
                            let curr = item["track"] as! UnboxableDictionary
                            do {
                                let spotifySong: Models.SpotifySong = try unbox(dictionary: curr)
                                self.libraryResults.append(spotifySong)
                            } catch {
                                print("error unboxing spotify song: ", error)
                            }
                        }
                        
                        self.recursiveLoadTracks(urlString: serializedJSON["next"] as? String, headers: headers)
                    }
                } catch {
                    print("error unboxing JSON")
                }
            }
        } else {
            // url is nil -- all songs have been loaded, so update table on main thread
            DispatchQueue.main.async {
                self.displayedResults = self.libraryResults
                self.tableView.reloadData()
            }
        }
    }

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
