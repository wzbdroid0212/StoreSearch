//
//  Search.swift
//  StoreSearch
//
//  Created by wuzhengbin on 2019/7/9.
//  Copyright © 2019 wuzhengbin. All rights reserved.
//

import Foundation
import UIKit

typealias SearchComplete = (Bool) -> Void

class Search {
    
    enum Category: Int {
        case all = 0
        case music = 1
        case software = 2
        case ebooks = 3
        
        var type: String {
            switch self {
            case .all: return ""
            case .music: return NSLocalizedString("musicTrack", comment:"Localized kind: musicTrack")
            case .software: return NSLocalizedString("software", comment:"Localized kind: software")
            case .ebooks: return NSLocalizedString("ebook", comment:"Localized kind: ebook")
            }
        }
    }
    
    // 定义一个搜索的状态的枚举
    enum State {
        case notSearchedYet
        case loading
        case noResults
        case results([SearchResult]) // 该枚举比较特殊，绑定了一个数组
    }
    private(set) var state: State = .notSearchedYet
    private var dataTask: URLSessionDataTask? = nil
    
    func performSearch(for text: String, category: Category, completion: @escaping SearchComplete) {
        if !text.isEmpty {
            dataTask?.cancel()
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
            
            state = .loading
            
            let url = iTunesURL(searchText: text, category: category)
            let session = URLSession.shared
            dataTask = session.dataTask(with: url, completionHandler: { data, response, error in
                
                var newState = State.notSearchedYet
                
                var success = false
                
                if let error = error as NSError?, error.code == -999 {
                    return
                }
                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200, let data = data {
                    
                    var searchResults = self.parse(data: data)
                    if searchResults.isEmpty {
                        newState = .noResults
                    } else {
                        searchResults.sort(by: { (result1, result2) -> Bool in
                            result1.name.localizedStandardCompare(result2.name) == .orderedAscending
                        })
                        newState = .results(searchResults)
                    }
                    success = true
                }
                
                DispatchQueue.main.async {
                    self.state = newState
                    completion(success)
                    UIApplication.shared.isNetworkActivityIndicatorVisible = false
                }
            })
            dataTask?.resume()
        }
    }
    
    private func iTunesURL(searchText: String, category: Category) -> URL {
        let kind = category.type
        let encodedText = searchText.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!
        let urlString = "https://itunes.apple.com/search?" + "term=\(encodedText)&entity=\(kind)&country=cn&limit=200"
        
        let url = URL(string: urlString)
        return url!
    }
    
    private func parse(data: Data) -> [SearchResult] {
        do {
            let decoder = JSONDecoder()
            let result = try decoder.decode(ResultArray.self, from: data)
            return result.results
        } catch {
            print("JSON Error: \(error)")
            return []
        }
    }

}
