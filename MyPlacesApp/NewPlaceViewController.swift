//
//  NewPlaceViewController.swift
//  MyPlacesApp
//
//  Created by  Aleksandr Afrikanov on 04.03.2021.
//

import UIKit

class NewPlaceViewController: UITableViewController {

    @IBOutlet weak var placeImage: UIImageView!
    @IBOutlet weak var placeLabel: UITextField!
    @IBOutlet weak var placeLocation: UITextField!
    @IBOutlet weak var placeType: UITextField!
    @IBOutlet weak var saveButton: UIBarButtonItem!
    @IBOutlet weak var starsStackView: StarStackView!
    @IBOutlet weak var mapButton: UIButton!
    
    var photoChanged = false
    var placeToEdit: Place?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.tableFooterView = UIView()
        placeLabel.delegate = self
        placeLocation.delegate = self
        placeType.delegate = self
        self.saveButton.isEnabled = false
        self.mapButton.isEnabled = false
        
        if self.placeToEdit != nil {
            self.setupContent()
            self.setupNavigationBar()
        }
        mapButton.layer.cornerRadius = mapButton.frame.height / 2
        
        placeLabel.addTarget(self, action: #selector(placeLabelChanged), for: .editingChanged)
        placeLocation.addTarget(self, action: #selector(placeLocationChanged), for: .editingChanged)
        
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row == 0 {
            let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            
            let cameraIcon = #imageLiteral(resourceName: "camera")
            let cameraAction = UIAlertAction(title: "Camera", style: .default, handler: { _ in
                self.chooseImage(.camera)
            })
            cameraAction.setValue(cameraIcon, forKey: "image")
            cameraAction.setValue(CATextLayerAlignmentMode.left, forKey: "titleTextAlignment")
            
            let photoIcon = #imageLiteral(resourceName: "photo")
            let photoAction = UIAlertAction(title: "Photo", style: .default, handler: { _ in
                self.chooseImage(.photoLibrary)
            })
            photoAction.setValue(photoIcon, forKey: "image")
            photoAction.setValue(CATextLayerAlignmentMode.left, forKey: "titleTextAlignment")
            
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
            
            alert.addAction(cameraAction)
            alert.addAction(photoAction)
            alert.addAction(cancelAction)
            
            present(alert, animated: true)
        } else {
            self.view.endEditing(true)
        }
    }
    
    func setupContent() {
        guard self.placeToEdit != nil else {
            return
        }
        self.placeLabel.text = self.placeToEdit?.name
        self.placeImage.image = UIImage(data: (self.placeToEdit?.imageData)!)
        self.placeImage.contentMode = .scaleAspectFill
        self.placeType.text = self.placeToEdit?.type
        self.placeLocation.text = self.placeToEdit?.location
        self.starsStackView.currentRating = self.placeToEdit!.rating
        self.mapButton.isEnabled = true
    }
    
    func setupNavigationBar() {
        self.navigationItem.leftBarButtonItem = nil
        if let topItem = self.navigationController?.navigationBar.topItem {
            topItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        }
        self.title = self.placeToEdit?.name
        self.saveButton.isEnabled = true
    }
    
    func saveNewPlace() {
        var imageData: Data!
        
        if self.placeToEdit != nil {
            self.photoChanged = true
        }
        
        if self.photoChanged {
            imageData = self.placeImage.image?.pngData()
        } else {
            imageData = UIImage(named: "imagePlaceholder")?.pngData()
        }
        
        let place = Place(name: self.placeLabel.text!, location: self.placeLocation.text, type: self.placeType.text, imageData: imageData, rating: starsStackView.currentRating)
        
        if self.placeToEdit != nil {
            StorageManager.editObject(place, placeToEdit!)
        } else {
            StorageManager.saveObject(place)
        }
    }
    
    @IBAction func cancelAction(_ sender: Any) {
        dismiss(animated: true)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "openMapAction" {
            guard let mapVC = segue.destination as? MapViewController else {
                return
            }
            var imageData: Data!
            
            if self.placeToEdit != nil {
                self.photoChanged = true
            }
            
            if self.photoChanged {
                imageData = self.placeImage.image?.pngData()
            } else {
                imageData = UIImage(named: "imagePlaceholder")?.pngData()
            }
            let place = Place(name: self.placeLabel.text!, location: self.placeLocation.text, type: self.placeType.text, imageData: imageData, rating: starsStackView.currentRating)
            mapVC.place = place
        }
    }
}

// MARK: TextField

extension NewPlaceViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    @objc func placeLabelChanged() {
        if self.placeLabel.text?.isEmpty == true {
            self.saveButton.isEnabled = false
        } else {
            self.saveButton.isEnabled = true
        }
    }
    
    @objc func placeLocationChanged() {
        if self.placeLocation.text?.isEmpty == true {
            self.mapButton.isEnabled = false
        } else {
            self.mapButton.isEnabled = true
        }
    }
    
}

// MARK: Image

extension NewPlaceViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate  {
    
    func chooseImage(_ sourceType: UIImagePickerController.SourceType) {
        if UIImagePickerController.isSourceTypeAvailable(sourceType) {
            let controller = UIImagePickerController()
            controller.delegate = self
            controller.allowsEditing = true
            controller.sourceType = sourceType
            present(controller, animated: true)
        }
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        self.placeImage.image = info[.editedImage] as? UIImage
        self.placeImage.contentMode = .scaleAspectFill
        self.placeImage.clipsToBounds = true
        self.photoChanged = true
        dismiss(animated: true)
    }
    
}
