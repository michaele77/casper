//
//  PersistenceManager.swift
//  Casper
//
//  Created by Michael Ershov on 2/5/23.
//

import Foundation

// TODO(mershov): Try not to use Singletons. Not sure that is possible or even really desired for something as ubiquotous as                  the persistance layer, but look into removing it.
class PersistenceManager {
    static let shared = PersistenceManager()
    
    // Setup any fields you want to store in the PersistenceManager singleton upon construction.
    private init() {}
    
    // Returns the directory of the given user. Will be used to retrieve directory for pList access.
    func documentsDirectory() -> URL {
        // Get the directories for the user, just use the first one.
        let path = try! FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true)
        return path
    }
    
    func write(asset_library_metadata: AssetLibraryMetadata) throws {
        let path = documentsDirectory().appendingPathExtension("asset_library_metadata.plist")
        let plistEncoder = PropertyListEncoder()
        plistEncoder.outputFormat = .xml

        var encoded: Data = Data()
        do {
            let encoded = try plistEncoder.encode(asset_library_metadata)
        } catch {
            throw CasperErrors.encodeError("Could not encode latest library asset.")
        }
        
        do {
            try encoded.write(to: path)
        } catch {
            throw CasperErrors.writeError("Could not persist latest library asset.")
        }
    }
    
    func read() throws -> AssetLibraryMetadata? {
        // TODO(mershov): Update this read code to be throwing with proper error handling.
        let path = documentsDirectory().appendingPathExtension("asset_library_metadata.plist")
        let plistDecoder = PropertyListDecoder()
        
        if let data = try? Data(contentsOf: path) {
            return try plistDecoder.decode(AssetLibraryMetadata.self, from: data)
        }
        return nil
    }
    
}
