//
//  ViewController.swift
//  RPAssessment
//
//  Created by Drew Sen on 2019-09-20.
//  Copyright © 2019 Drew Sen. All rights reserved.
//

import UIKit
import CoreData
import Alamofire


struct RemoteRPComment: Codable {
    var id:String
    var message:String
}


class ViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    var comments: [NSManagedObject] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        title = "Comment List"
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")

    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        
        let managedContext = appDelegate.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "RPComment")
        
        do {
            comments = try managedContext.fetch(fetchRequest)
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
    }

    @IBAction func addName(_ sender: UIBarButtonItem) {
        let alert = UIAlertController(title: "New Comment", message: "Add a new comment", preferredStyle: .alert)
        
        let saveAction = UIAlertAction(title: "Save", style: .default) { [unowned self] action in
            
            guard let textField = alert.textFields?.first,
                let nameToSave = textField.text else {
                    return
            }
            
            self.save(name: nameToSave)
            self.tableView.reloadData()
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        alert.addTextField()
        alert.addAction(saveAction)
        alert.addAction(cancelAction)
        
        present(alert, animated: true)
    }
    
    func save(name: String) {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        
        let managedContext = appDelegate.persistentContainer.viewContext
        let entity = NSEntityDescription.entity(forEntityName: "RPComment", in: managedContext)!
        let comment = NSManagedObject(entity: entity, insertInto: managedContext)
        comment.setValue(name, forKeyPath: "message")
        
        do {
            
            //RobotsAndPecils
            //Save to remote store here - mimic storage to local storage
            saveAllCommentsToRemote(completion: {_ in
                print("Saved to remote store")
            })
            try managedContext.save()
            comments.append(comment)
        } catch let error as NSError {
            print("Could not save. \(error), \(error.userInfo)")
        }
    }
    
    // With Alamofire
    func saveAllCommentsToRemote(completion: @escaping ([RemoteRPComment]?) -> Void) {
        guard let url = URL(string: "http://rpassessment/comments/") else {
            completion(nil)
            return
        }
        
        let parameters: Parameters = [
            "comments": comments,
        ]

        Alamofire.request(url,
                           method: .post,
                           parameters: parameters).validate().responseJSON { response in
                guard response.result.isSuccess else {
                    print("Error while saving comments to remote store: \(String(describing: response.result.error))")
                    
                        completion(nil)
                    return
                }
                            
                //Successfully saved comments
                
        }
    }

}

// MARK: - UITableViewDataSource
extension ViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return comments.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let comment = comments[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        cell.textLabel?.text = comment.value(forKeyPath: "message") as? String
        return cell
    }
}
