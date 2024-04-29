//
//  Errors.swift
//  Casper
//
//  Created by Michael Ershov on 2/5/23.
//

import Foundation

enum CasperErrors: Error {
    case unknown
    case readError(String)
    case writeError(String)
    case encodeError(String)
    case decodeError(String)
}

