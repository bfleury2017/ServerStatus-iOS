//
//  Copyright (c) 2015 Google Inc.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import Photos
import UIKit

import Firebase

/**
 * AdMob ad unit IDs are not currently stored inside the google-services.plist file. Developers
 * using AdMob can store them as custom values in another plist, or simply use constants. Note that
 * these ad units are configured to return only test ads, and should not be used outside this sample.
 */

@objc(FCViewController)
class FCViewController: UIViewController, UITableViewDataSource, UITableViewDelegate,
    UITextFieldDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {


  let offlineSegment = 0
  let onlineSegment = 1
    let disksSegment = 2
    let hostsSegment = 3
    let powerSegment = 4

  var ref: FIRDatabaseReference!
  var query: FIRDatabaseQuery!
  var messages: [FIRDataSnapshot]! = []
  var msglength: NSNumber = 10
  fileprivate var _refHandle: FIRDatabaseHandle!

  @IBOutlet weak var clientTable: UITableView!
    @IBOutlet weak var segment: UISegmentedControl!
    

  override func viewDidLoad() {
    super.viewDidLoad()

    self.clientTable.register(UITableViewCell.self, forCellReuseIdentifier: "tableViewCell")

    //set initial reference and query
    ref = FIRDatabase.database().reference().child("ServerNames")
    //query for ping connectivity state
    query = ref.queryOrdered(byChild: "state").queryEqual(toValue: 0)
    refreshDatabase(query: query)
   
  }

  deinit {
    self.ref.child("ServerNames").removeObserver(withHandle: _refHandle)
  }
   
    @IBAction func segment(_ sender: UISegmentedControl) {
        switch(sender.selectedSegmentIndex) {
        case offlineSegment:
            query = ref.queryOrdered(byChild: "state").queryEqual(toValue: 0)
        case onlineSegment:
            query = ref.queryOrdered(byChild: "state").queryEqual(toValue: 1)
        case disksSegment:
            //query for disk percentage remaining equal to 10 percent or lower
            query = ref.queryOrdered(byChild: "diskPercentage").queryEnding(atValue: 10)
        case hostsSegment:
            //query for only hosts
            query = ref.queryOrdered(byChild: "isHost").queryEqual(toValue: 1)
        case powerSegment:
            //query for powered on machines
            query = ref.queryOrdered(byChild: "powerState").queryEqual(toValue: "PoweredOn")
        default:
            print("default")
        }
        
        messages.removeAll()
        self.ref.child("ServerNames").removeObserver(withHandle: _refHandle)
        refreshDatabase(query: query)
        clientTable.reloadData()
    }

    func refreshDatabase(query: FIRDatabaseQuery) {

        // Listen for new messages in the database
        _refHandle = query.observe(.childAdded, with: { [weak self] (snapshot) -> Void in
            guard let strongSelf = self else { return }

          strongSelf.messages.append(snapshot)
            
        strongSelf.clientTable.insertRows(at: [IndexPath(row: strongSelf.messages.count-1, section: 0)], with: .automatic)

        })

         query.observe(.childChanged, with: { [weak self] (snapshot) -> Void in
            guard let strongSelf = self else { return }
            let index = strongSelf.indexOfMessage(snapshot: snapshot)
            strongSelf.messages.remove(at: index)
            strongSelf.messages.append(snapshot)
            strongSelf.clientTable.reloadData()
            print("child changed")
        })
        
        query.observe(.childRemoved, with: { [weak self] (snapshot) -> Void in
            guard let strongSelf = self else { return }
            
            let index = strongSelf.indexOfMessage(snapshot: snapshot)

            if (self?.messages.count)! > 0 {
                strongSelf.messages.remove(at: index)
                strongSelf.clientTable.deleteRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
            }
            print("child removed")
        })
    }

    func indexOfMessage(snapshot: FIRDataSnapshot) -> Int {
        var index = 0
        for  comment in self.messages {
            if (snapshot.key == comment.key) {
                return index
            }
            index += 1
        }
        return -1
    }

  // UITableViewDataSource protocol methods
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return messages.count
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    // Dequeue cell
    let cell = self.clientTable .dequeueReusableCell(withIdentifier: "tableViewCell", for: indexPath)
    // Unpack message from Firebase DataSnapshot
    let messageSnapshot: FIRDataSnapshot! = self.messages[indexPath.row]
    let message = messageSnapshot.value as! Dictionary<String, AnyObject>
    let serverName = message[Constants.MessageFields.serverName] as! String!
    let state = message[Constants.MessageFields.state] as! Int!
    let powerState = message[Constants.MessageFields.powerState] as! String!
    
    let strState = state == 1 ? "Online" : "Offline"
    
    cell.textLabel?.text = serverName! + ": " + strState + ": " + powerState!

      cell.detailTextLabel?.text = serverName!
      cell.imageView?.image = UIImage(named: (strState.lowercased()))

    
    return cell
  }


}
