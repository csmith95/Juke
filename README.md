# Juke

## Setup project
1. Make sure you have the up to date version of the repo
2. If necessary, run 'sudo gem install cocoapods' to install CocoaPods, a service to manage library dependencies. 
3. In terminal, navigate into the Juke project folder and run 'pod install'
4. After running pod install open the Juke.xcworkspace. From now on you must always use the .xcworkspace file instead of the .xcodeproj file for dev
5. If you get errors about missing files, try this: http://stackoverflow.com/questions/32767936/pod-update-is-removing-target-support-files-but-not-updating-my-project-settin

## Documentation for libraries used
Add documentation for libraries used below
1. Alamofire -> https://github.com/Alamofire/Alamofire#response-handling 
  * Used for network requests to our server as well as Spotify server
2. AlamofireImage -> https://github.com/Alamofire/AlamofireImage
  * Alamofire extension for image-specific requests. Useful because we only store image URLs in our db.
3. Unbox -> https://github.com/JohnSundell/Unbox
  * Swift JSON decoder. See Models.swift for the models we're using.
4. Socket.io Swift Client -> https://github.com/socketio/socket.io-client-swift
  * Web socket interface for Swift. Here is the server-side repo: https://github.com/socketio/socket.io
5. Miscellaneous Awesome Libs -> https://github.com/matteocrippa/awesome-swift#uitableview
  * Great list of Swift libraries for any task. 
