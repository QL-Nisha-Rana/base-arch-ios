//
//  NetworkWrapper.swift
//  BaseProject
//
//  Created by Himanshu Kesharwani on 07/06/23.
//

import Foundation
import SystemConfiguration
import UIKit

class NetworkManager: HTTPClient {
    // MARK: - Properties
    private let service: HTTPServiceProtocol
    private let session: URLSessionProtocol

    // MARK: - Initializer
    init(sessionFactory: URLSessionFactoryProtocol = DefaultURLSessionFactory(), service: HTTPServiceProtocol = DefaultHTTPService()) {
        self.session = sessionFactory.session(for: service, delegate: nil)
        self.service = service
    }
    // MARK: - Methods

    func uploadImageToServer(_ parameter: [String: String], basePath: String, imageData: UIImage?, success: @escaping NetworkSuccessHandler, failure: @escaping NetworkFailureHandler) {
       let parameters = parameter
       guard let mediaImage = Media(withImage: UIImage(), forKey: "image") else { return }
       guard let url = URL(string: basePath) else { return }
       var request = URLRequest(url: url)
       request.httpMethod = "POST"
       // create boundary
       let boundary = generateBoundary()
       // set content type
       request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
       // call createDataBody method
       let dataBody = createDataBody(withParameters: parameters, media: [mediaImage], boundary: boundary)
       request.httpBody = dataBody
       let session = URLSession.shared
       session.dataTask(with: request) { (data, response, error) in
          if let response = response as? HTTPURLResponse {
             print(response)

          }
          if let data = data {
             do {
                let json = try JSONSerialization.jsonObject(with: data, options: [])
                print(json)
                 success(data, response)
             } catch {
                print(error)

             }
          }
       }.resume()
    }

    func fetch(_ request: HTTPRequest, basePath: String, success: @escaping NetworkSuccessHandler, failure: @escaping NetworkFailureHandler) {
        if NetworkReachability.isConnectedToNetwork() {
            debugPrint("Internet Connection Available!")
        } else {
            debugPrint("Internet Connection not Available!")
            failure(nil, nil, .failed(message: "Internet Connection not Available!"))
            return
        }
        guard let urlRequest = request.urlRequest(with: basePath ) else {
            failure(nil, nil, .badRequest)
            return
        }

        debugLog(logType: .info, anyObject: urlRequest, text: "Initiating URL Request")
        session.dataTask(with: urlRequest) { data, response, error in
            if let error = error {
                failure(nil, nil, .failed(message: error.localizedDescription))
                return
            }
            if let httpResponse = response as? HTTPURLResponse {
                // if it is between 200..299
                if (200...299).contains(httpResponse.statusCode) {
                    if let data = data {
                        let json = try? JSONSerialization.jsonObject(with: data)
                        debugLog(logType: .networkResponse, anyObject: json, text: "URL Response")
                        print("\(data)")
                        success(data, response)
                    }
                } else {
                    debugLog(logType: .networkResponse, anyObject: httpResponse.statusCode, text: "Unexpected Network response")
                    failure(nil, httpResponse, .failed(message: "Bad Request"))
                }
            } else {
                // debug log response not received
                debugLog(logType: .error, anyObject: nil, text: "Network response not received.")
            }
        }.resume()
    }

    func fetchJSON<T: Decodable>(_ request: HTTPRequest,
                                 basePath: String,
                                 decodableModelType: T.Type,
                                 completion: @escaping ((Result<T, NetworkError>) -> Void)) {
        if NetworkReachability.isConnectedToNetwork() {
            print("Internet Connection Available!")
        } else {
            print("Internet Connection not Available!")
            completion(.failure(.failed(message: "Internet Connection not Available!")))

            return
        }
        self.fetch(request, basePath: basePath) { data, _ in
            do {
                let decodedObject: GeneralNetworkModel<T> = try JSONDecoder().decode(GeneralNetworkModel.self, from: data)
                if decodedObject.isSuccess {
                    if let data = decodedObject.data {
                        completion(.success(data))
                    }
                } else {

                    completion(.failure(.failed(message: NetworkManager.errorMessageBasedOnStatusCode(decodedObject.code))))
                }
            } catch {
                completion(.failure(.unableToDecodeResponseData(errorDescription: error.localizedDescription)))
            }
        } failure: { _, response, _ in
            if let response = response {
                completion(.failure(.statusCode(statusCode: response.statusCode)))
            } else {
                debugLog(logType: .debug, anyObject: nil, text: "Skipped during optional unwraping ")
            }
        }
    }
}
// MARK: - Error Class
extension NetworkManager {

    /// This function will return the string message based on the error code
    class func errorMessageBasedOnStatusCode(_ code: Int?) -> String {
        let afilepath = Bundle.main.path(forResource: "ErrorCode", ofType: "plist") // Getting error codes from plist file

        var propertyListFormat =  PropertyListSerialization.PropertyListFormat.xml // Format of the Property List.

        let plistXML = FileManager.default.contents(atPath: afilepath!)!

        var plistData: [String: Any] = [:] // Our data

        do {
            // convert the data to a dictionary and handle errors
        plistData = try PropertyListSerialization.propertyList(from: plistXML, options: .mutableContainersAndLeaves, format: &propertyListFormat) as? [String: Any] ?? [:]

            var message = ""
            if let aRoot = (plistData["ErrorCode"] as?  [[String: Any]]) {
                for aObj in aRoot where aObj["Code"] as? Int == code {
                    message = aObj["Message"]  as? String ?? ""
                    break
                }
            }
            return message

        } catch {
            debugPrint("error")
        }
        debugPrint("Error While Creating a Error message from status code")
        return ""
    }
    func createDataBody(withParameters params: [String: String]?, media: [Media]?, boundary: String) -> Data {
       let lineBreak = "\r\n"
       var body = Data()
       if let parameters = params {
          for (key, value) in parameters {
             body.append("--\(boundary + lineBreak)")
             body.append("Content-Disposition: form-data; name=\"\(key)\"\(lineBreak + lineBreak)")
              body.append("\(value + lineBreak)")
          }
       }
       if let media = media {
          for photo in media {
             body.append("--\(boundary + lineBreak)")
             body.append("Content-Disposition: form-data; name=\"\(photo.key)\"; filename=\"\(photo.filename)\"\(lineBreak)")
             body.append("Content-Type: \(photo.mimeType + lineBreak + lineBreak)")
             body.append(photo.data)
             body.append(lineBreak)
          }
       }
       body.append("--\(boundary)--\(lineBreak)")
       return body
    }
    func generateBoundary() -> String {
       return "Boundary-\(NSUUID().uuidString)"
    }

}

extension Data {
   mutating func append(_ string: String) {
      if let data = string.data(using: .utf8) {
         append(data)
         print("data======>>>", data)
      }
   }
}
