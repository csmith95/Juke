//
//  SearchTableViewController.swift
//  Juke
//
//  Created by Kojo Worai Osei on 4/14/17.
//  Copyright © 2017 csmith. All rights reserved.
//

import UIKit
import Alamofire
import Unbox

struct post {
    let mainImage: UIImage!
    let name: String!
}

class SearchTableViewController: UITableViewController, UISearchBarDelegate {
    @IBOutlet weak var searchBar: UISearchBar!
    var results:[Models.SpotifySong] = []
    
    var searchURL = String()
    typealias JSONStandard = [String: AnyObject]
    var posts = [post]()
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        let keywords = searchBar.text
        print("searching.. keywords are \(String(describing: keywords))")
        let finalKeywords = keywords?.replacingOccurrences(of: " ", with: "+")
        
        searchURL = "https://api.spotify.com/v1/search?q=\(finalKeywords!)&type=track"
        
        searchSpotify(url: searchURL)
        self.view.endEditing(true)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        searchBar.delegate = self
        tableView.delegate = self
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
        Alamofire.request(url).responseJSON(completionHandler: {
            response in
            self.parseSearchData(JSONData: response.data!)
            
        })
    }
    
    func parseSearchData(JSONData: Data) {
        do {
            var readableJSON = try JSONSerialization.jsonObject(with: JSONData, options: .mutableContainers) as! JSONStandard
            print(readableJSON)
            if let tracks = readableJSON["tracks"] as? JSONStandard{
                if let items = tracks["items"] as? [JSONStandard] {
                    for i in 0..<items.count {
                        let item = items[i]
                        
                        // convert to models.spotifySong so we can add to stream. CHECK: make less redundant
                        let curr = item as UnboxableDictionary
                        do {
                            let spotifySong: Models.SpotifySong = try unbox(dictionary: curr)
                            self.results.append(spotifySong)
                        } catch {
                            print("error unboxing spotify song: ", error)
                        }
                        
                        let name = item["name"] as! String
                        
                        if let album = item["album"] as? JSONStandard{
                            if let images = album["images"] as? [JSONStandard]{
                                let imageData = images[0]
                                let mainImageURL = URL(string: imageData["url"] as! String)
                                let mainImageData = NSData(contentsOf: mainImageURL!)
                                
                                let mainImage = UIImage(data: mainImageData as! Data)
                                
                                posts.append(post.init(mainImage: mainImage, name: name))
                                self.tableView.reloadData()
                            }
                        }

                    }
                }
            }
        }
        catch {
            print(error)
        }
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SearchCell") as! SearchCell
        
        cell.tapAction = { (cell) in
            // post to server
            self.addSongToStream(song: self.results[indexPath.row], stream: CurrentUser.stream!)
            
            // animate button text change from "+" to "Added!"
            cell.addToStreamButton!.setTitle("Added!", for: .normal)
            cell.addToStreamButton!.titleLabel?.font = UIFont(name: "System", size: 16)
        }
        
        
        
        let mainImageView = cell.viewWithTag(2) as! UIImageView
        
        mainImageView.image = posts[indexPath.row].mainImage
        
        let mainLabel = cell.viewWithTag(1) as! UILabel
        
        mainLabel.text = posts[indexPath.row].name
        
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
                    CurrentUser.stream = stream
                    print("added song")
                } catch {
                    print("error unboxing stream after adding song: ", error)
                }
                
            case .failure(let error):
                print("Error adding song to current stream: ", error)
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
