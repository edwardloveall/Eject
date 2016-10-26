//
//  Extensions.swift
//  Eject
//
//  Created by Brian King on 10/19/16.
//  Copyright © 2016 Brian King. All rights reserved.
//

import Foundation

extension String {

    func snakeCased() -> String {
        var newString = ""
        var previousCharacter: Character? = nil
        for character in characters {
            if previousCharacter == nil {
                newString.append(String(character).lowercased())
            }
            else if previousCharacter == " " {
                newString.append(String(character).uppercased())
            }
            else if character != " " {
                newString.append(character)
            }
            previousCharacter = character
        }
        return newString
    }

    func objcNamespace() -> String {
        var namespace = ""
        var previousCharacter: UnicodeScalar? = nil
        for character in unicodeScalars {
            if let previousCharacter = previousCharacter {
                if CharacterSet.uppercaseLetters.contains(previousCharacter) && CharacterSet.uppercaseLetters.contains(character) {
                    namespace.append(String(previousCharacter))
                }
                else {
                    return namespace
                }
            }
            previousCharacter = character
        }
        return namespace
    }
}

extension String {

    var floatValue: CGFloat? {
        if let double = Double(self) {
            return CGFloat(double)
        }
        return nil
    }
}

extension CGFloat {

    var shortString: String {
        return String(format: "%.3g", self)
    }
}

extension XMLParser {
    struct Error: Swift.Error {
        /// The error generated by XMLParser
        public let parserError: Swift.Error
        /// The line number the error occurred on.
        public let line: Int
        /// The column the error occurred on.
        public let column: Int
    }

    func throwingParse() throws {
        if parse() == false {
            throw Error(parserError: parserError!, line: lineNumber, column: columnNumber)
        }
    }
}

extension RangeReplaceableCollection where Iterator.Element : Equatable {

    mutating func remove(contentsOf array: Array<Iterator.Element>) {
        for item in array {
            if let index = index(of: item) {
                remove(at: index)
            }
        }
    }
}
