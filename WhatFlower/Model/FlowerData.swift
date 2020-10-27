//
//  FlowerData.swift
//  WhatFlower
//
//  Created by Eliu Efraín Díaz Bravo on 22/10/20.
//

import Foundation

struct FlowerData: Codable {
    let query: Query
}

struct Query: Codable {
    let pageids: [String]
    let pages: [Int:Pages]
}

struct Pages: Codable {
    let title: String
    let extract: String
    let thumbnail: Thumbnail
}

struct Thumbnail: Codable {
    let source: String
}
