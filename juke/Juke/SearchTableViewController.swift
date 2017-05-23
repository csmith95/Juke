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

struct post {
    let song_name: String!
    let artist_name: String!
    //let album_name: String!
}

class SearchTableViewController: UITableViewController, UISearchBarDelegate {
    @IBOutlet weak var searchBar: UISearchBar!
    var results:[Models.SpotifySong] = []
    var savedTracks: [Models.SpotifySong] = []
    
    var searchURL = String()
    typealias JSONStandard = [String: AnyObject]
    var posts = [post]()
    let socketManager = SocketManager.sharedInstance
    
    func execSearch() {
        let keywords = searchBar.text
        if (keywords?.isEmpty)! {
            self.posts.removeAll()
            loadSavedTracks() //optimize this
        } else {
            let finalKeywords = keywords?.replacingOccurrences(of: " ", with: "+")
            searchURL = "https://api.spotify.com/v1/search?q=\(finalKeywords!)&type=track"
            self.posts.removeAll() // reset for a new round of search results
            self.results.removeAll()
            self.tableView.reloadData()
            searchSpotify(url: searchURL)
        }
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        print("search bar button clicked")
        execSearch()
        self.view.endEditing(true)
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        loadSavedTracks()
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        print("search bar ended editing")
        execSearch()
    }


    override func viewDidLoad() {
        super.viewDidLoad()
        searchBar.delegate = self
        tableView.delegate = self
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(hideKeyboard))
        self.tableView.addGestureRecognizer(tapRecognizer)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        // reset UI a new round of search results
        self.searchBar.text = ""
        self.view.endEditing(true)
        self.posts.removeAll()
        self.results.removeAll()
        self.tableView.reloadData()
        loadSavedTracks()

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
        return posts.count
    }
    
    func searchSpotify(url: String) {
        // call alamofire with endpoint
        self.navigationItem.title = "Search results"
        Alamofire.request(url).responseJSON(completionHandler: {
            response in
            self.parseSearchData(JSONData: response.data!)
        })
    }
    
    func parseSearchData(JSONData: Data) {
        print("in parseSearchData")
        do {
            let group = DispatchGroup()
            var readableJSON = try JSONSerialization.jsonObject(with: JSONData, options: .mutableContainers) as! JSONStandard
            if let tracks = readableJSON["tracks"] as? JSONStandard{
                //print("found tracks", tracks)
                if let items = tracks["items"] as? [JSONStandard] {
                    for i in 0..<items.count {
                        let item = items[i]
                        
                        // convert to models.spotifySong so we can add to stream.
                        let curr = item as UnboxableDictionary
                        do {
                            let spotifySong: Models.SpotifySong = try unbox(dictionary: curr)
                            group.enter()
                            self.posts.append(post.init(song_name: spotifySong.songName, artist_name: spotifySong.artistName))
                            self.results.append(spotifySong)
                            group.leave()
                        } catch {
                            print("error unboxing spotify song: ", error)
                        }
                    }
                }
            }
            
            // all images fetched -- update tableView on main thread
            group.notify(queue: DispatchQueue.main) {
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
            self.addSongToStream(song: self.results[indexPath.row], stream: CurrentUser.stream!)
            
            // animate button text change from "+" to "Added!"
            cell.addToStreamButton.isSelected = true
            //cell.addToStreamButton!.titleLabel?.font = UIFont(name: "System", size: 16)
        }
        
        
        let mainLabel = cell.viewWithTag(1) as! UILabel
        let artistLabel = cell.viewWithTag(2) as! UILabel
        
        mainLabel.text = posts[indexPath.row].song_name
        artistLabel.text = posts[indexPath.row].artist_name
        
        return cell
    }
 
    func addSongToStream(song: Models.SpotifySong, stream: Models.Stream) {
        var params: Parameters = ["streamID": stream.streamID, "spotifyID": song.spotifyID, "songName": song.songName, "artistName": song.artistName, "duration": song.duration, "coverArtURL": song.coverArtURL]
        if let memberImageURL = CurrentUser.user.imageURL {
            params["memberImageURL"] = memberImageURL
        } else {
            params["memberImageURL"] = nil
        }
        
        // go through socketManager so that other members will be updated
        socketManager.addSong(params: params);
    }
    
    func loadSavedTracks() {
        print("called loadSavedTracks")
        self.navigationItem.title = "From your saved songs"
        if let sessionObj = UserDefaults.standard.object(forKey: "SpotifySession") {
            let sessionDataObj = sessionObj as! Data
            let session = NSKeyedUnarchiver.unarchiveObject(with: sessionDataObj) as! SPTSession
            let savedSongsUrl = "https://api.spotify.com/v1/me/tracks"
            let headers = [
                "Authorization": "Bearer " + session.accessToken
            ]
            Alamofire.request(savedSongsUrl, headers: headers).responseJSON { response in
                do {
                    //let group = DispatchGroup()
                    var serializedJSON = try JSONSerialization.jsonObject(with: response.data!, options: .mutableContainers) as! JSONStandard
                    //print("serializedJSON", serializedJSON)
                    if let items = serializedJSON["items"] as? [JSONStandard] {
                        for i in 0..<items.count {
                            let item = items[i]["track"]
                            //print("item", item)
                            
                            // convert to models.spotifySong so we can add to stream.
                            let curr = item as! UnboxableDictionary
                            do {
                                //group.enter()
                                let spotifySong: Models.SpotifySong = try unbox(dictionary: curr)
                                self.posts.append(post.init(song_name: spotifySong.songName, artist_name: spotifySong.artistName))
                                self.results.append(spotifySong)
                                //group.leave()
                                print("results", self.results)
                            } catch {
                                print("error unboxing spotify song: ", error)
                            }
                        }
                        DispatchQueue.main.async { self.tableView.reloadData()}
                    }
                    
                }
                catch {
                    print("error unboxing spotify song: ", error)
                }
//                if let JSON = response.result.value {
//                    print("JSON: \(JSON)")
//                }
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
