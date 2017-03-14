//
//  SearchTableViewController.swift
//  Juke
//
//  Created by Conner Smith on 3/7/17.
//  Copyright © 2017 csmith. All rights reserved.
//

import UIKit
import Alamofire

class SearchTableViewController: UITableViewController, UISearchBarDelegate {
    
    var results = [Song]()
    let kNumResultsToStore = 15
    let searchController = UISearchController(searchResultsController: nil)
    
    @IBOutlet var searchBar: UISearchBar!
    
    // passed from GroupController (the previous ViewController)
    var group: GroupsController.Group?
    
    struct Song {
        var uri: String
        var artistName: String
        var songName: String
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        searchBar.delegate = self
        tableView.delegate = self
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        search(query: searchBar.text!)
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
            self.addSongToGroup(song: self.results[indexPath.row], group: self.group!)
            
            // animate button text change from "+" to "Added!"
            cell.addButton!.setTitle("Added!", for: .normal)
            cell.addButton!.titleLabel?.font = UIFont(name: "System", size: 16)
        }
        return cell
    }
    
    func addSongToGroup(song: Song, group: GroupsController.Group) {
        let params: Parameters = ["group_id": group.id!, "song_id": song.uri]
        Alamofire.request(ServerConstants.kJukeServerURL + ServerConstants.kAddSongPath, method: .post, parameters: params).validate().responseJSON { response in
            switch response.result {
            case .success:
                print("Added song: ", song)
            case .failure(let error):
                print(error)
            }
        }
    }
    
    // Code to send GET request and parse json response into results array
    func fillItems(json: NSDictionary) {
        let tracks = json["tracks"] as! NSDictionary
        let items = tracks["items"] as! NSArray
        let numItemsToCache = min(kNumResultsToStore, items.count)
        for i in 0 ..< numItemsToCache {
            let curr = items[i] as! NSDictionary
            let uri = curr["uri"] as! String
            let name = curr["name"] as! String
            let artists = curr["artists"] as! NSArray
            let first = artists[0] as! NSDictionary
            let artist = first["name"] as! String
            self.results.append(Song(uri: uri, artistName: artist, songName: name))
        }
    }
    
    func search(query: String) {
        
        if query == "" {
            return
        }
        
        self.results = []
        let fixedQuery = query.replacingOccurrences(of: " ", with: "%20")
        let params: Parameters = [
            "query" : fixedQuery,
            "type" : "track",
            "market" : "US",
            "offset" : "00",
            "limit" : "10"
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




