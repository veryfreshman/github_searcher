//
//  Network.swift
//  Github Searcher
//
//  Created by Ivan Komar on 9/6/19.
//  Copyright © 2019 Ivan Komar. All rights reserved.
//

import UIKit

protocol NetworkRequest {
    associatedtype DataType
    
    func startRequest(withCompletion completion: @escaping (DataType?) -> Void)
    
    func decode(_ data: Data) -> DataType?
    
}

extension NetworkRequest {
    func startRequest(_ url: URL, withCompletion completion: @escaping (DataType?) -> Void) {
        let task = URLSession.shared.dataTask(with: url, completionHandler: {(data:Data?, response: URLResponse?, error: Error?) in
            guard let data = data else {
                completion(nil)
                return
            }
            completion(self.decode(data))
        })
        task.resume()
    }
    
    func appendSecretKey(to url:URL, inAddition:Bool) -> URL {
        let client_id = "6ec56fe12a23b71d82a7"
        let client_secret = "3b61d2954a672af9b22dad18134cc1220c124f6e"
        let path = "client_id=\(client_id)&client_secret=\(client_secret)"
        let final_string = url.absoluteString + (inAddition ? "&\(path)" : "?\(path)")
        let final_url = URL(string: final_string)!
        return final_url
    }
}

class ImageRequest : NetworkRequest {
    
    var url:URL
    
    init(url:URL) {
        self.url = url
    }
    
    func startRequest(withCompletion completion: @escaping (UIImage?) -> Void) {
        startRequest(url, withCompletion: completion)
    }
    
    func decode(_ data: Data) -> UIImage? {
        return UIImage(data: data)
    }
    
}

class ReposSearchRequest: NetworkRequest {
    var url_string = "https://api.github.com/search/repositories?q="
    var url:URL
    
    init(query:String,userName:String) {
        url_string = url_string + query
        url_string.append("+user:\(userName)")
        let url_enc = url_string.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        if let url_encoded = url_enc {
            url = URL(string: url_encoded)!
        }
        else {
            url = URL(string: url_string)!
        }
    }
    
    func startRequest(withCompletion completion: @escaping ([GithubRepoResult]?) -> Void) {
        url = appendSecretKey(to: url, inAddition: true)
        startRequest(url, withCompletion: completion)
    }
    
    func decode(_ data: Data) -> [GithubRepoResult]? {
        let repos_response = try? JSONDecoder().decode(GithubReposSearchResponseModel.self, from: data)
        var repos_result:[GithubRepoResult] = []
        if let repos = repos_response {
            if let items = repos.items {
                for item in items {
                    let repo = GithubRepoResult(name: item.name, stars: item.stargazers_count, forks: item.forks_count, html_url: item.html_url)
                    repos_result.append(repo)
                }
            }
        }
        return repos_result
    }
}

class UsersSearchRequest: NetworkRequest {
    var url_string = "https://api.github.com/search/users?q="
    var url:URL
    
    init(query:String) {
        url_string = url_string + query
        let url_enc = url_string.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        if let url_encoded = url_enc {
            url = URL(string: url_encoded)!
        }
        else {
            url = URL(string: url_string)!
        }
    }
    
    func startRequest(withCompletion completion: @escaping ([GithubSearchUserModel]?) -> Void) {
        
        url = appendSecretKey(to: url, inAddition: true)
        print("final url")
        print(url)
        startRequest(url, withCompletion: completion)
    }
    
    func decode(_ data: Data) -> [GithubSearchUserModel]? {
        let user_search_result = try? JSONDecoder().decode(GithubUserSearchResponseModel.self, from: data)
        var users_profiles:[GithubSearchUserModel] = []
        if let result = user_search_result {
            if let items = result.items {
                for item in items {
                    users_profiles.append(item)
                }
            }
        }
        return users_profiles
    }
}

class UserProfileRequest : NetworkRequest {
    var url:URL
    
    init(url:URL) {
        self.url = url
    }
    
    func startRequest(withCompletion completion: @escaping (GithubUserModel?) -> Void) {
        url = appendSecretKey(to: url, inAddition: false)
        startRequest(url, withCompletion: completion)
    }
    
    func decode(_ data: Data) -> GithubUserModel? {
        var user:GithubUserModel?
        do {
            user = try JSONDecoder().decode(GithubUserModel.self, from: data)
        }
        catch let error {
            print("err")
            print(error)
        }
        
        print("decoded user profie")
        print(user)
        return user
    }
    
}

class UserReposRequest: NetworkRequest {
    var url:URL
    
    init(url:URL) {
        self.url = url
    }
    
    func startRequest(withCompletion completion: @escaping ([GithubRepoResult]?) -> Void) {
        url = appendSecretKey(to: url, inAddition: false)
        startRequest(url, withCompletion: completion)
    }
    
    func decode(_ data: Data) -> [GithubRepoResult]? {
        let repos_response = try? JSONDecoder().decode([GithubReposModel].self, from: data)
        var repos_result:[GithubRepoResult] = []
        if let repos = repos_response {
            for repo in repos {
                let repo = GithubRepoResult(name: repo.name, stars: repo.stargazers_count, forks: repo.forks_count, html_url: repo.html_url)
                repos_result.append(repo)
            }
        }
        return repos_result
    }
}
