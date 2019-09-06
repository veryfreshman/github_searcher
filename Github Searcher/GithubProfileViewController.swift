//
//  GithubProfileViewController.swift
//  Github Searcher
//
//  Created by Ivan Komar on 9/6/19.
//  Copyright © 2019 Ivan Komar. All rights reserved.
//

import UIKit

class GithubProfileViewController: UIViewController, UISearchBarDelegate, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet var repo_search_bar:UISearchBar!
    @IBOutlet var username:UILabel!
    @IBOutlet var avatar:UIImageView!
    @IBOutlet var email:UILabel!
    @IBOutlet var location:UILabel!
    @IBOutlet var join_date:UILabel!
    @IBOutlet var followers:UILabel!
    @IBOutlet var following:UILabel!
    @IBOutlet var bior:UILabel!
    @IBOutlet var repo_search_table_view:UITableView!
    
    var currentModel:GithubUserSearchResult?
    var currentUser:GithubUserModel?
    var currentRepos:[GithubRepoResult] = []
    var defaultRepos:[GithubRepoResult] = []
    var view_ready:Bool = false
    var view_layout_finished:Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        repo_search_bar.delegate = self
        repo_search_bar.placeholder = "Search for repos"
        repo_search_table_view.delegate = self
        repo_search_table_view.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 30, right: 0)
        repo_search_table_view.contentInsetAdjustmentBehavior = .never
        repo_search_table_view.dataSource = self
        repo_search_table_view.register(UINib(nibName: "repo_search_cell", bundle: nil), forCellReuseIdentifier: "repo_cell")
        let keyboardToolbar = UIToolbar()
        keyboardToolbar.sizeToFit()
        let flexBarButton = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let doneBarButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(GithubProfileViewController.donePressed(sender:)))
        keyboardToolbar.items = [flexBarButton, doneBarButton]
        repo_search_bar.inputAccessoryView = keyboardToolbar
    }
    
    @objc func donePressed(sender:UIBarButtonItem) {
        repo_search_bar.resignFirstResponder()
        repo_search_bar.endEditing(true)
        if let query = repo_search_bar.text {
            let trimmed_query = query.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed_query.count == 0 {
                currentRepos = defaultRepos
                repo_search_table_view.reloadData()
            }
        }
        //initiateSearchWithQuery(repo_search_bar.text!)
    }
    
    func initiateSearchWithQuery(_ qu:String) {
        if let model = currentModel {
            let q = qu.trimmingCharacters(in: .whitespacesAndNewlines)
            if q.count == 0 {
                currentRepos = defaultRepos
                repo_search_table_view.reloadData()
            }
            else {
                currentRepos = []
                repo_search_table_view.reloadData()
                let repos_search_request = ReposSearchRequest(query: q, userName: model.login)
                repos_search_request.startRequest(withCompletion: {(result:[GithubRepoResult]?) in
                    if let repos = result {
                        for repo in repos {
                            DispatchQueue.main.async {
                                self.currentRepos.append(repo)
                            }
                        }
                        DispatchQueue.main.async {
                            self.repo_search_table_view.reloadData()
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
    }
    
    func setupWithUserModel(_ userModel: GithubUserSearchResult) {
        currentModel = userModel
        installData()
        loadDefaultData()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        view_ready = true
        if !view_layout_finished {
            installData()
        }
        view_layout_finished = true
        
    }
    
    func loadDefaultData() {
        if let model = currentModel {
            let user_request = UserProfileRequest(url: URL(string: model.url)!)
            user_request.startRequest(withCompletion: {(user:GithubUserModel?) in
                self.currentUser = user
                DispatchQueue.main.async {
                    self.installData()
                }
                if let us = user {
                    let repos_request = UserReposRequest(url: URL(string: us.repos_url)!)
                    repos_request.startRequest(withCompletion: {(result:[GithubRepoResult]?) in
                        if let repos = result {
                            for repo in repos {
                                DispatchQueue.main.async {
                                    self.currentRepos.append(repo)
                                }
                            }
                            DispatchQueue.main.async {
                                for repo in self.currentRepos {
                                    self.defaultRepos.append(repo)
                                }
                                self.repo_search_table_view.reloadData()
                            }
                        }
                        else {
                            //showing error
                        }
                    })
                }
                else {
                    DispatchQueue.main.async {
                        NotificationCenter.default.post(name: NSNotification.Name("user_error"), object: nil)
                    }
                }
            })
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return currentRepos.count
    }
    
    
    func installData() {
        if let profile = currentUser {
            username.text = profile.login
            email.text = profile.email ?? "Email is not available"
            location.text = profile.location ?? "Location is not available"
            let creation_string = profile.created_at
            let date_formatter = DateFormatter()
            date_formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
            let date = date_formatter.date(from: creation_string)
            let calendar = Calendar.current
            var final_date:String?
            if let dt = date {
                let comp = calendar.dateComponents([.year,.month,.day], from: dt)
                final_date = "Created at: "
                if let day = comp.day {
                    final_date!.append("\(day) ")
                }
                if let month = comp.month {
                    final_date!.append("\(month) ")
                }
                if let year = comp.year {
                    final_date!.append("\(year)")
                }
            }
            join_date.text = final_date ?? "Created at: \(profile.created_at)"
            followers.text = "\(profile.followers) followers"
            following.text = "Following \(profile.following)"
            bior.text = profile.bio ?? "Bio is not available"
            let avatar_url_string = profile.avatar_url
            if let userImage = GithubCache.cache_shared.object(forKey:avatar_url_string as NSString) {
                setImage(userImage)
            }
            else {
                if let avatar_url = URL(string: avatar_url_string) {
                    let image_request = ImageRequest(url: avatar_url)
                    image_request.startRequest(withCompletion: {(img:UIImage?) in
                        DispatchQueue.main.async {
                            self.setImage(img)
                            if let im = img {
                                GithubCache.cache_shared.setObject(im, forKey: avatar_url_string as NSString)
                            }
                        }
                    })
                }
            }
        }
        else if let model = currentModel {
            if view_ready {
                username.text = model.login
                let avatar_url_string = model.avatar_url
            }
        }
    }
    
    func setImage(_ image:UIImage?) {
        self.avatar.image = image
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        repo_search_bar.resignFirstResponder()
        repo_search_bar.endEditing(true)
        initiateSearchWithQuery(searchBar.text!)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return UIData.TABLE_CELL_SPACING
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let v = UIView()
        v.backgroundColor = UIColor.clear
        return v
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let repo_cell = tableView.dequeueReusableCell(withIdentifier: "repo_cell") as? RepoSearchCell {
            repo_cell.layer.cornerRadius = UIData.TABLE_CELL_CORNER_RADIUS
            repo_cell.layer.masksToBounds = true
            return repo_cell
        }
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if let repo_cell = cell as? RepoSearchCell {
            repo_cell.username.text = currentRepos[indexPath.section].name
            repo_cell.forks.text = "\(currentRepos[indexPath.section].forks) forks"
            repo_cell.stars.text = "\(currentRepos[indexPath.section].stars) stars"
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let repo = currentRepos[indexPath.section]
        if let repo_url = URL(string: repo.html_url) {
            UIApplication.shared.open(repo_url, options: [:], completionHandler: nil)
        }
        
    }
    
}

