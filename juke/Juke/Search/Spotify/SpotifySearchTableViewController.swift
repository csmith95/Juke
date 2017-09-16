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

class SpotifySearchTableViewController: JukeSearchTableViewController {
    
    @IBOutlet var searchBar: UISearchBar!

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.searchBar.text = ""
    }
    
    override func hideKeyboard() {
        self.view.endEditing(true)
        searchBar.setShowsCancelButton(false, animated: true)
    }
    
    override func execSearch(keywords: String) {
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
            "query" : keywords,
            "type" : "track,artist,album",
            "offset": "00",
            "limit": "50",
            "market": "US"
        ]
        
        let headers = [
            "Authorization": "Bearer " + Current.accessToken
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

}
