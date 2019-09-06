//
//  SearchModel.swift
//  Github Searcher
//
//  Created by Ivan Komar on 9/6/19.
//  Copyright © 2019 Ivan Komar. All rights reserved.
//

import UIKit

class GithubCache {
    static let cache_shared = NSCache<NSString,UIImage>()

}

struct GithubUserSearchResponseModel: Codable {
    var items:[GithubSearchUserModel]?
}

struct GithubReposSearchResponseModel: Codable {
    var items:[GithubSearchRepoModel]?
}

struct GithubSearchRepoModel: Codable {
    var name:String
    var stargazers_count:Int
    var forks_count:Int
    var html_url:String
}

struct GithubUserSearchResult {
    var avatar_url:String
    var username:String
    var repo_number:Int?
    var login:String
    var url:String
}

struct GithubUserProfile {
    var login:String
    var avatar_url:String
    var email:String?
    var location:String?
    var bio:String?
    var following:Int
    var followers:Int
    var created_at:String
    var repos:[GithubRepoResult]
}

struct GithubRepoResult {
    var name:String
    var stars:Int
    var forks:Int
    var html_url:String
}

struct GithubSearchUserModel: Codable {
    var login:String
    var avatar_url:String
    var url:String
}

struct GithubUserModel: Codable {
    var login:String
    var avatar_url:String
    var url:String
    var email:String?
    var location:String?
    var bio:String?
    var following:Int
    var followers:Int
    var created_at:String
    var public_repos:Int
    var repos_url:String
}

struct GithubReposModel: Codable {
    var name:String
    var forks_count:Int
    var stargazers_count:Int
    var html_url:String
}
