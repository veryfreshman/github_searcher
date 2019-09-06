//
//  ViewController.swift
//  Github Searcher
//
//  Created by Ivan Komar on 9/6/19.
//  Copyright © 2019 Ivan Komar. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UISearchBarDelegate, UITableViewDelegate, UITableViewDataSource {
    
    var usersModel:[GithubUserSearchResult] = []

    
    @IBOutlet var search_bar:UISearchBar!
    @IBOutlet var search_table_view:UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()
        search_bar.delegate = self
        search_bar.placeholder = "Search for users"
        search_table_view.delegate = self
        search_table_view.dataSource = self
        search_table_view.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 30, right: 0)
        search_table_view.contentInsetAdjustmentBehavior = .never
        search_table_view.register(UINib(nibName: "user_search_cell", bundle: nil), forCellReuseIdentifier: "user_cell")
        let keyboardToolbar = UIToolbar()
        keyboardToolbar.sizeToFit()
        let flexBarButton = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let doneBarButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(ViewController.donePressed(sender:)))
        keyboardToolbar.items = [flexBarButton, doneBarButton]
        search_bar.inputAccessoryView = keyboardToolbar
    }
    
    @objc func donePressed(sender: UIBarButtonItem) {
        search_bar.resignFirstResponder()
        search_bar.endEditing(true)
        //initiateSearchWithQuery(search_bar.text!)
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        search_bar.resignFirstResponder()
        search_bar.endEditing(true)
        initiateSearchWithQuery(searchBar.text!)
    }
    
    func setReposNumber(_ reposNumber: Int, at indexPath: IndexPath) {
        if indexPath.section < usersModel.count - 1 {
            usersModel[indexPath.section].repo_number = reposNumber
        }
        if let cell = search_table_view.cellForRow(at: indexPath) as? UserSearchCell {
            cell.repos.text = "Repo: \(reposNumber)"
        }
    }
    
    func initiateSearchWithQuery(_ qu:String) {
        let q = qu.trimmingCharacters(in: .whitespacesAndNewlines)
        if q.count > 0 {
            usersModel = []
            search_table_view.reloadData()
            let users_search_request = UsersSearchRequest(query: q)
            users_search_request.startRequest(withCompletion: {(users:[GithubSearchUserModel]?) in
                if let us = users {
                    for user in us {
                        DispatchQueue.main.async {
                            let user_res = GithubUserSearchResult(avatar_url: user.avatar_url, username: user.login, repo_number: nil, login: user.login, url: user.url)
                            self.usersModel.append(user_res)
                        }
                    }
                    DispatchQueue.main.async {
                        self.search_table_view.reloadData()
                    }
                }
                else {
                    DispatchQueue.main.async {
                        NotificationCenter.default.post(name: NSNotification.Name("search_error"), object: nil)
                    }
                }
            })
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return usersModel.count
    } 
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let user_cell = tableView.dequeueReusableCell(withIdentifier: "user_cell") as? UserSearchCell {
            user_cell.layer.cornerRadius = UIData.TABLE_CELL_CORNER_RADIUS
            user_cell.layer.masksToBounds = true
            return user_cell
        }
        return UITableViewCell()
    }
    
    func setImage(_ image:UIImage?, toIndexPath:IndexPath) {
        if let img = image {
            if let cell = search_table_view.cellForRow(at: toIndexPath) as? UserSearchCell {
                cell.setImage(img)
            }
        }
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if let user_cell = cell as? UserSearchCell {
            let avatar_url_string = usersModel[indexPath.section].avatar_url
            if let userImage = GithubCache.cache_shared.object(forKey:avatar_url_string  as NSString) {
                user_cell.setImage(userImage)
            }
            else {
                user_cell.avatar.image = nil
                if let avatar_url = URL(string: avatar_url_string) {
                    let image_request = ImageRequest(url: avatar_url)
                    image_request.startRequest(withCompletion: {(img:UIImage?) in
                        DispatchQueue.main.async {
                            self.setImage(img, toIndexPath: indexPath)
                            if let im = img {
                                GithubCache.cache_shared.setObject(im, forKey: avatar_url_string as NSString)
                            }
                        }
                    })
                }
            }
            if let repo_number = usersModel[indexPath.section].repo_number {
                user_cell.repos.text = "Repo: \(repo_number)"
            }
            else {
                let user_request = UserProfileRequest(url: URL(string: usersModel[indexPath.section].url)!)
                user_request.startRequest(withCompletion: {(user:GithubUserModel?) in
                    if let us = user {
                        DispatchQueue.main.async {
                            self.setReposNumber(us.public_repos, at: indexPath)
                        }
                    }
                })
            }
            let username = usersModel[indexPath.section].login
            user_cell.username.text = "\(username)"
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UIData.USER_CELL_HEIGHT
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let v = UIView()
        v.backgroundColor = UIColor.clear
        return v
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return UIData.TABLE_CELL_SPACING
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let profile_vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "profile_vc") as? GithubProfileViewController
        if let profile = profile_vc {
            navigationController?.pushViewController(profile, animated: true)
            profile.setupWithUserModel(usersModel[indexPath.section])
            profile.navigationItem.title = usersModel[indexPath.section].login
        }
    }


}

