//
//  MainViewController.swift
//  MyPlacesApp
//
//  Created by  Aleksandr Afrikanov on 04.03.2021.
//

import UIKit
import RealmSwift

class MainViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    
    var searchController = UISearchController(searchResultsController: nil)
    var ascendingOrder = true
    var searchBarIsEmpty: Bool {
        guard let text = self.searchController.searchBar.text else {
            return false
        }
        return text.isEmpty
    }
    var isFiltering: Bool {
        return self.searchController.isActive && !self.searchBarIsEmpty
    }
    var places: Results<Place>!
    var filteredPlaces: Results<Place>?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        places = realm.objects(Place.self)
        
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search"
        navigationItem.searchController = searchController
        self.definesPresentationContext = true
        self.extendedLayoutIncludesOpaqueBars = true
    }

    // MARK: - Table view data source

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.isFiltering ? filteredPlaces!.count : places.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "placeCell", for: indexPath) as! CustomTableViewCell

        let place = self.isFiltering ? filteredPlaces![indexPath.row] : places[indexPath.row]

        cell.placeName?.text = place.name
        cell.placeLocation?.text = place.location
        cell.placeType?.text = place.type
        cell.placeImage?.image = UIImage(data: place.imageData!)
        
        cell.placeImage?.layer.cornerRadius = (cell.placeImage?.frame.height)! / 2
        cell.placeImage?.clipsToBounds = true

        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 85
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let place = self.isFiltering ? filteredPlaces![indexPath.row] : places[indexPath.row]
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
            let place = self.isFiltering ? filteredPlaces![indexPath.row] : places[indexPath.row]
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
    
    // MARK: sorting
    
    @IBAction func changeSortingOrder(_ sender: UIBarButtonItem) {
        self.ascendingOrder.toggle()
        
        if self.ascendingOrder {
            sender.image = UIImage(named: "ZA")
        } else {
            sender.image = UIImage(named: "AZ")
        }
        guard let segmentTitle = self.segmentedControl.titleForSegment(at: self.segmentedControl.selectedSegmentIndex) else {
            return
        }
        self.places = self.places.sorted(byKeyPath: segmentTitle.lowercased(), ascending: self.ascendingOrder)
        self.tableView.reloadData()
    }
    
    @IBAction func changeSortingValue(_ sender: UISegmentedControl) {
        guard let segmentTitle = self.segmentedControl.titleForSegment(at: self.segmentedControl.selectedSegmentIndex) else {
            return
        }
        self.places = self.places.sorted(byKeyPath: segmentTitle.lowercased(), ascending: self.ascendingOrder)
        self.tableView.reloadData()
    }
}

// MARK: UISearchController

extension MainViewController : UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        filterContentForSearchText(searchController.searchBar.text!)
    }
    
    func filterContentForSearchText(_ text: String) {
        self.filteredPlaces = places.filter("name CONTAINS[c] %@ or location CONTAINS[c] %@", text, text)
        self.tableView.reloadData()
    }
}
