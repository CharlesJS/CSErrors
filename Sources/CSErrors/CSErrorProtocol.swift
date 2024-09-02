//
//  CSErrorProtocol.swift
//
//
//  Created by Charles Srstka on 1/10/23.
//

public protocol CSErrorProtocol: Error {
    var isFileNotFoundError: Bool { get }
    var isPermissionError: Bool { get }
    var isCancelledError: Bool { get }
}
