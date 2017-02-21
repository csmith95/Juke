//
//  SearchViewController.swift
//  Juke
//
//  Created by Conner Smith on 2/18/17.
//  Copyright © 2017 csmith. All rights reserved.
//

import UIKit

class SearchViewController: UIViewController, UITableViewDataSource, UITableViewDelegate,
    UISearchBarDelegate{

    
    var items: [TrackInfo] = []
    let kNumItems = 10
    
    struct TrackInfo {
        var id: String
        var artist: String
        var name: String
    }
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = self
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func tableView(_ tableView: UITableView,
                   numberOfRowsInSection section: Int) -> Int {
        return self.items.count
    }
    
    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        var cellOptional:SearchTableViewCell? = tableView.dequeueReusableCell(withIdentifier : "SearchCell", for: indexPath) as! SearchTableViewCell
        if let cell = cellOptional {
            cell.artist.text = self.items[indexPath.row].artist
            cell.songName.text = self.items[indexPath.row].name
            return cell
        }
        
        let cell = SearchTableViewCell()
        cell.artist.text = self.items[indexPath.row].artist
        cell.songName.text = self.items[indexPath.row].name
        return cell
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        searchForWords(query: searchBar.text!)
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchForWords(query: searchBar.text!)
    }
    
    func fillItems(json: NSDictionary) {
        let tracks = json["tracks"] as! NSDictionary
        let items = tracks["items"] as! NSArray
        print("ITEMS: ", items)
        let numItemsToCache = min(kNumItems, items.count)
        for i in 0 ..< numItemsToCache {
            let curr = items[i] as! NSDictionary
            let id = curr["uri"] as! String
            let name = curr["name"] as! String
            let artists = curr["artists"] as! NSArray
            let first = artists[0] as! NSDictionary
            let artist = first["name"] as! String
            self.items.append(TrackInfo(id: id, artist: artist, name: name))
        }
    }
    
    func searchForWords(query: String) {
        print("SEARCH CALLED: ", query)
        self.items = []
        let userDefaults = UserDefaults.standard
        if userDefaults.object(forKey: "access_token") != nil {
            let token = userDefaults.string(forKey: "access_token")
            SPTSearch.perform(withQuery: query, queryType: SPTSearchQueryType.queryTypeTrack, accessToken: token, callback: { (error, any) in
                
                if userDefaults.object(forKey: "access_token") != nil {
                    let token = userDefaults.string(forKey: "access_token")
                    SPTSearch.perform(withQuery: query, queryType: SPTSearchQueryType.queryTypeTrack, accessToken: token, callback: { (error, any) in
                        let listPage = any as! SPTListPage
                        if listPage.totalListLength == 0 {
                            print("FOUND NO SEARCH RESULTS")
                            return
                        }
                        
                        let template = "https://api.spotify.com/v1/search?query=$&type=track&market=US&offset=00&limit=10"
                        let tmp = template.replacingOccurrences(of: "$", with: query)
                        let url = URL(string: tmp.replacingOccurrences(of: " ", with: "%20"))!
                        let data = NSData(contentsOf: url) as Data?
                        do {
                            let json = try JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions.allowFragments) as! NSDictionary
                            self.fillItems(json: json)
                            self.tableView.reloadData()
                        } catch {
                            print("ERROR: ", error)
                        }
                    })
                }
            })
        }
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
