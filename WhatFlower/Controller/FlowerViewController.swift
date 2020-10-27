//
//  ViewController.swift
//  WhatFlower
//
//  Created by Eliu Efraín Díaz Bravo on 12/10/20.
//

import UIKit
import CoreML
import Vision

class FlowerViewController: UIViewController, UINavigationControllerDelegate {
    
    let imagePicker = UIImagePickerController()
    var flowerManager = FlowerManager()
    
    lazy var flowerImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.backgroundColor = .white
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        return imageView
    }()
    
    lazy var flowerTextLabel: UILabel = {
        let textLabel = UILabel()
        textLabel.translatesAutoresizingMaskIntoConstraints = false
        textLabel.text = "Flowers!"
        textLabel.lineBreakMode = .byWordWrapping
        textLabel.numberOfLines = 0
        textLabel.textColor = .white
        return textLabel
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        setupContsraints()
        setupNavigationBar()
        setupImagePicker()
        view.backgroundColor = .systemGreen
        flowerManager.delegate = self
    }
    
    private func setupViews() {
        view.addSubview(flowerImageView)
        view.addSubview(flowerTextLabel)
    }
    
    private func setupContsraints() {
        let safeArea = view.safeAreaLayoutGuide
        
        NSLayoutConstraint.activate([
            flowerImageView.topAnchor.constraint(equalTo: safeArea.topAnchor),
            flowerImageView.bottomAnchor.constraint(equalTo: view.centerYAnchor),
            flowerImageView.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor),
            flowerImageView.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor),
        
            flowerTextLabel.topAnchor.constraint(equalTo: flowerImageView.bottomAnchor, constant: 50),
            flowerTextLabel.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor, constant: -35),
            flowerTextLabel.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor, constant: 35),
            flowerTextLabel.bottomAnchor.constraint(equalTo: safeArea.bottomAnchor, constant: -20),
            
        ])
    }
    
    private func setupNavigationBar() {
        title = "WhatFlower?"
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .camera, target: self, action: #selector(cameraTapped))
        navigationController?.navigationBar.tintColor = .white
        navigationController?.navigationBar.barTintColor = .systemGreen
        navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white ]
    }
    
    @objc private func cameraTapped() {
        present(imagePicker, animated: true, completion: nil)
    }
    
    private func setupImagePicker() {
        imagePicker.delegate = self
        imagePicker.allowsEditing = true
        imagePicker.sourceType = .camera
    }
}

//MARK: - UIImagePickerControllerDelegate

extension FlowerViewController: UIImagePickerControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let userPickedImage = info[.editedImage] as? UIImage {
            
            guard let ciPickedImage = CIImage(image: userPickedImage) else {
                fatalError("Could not convert image to CIImage.")
            }
            
            detect(ciimage: ciPickedImage)
        }
        imagePicker.dismiss(animated: true, completion: nil)
    }
    
    func detect(ciimage: CIImage) {
        guard let flowerClassifierModel = try? VNCoreMLModel(for: FlowerClassifier(configuration: .init()).model) else {
            fatalError("Could not setup CoreML model.")
        }
        
        let request = VNCoreMLRequest(model: flowerClassifierModel) { (request, error) in
            // Executed once the request is "competed"
            guard let classification = request.results as? [VNClassificationObservation] else {
                fatalError("Model failed to process image.")
            }
            
            if let firstItem = classification.first {
                let flowerFound = firstItem.identifier
                self.flowerManager.fetchFlower(flowerName: flowerFound)
                self.title = flowerFound.capitalized
            }
        }
        
        let handler = VNImageRequestHandler(ciImage: ciimage)
        
        do {
            try handler.perform([request])
        } catch {
            print(error)
        }
        
    }
}

//MARK: - FlowerManagerDelegate

extension FlowerViewController: FlowerManagerDelegate {
    func didFindFlower(_ flower: FlowerModel) {
        DispatchQueue.main.async {
            self.flowerTextLabel.text = flower.extract
            self.flowerImageView.load(url: flower.imageURL)
        }
    }
    
    func didFailwithError(_ error: Error) {
        print(error)
    }
    
    
}

extension UIImageView {
    func load(url: URL) {
        DispatchQueue.global().async { [weak self] in
            if let data = try? Data(contentsOf: url) {
                if let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        self?.image = image
                    }
                }
            }
        }
    }
}
