//
//  String+Extension.swift
//  BaseProject
//
//  Created by Himanshu Kesharwani on 08/06/23.
//

import Foundation

extension String {

    var trim: String {
        return self.trimmingCharacters(in: .whitespaces)
    }
    var isValidEmail: Bool {
        let regexString = #"^(([^<>()\[\]\\.,;:\s@"]+(\.[^<>()\[\]\\.,;:\s@"]+)*)|(".+"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$"#
        let regex = try? NSRegularExpression(pattern: regexString,
           options: .caseInsensitive)
        return regex?.firstMatch(in: self, options: [], range: NSRange(location: 0, length: self.count)) != nil
    }
    var isAlphabetWithSpace: Bool {
        let regex = try? NSRegularExpression(pattern: ".*[^A-Za-z ].*", options: [])
        if regex?.firstMatch(in: self, options: [], range: NSRange(location: 0, length: self.count)) != nil {
            return false
        } else {
            return true

        }
    }
    var isValidPhoneNumber: Bool {
        let regex = try? NSRegularExpression(pattern: ".*[^0-9-+ ].*", options: [])
        if regex?.firstMatch(in: self, options: [], range: NSRange(location: 0, length: self.count)) != nil {
            return false
        } else {
            return true
        }
    }
}
