//
//  FlowerManager.swift
//  WhatFlower
//
//  Created by Eliu Efraín Díaz Bravo on 22/10/20.
//

import Foundation

protocol FlowerManagerDelegate {
    func didFindFlower(_ flower: FlowerModel)
    func didFailwithError(_ error: Error)
}

struct FlowerManager {
    let url = "https://en.wikipedia.org/w/api.php?format=json&action=query&prop=extracts|pageimages&exintro=&explaintext=&indexpageids&redirects=1&pithumbsize=500"
    
    var delegate: FlowerManagerDelegate?
    
    func fetchFlower(flowerName: String) {
        if let urlString = "\(url)&titles=\(flowerName)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
            performRequest(with: urlString)
        }
    }
    
    func performRequest(with url: String) {
        // 1. Create a URL
        print(url)
        if let url = URL(string: url) {
            // 2. Create a URL session
            let session = URLSession(configuration: .default)
            // 3. Give a session a task
            let task = session.dataTask(with: url) { (data, response, error) in
                if error != nil {
                    self.delegate?.didFailwithError(error!)
                }
                if let safeData = data {
                    if let flower = self.parseJSON(with: safeData) {
                        self.delegate?.didFindFlower(flower)
                    }
                }
            }
            // 4. Start the task
            task.resume()
        } else {
            print("Could not convert string to a proper URL")
        }
    }
    
    func parseJSON(with data: Data) -> FlowerModel? {
        let decoder = JSONDecoder()
        var decodedData: FlowerData
        do {
            decodedData = try decoder.decode(FlowerData.self, from: data)
            print(decodedData)
            let pageIds = Int(decodedData.query.pageids[0])!
            let dataPath = decodedData.query.pages[pageIds]
            
            if let title = dataPath?.title, let extract = dataPath?.extract, let imageURL = dataPath?.thumbnail.source {
                guard let finalImageUrl = URL(string: imageURL) else {
                    return nil
                }
                let flower = FlowerModel(title: title, extract: extract, imageURL: finalImageUrl)
                return flower
            } else {
                return nil
            }
        } catch {
            print(error)
            return nil
        }
    }
}
