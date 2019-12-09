//
//  GithubUploader.swift
//  uPic
//
//  Created by Svend Jin on 2019/6/29.
//  Copyright © 2019 Svend Jin. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON

class GithubUploader: BaseUploader {
    static let shared = GithubUploader()
    static let fileExtensions: [String] = []
    
    func _upload(_ fileUrl: URL?, fileData: Data?) {
        guard let host = ConfigManager.shared.getDefaultHost(), let data = host.data else {
            super.faild(errorMsg: "There is a problem with the map bed configuration, please check!".localized)
            return
        }
        
        super.start()
        
        let config = data as! GithubHostConfig
        
        let owner = config.owner!
        let repo = config.repo!
        let branch = config.branch!
        let token = config.token!
        let domain = config.domain
        
        let saveKeyPath = config.saveKeyPath
        
        guard let configuration = BaseUploaderUtil.getSaveConfigurationWithB64(fileUrl, fileData, saveKeyPath) else {
            super.faild(errorMsg: "Invalid file")
            return
        }
        let fileBase64 = configuration["fileBase64"] as! String
        let fileName = configuration["fileName"] as! String
        let saveKey = configuration["saveKey"] as! String
        
        
        let url = GithubUtil.getUrl(owner: owner, repo: repo, filePath: saveKey)

        let parameters = GithubUtil.getRequestParameters(branch: branch, filePath: saveKey, b64Content: fileBase64)
        
        var headers = HTTPHeaders()
        headers.add(HTTPHeader.authorization("token \(token)"))
        headers.add(HTTPHeader.contentType("application/json"))
        headers.add(name: "User-Agent", value: "Macos/uPic")
        
        AF.request(url, method: .put, parameters: parameters, encoding: JSONEncoding.default, headers: headers).validate().uploadProgress { progress in
            super.progress(percent: progress.fractionCompleted)
            }.responseJSON(completionHandler: { response -> Void in
                switch response.result {
                case .success(let value):
                    let json = JSON(value)
                    if let errorMessage = json["message"].string {
                        super.faild(errorMsg: errorMessage)
                        return
                    }
                    if domain == nil || domain!.isEmpty {
                        super.completed(url: json["content"]["download_url"].stringValue.urlDecoded(), fileBase64, fileUrl, fileName)
                    } else {
                        super.completed(url: "\(domain!)/\(saveKey)", fileBase64, fileUrl, fileName)
                    }
                case .failure(let error):
                    var errorMsg = error.localizedDescription
                    if let data = response.data {
                        let json = JSON(data)
                        errorMsg = json["message"].stringValue
                    }
                    super.faild(errorMsg: errorMsg)
                }
            })
        
    }
    
    func upload(_ fileUrl: URL) {
        self._upload(fileUrl, fileData: nil)
    }
    
    func upload(_ fileData: Data) {
        self._upload(nil, fileData: fileData)
    }
}