//
//  MainViewController.swift
//  MyPlacesApp
//
//  Created by  Aleksandr Afrikanov on 04.03.2021.
//

import UIKit
import RealmSwift

class MainViewController: UITableViewController {
    
    var places: Results<Place>!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        places = realm.objects(Place.self)
    }

    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return places.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "placeCell", for: indexPath) as! CustomTableViewCell

        let place = places[indexPath.row]

        cell.placeName?.text = place.name
        cell.placeLocation?.text = place.location
        cell.placeType?.text = place.type
        cell.placeImage?.image = UIImage(data: place.imageData!)
        
        cell.placeImage?.layer.cornerRadius = (cell.placeImage?.frame.height)! / 2
        cell.placeImage?.clipsToBounds = true

        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 85
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let place = places[indexPath.row]
        let deleteItem = UIContextualAction(style: .destructive, title: "Delete", handler: { (action, view, boolValue) in
            StorageManager.deleteObject(place)
            tableView.deleteRows(at: [indexPath], with: .automatic)
        })
        return UISwipeActionsConfiguration(actions: [deleteItem])
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "editAction" {
            guard let placeViewController = segue.destination as? NewPlaceViewController else {
                return
            }
            guard let indexPath = self.tableView.indexPathForSelectedRow else {
                return
            }
            let place = places[indexPath.row]
            placeViewController.placeToEdit = place
        } else if segue.identifier == "addAction" {
            
        }
    }
    
    @IBAction func saveAction(_ segue: UIStoryboardSegue) {
        guard let newPlaceViewController = segue.source as? NewPlaceViewController else {
            return
        }
        newPlaceViewController.saveNewPlace()
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
}
