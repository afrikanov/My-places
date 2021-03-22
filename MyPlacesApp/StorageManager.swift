//
//  StorageManager.swift
//  MyPlacesApp
//
//  Created by  Aleksandr Afrikanov on 16.03.2021.
//

import Foundation
import RealmSwift

let realm = try! Realm()

class StorageManager {
    
    static func saveObject(_ place: Place) {
        try! realm.write {
            realm.add(place)
        }
    }
    
    static func deleteObject(_ place: Place) {
        try! realm.write {
            realm.delete(place)
        }
    }
    
    static func editObject(_ placeNew: Place, _ placeToEdit: Place) {
        try! realm.write {
            placeToEdit.name = placeNew.name
            placeToEdit.type = placeNew.type
            placeToEdit.location = placeNew.location
            placeToEdit.imageData = placeNew.imageData
            placeToEdit.rating = placeNew.rating
        }
    }
}
