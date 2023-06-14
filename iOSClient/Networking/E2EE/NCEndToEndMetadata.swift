//
//  NCEndToEndMetadata.swift
//  Nextcloud
//
//  Created by Marino Faggiana on 13/11/17.
//  Copyright © 2017 Marino Faggiana. All rights reserved.
//
//  Author Marino Faggiana <marino.faggiana@nextcloud.com>
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.
//

import UIKit
import NextcloudKit

class NCEndToEndMetadata: NSObject {

    struct E2eeV1: Codable {

        struct Metadata: Codable {
            let metadataKeys: [String: String]
            let version: Double
        }

        struct Encrypted: Codable {
            let key: String
            let filename: String
            let mimetype: String
        }

        struct Files: Codable {
            let initializationVector: String
            let authenticationTag: String?
            let metadataKey: Int
            let encrypted: String
        }

        let metadata: Metadata
        let files: [String: Files]?
    }

    struct E2eeV12: Codable {

        struct Metadata: Codable {
            let metadataKey: String
            let version: Double
            let checksum: String?
        }

        struct Encrypted: Codable {
            let key: String
            let filename: String
            let mimetype: String
        }

        struct Files: Codable {
            let initializationVector: String
            let authenticationTag: String?
            let encrypted: String
        }

        struct Filedrop: Codable {
            let initializationVector: String
            let authenticationTag: String?
            let encrypted: String
            let encryptedKey: String?
            let encryptedTag: String?
            let encryptedInitializationVector: String?
        }

        let metadata: Metadata
        let files: [String: Files]?
        let filedrop: [String: Filedrop]?
    }

    struct E2eeV20: Codable {

        struct Metadata: Codable {
            let metadataKey: String
            let version: Double
            let checksum: String?
        }

        /*
        struct Encrypted: Codable {
            let key: String
            let filename: String
            let mimetype: String
        }

        struct Files: Codable {
            let initializationVector: String
            let authenticationTag: String?
            let encrypted: String
        }

        struct Filedrop: Codable {
            let initializationVector: String
            let authenticationTag: String?
            let encrypted: String
            let encryptedKey: String?
            let encryptedTag: String?
            let encryptedInitializationVector: String?
        }
        */

        let metadata: Metadata
        // let files: [String: Files]?
        // let filedrop: [String: Filedrop]?
    }

    // --------------------------------------------------------------------------------------------
    // MARK: Encode JSON Metadata V1.2
    // --------------------------------------------------------------------------------------------

    func encoderMetadata(_ items: [tableE2eEncryption], account: String, serverUrl: String) -> String? {

        let encoder = JSONEncoder()
        var metadataKey: String = ""
        let metadataVersion = 1.2
        var files: [String: E2eeV12.Files] = [:]
        var filesCodable: [String: E2eeV12.Files]?
        var filedrop: [String: E2eeV12.Filedrop] = [:]
        var filedropCodable: [String: E2eeV12.Filedrop]?
        let privateKey = CCUtility.getEndToEndPrivateKey(account)
        var fileNameIdentifiers: [String] = []

        // let shortVersion: String = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
        // var filesCodable: [String: E2eeV12.Files] = [String: E2eeV12.Files]()
        // var filedropCodable: [String: E2eeV12.Filedrop] = [String: E2eeV12.Filedrop]()

        //
        // metadata
        //
        if items.isEmpty, let key = NCEndToEndEncryption.sharedManager()?.generateKey() as? NSData {

            if let key = key.base64EncodedString().data(using: .utf8)?.base64EncodedString(),
               let metadataKeyEncrypted = NCEndToEndEncryption.sharedManager().encryptAsymmetricString(key, publicKey: nil, privateKey: privateKey) {
                metadataKey = metadataKeyEncrypted.base64EncodedString()
            }

        } else if let metadatakey = (items.first!.metadataKey.data(using: .utf8)?.base64EncodedString()),
                  let metadataKeyEncrypted = NCEndToEndEncryption.sharedManager().encryptAsymmetricString(metadatakey, publicKey: nil, privateKey: privateKey) {

            metadataKey = metadataKeyEncrypted.base64EncodedString()
        }

        for item in items {

            //
            // files
            //
            if item.blob == "files" {
                let encrypted = E2eeV12.Encrypted(key: item.key, filename: item.fileName, mimetype: item.mimeType)
                do {
                    // Create "encrypted"
                    let json = try encoder.encode(encrypted)
                    if let encrypted = NCEndToEndEncryption.sharedManager().encryptPayloadFile(String(data: json, encoding: .utf8), key: item.metadataKey) {
                        let record = E2eeV12.Files(initializationVector: item.initializationVector, authenticationTag: item.authenticationTag, encrypted: encrypted)
                        files.updateValue(record, forKey: item.fileNameIdentifier)
                    }
                    fileNameIdentifiers.append(item.fileNameIdentifier)
                } catch let error {
                    print("Serious internal error in encoding metadata (" + error.localizedDescription + ")")
                    return nil
                }
            }

            //
            // filedrop
            //
            if item.blob == "filedrop" {

                var encryptedKey: String?
                var encryptedInitializationVector: NSString?
                var encryptedTag: NSString?

                if let metadataKeyFiledrop = (item.metadataKeyFiledrop.data(using: .utf8)?.base64EncodedString()),
                   let metadataKeyEncrypted = NCEndToEndEncryption.sharedManager().encryptAsymmetricString(metadataKeyFiledrop, publicKey: nil, privateKey: privateKey) {
                    encryptedKey = metadataKeyEncrypted.base64EncodedString()
                }
                let encrypted = E2eeV12.Encrypted(key: item.key, filename: item.fileName, mimetype: item.mimeType)
                do {
                    // Create "encrypted"
                    let json = try encoder.encode(encrypted)
                    if let encrypted = NCEndToEndEncryption.sharedManager().encryptPayloadFile(String(data: json, encoding: .utf8), key: item.metadataKeyFiledrop, initializationVector: &encryptedInitializationVector, authenticationTag: &encryptedTag) {
                        let record = E2eeV12.Filedrop(initializationVector: item.initializationVector, authenticationTag: item.authenticationTag, encrypted: encrypted, encryptedKey: encryptedKey, encryptedTag: encryptedTag as? String, encryptedInitializationVector: encryptedInitializationVector as? String)
                        filedrop.updateValue(record, forKey: item.fileNameIdentifier)
                    }
                } catch let error {
                    print("Serious internal error in encoding metadata (" + error.localizedDescription + ")")
                    return nil
                }
            }
        }

        // Create checksum
        let passphrase = CCUtility.getEndToEndPassphrase(account).replacingOccurrences(of: " ", with: "")
        let checksum = NCEndToEndEncryption.sharedManager().createSHA256(passphrase + fileNameIdentifiers.sorted().joined() + metadataKey)

        // Create Json
        let metadata = E2eeV12.Metadata(metadataKey: metadataKey, version: metadataVersion, checksum: checksum)
        if !files.isEmpty { filesCodable = files }
        if !filedrop.isEmpty { filedropCodable = filedrop }
        let e2ee = E2eeV12(metadata: metadata, files: filesCodable, filedrop: filedropCodable)
        do {
            let data = try encoder.encode(e2ee)
            data.printJson()
            let jsonString = String(data: data, encoding: .utf8)
            // Updated metadata to 1.2
            if NCManageDatabase.shared.getE2eMetadata(account: account, serverUrl: serverUrl) == nil {
                NCManageDatabase.shared.setE2eMetadata(account: account, serverUrl: serverUrl, metadataKey: metadataKey, version: metadataVersion)
            }
            return jsonString
        } catch let error {
            print("Serious internal error in encoding e2ee (" + error.localizedDescription + ")")
            return nil
        }
    }

    // --------------------------------------------------------------------------------------------
    // MARK: Decode JSON Metadata Bridge
    // --------------------------------------------------------------------------------------------

    func decoderMetadata(_ json: String, serverUrl: String, account: String, urlBase: String, userId: String, ownerId: String?) -> (version: Double, metadataKey: String, error: NKError) {
        guard let data = json.data(using: .utf8) else {
            return (0, "", NKError(errorCode: NCGlobal.shared.errorE2EE, errorDescription: "Error decoding JSON"))
        }

        data.printJson()

        let decoder = JSONDecoder()

        if (try? decoder.decode(E2eeV1.self, from: data)) != nil {
            return decoderMetadataV1(json, serverUrl: serverUrl, account: account, urlBase: urlBase, userId: userId)
        } else if (try? decoder.decode(E2eeV12.self, from: data)) != nil {
            return decoderMetadataV12(json, serverUrl: serverUrl, account: account, urlBase: urlBase, userId: userId, ownerId: ownerId)
        } else if (try? decoder.decode(E2eeV20.self, from: data)) != nil {
            return decoderMetadataV20(json, serverUrl: serverUrl, account: account, urlBase: urlBase, userId: userId, ownerId: ownerId)
        } else {
            return (0, "", NKError(errorCode: NCGlobal.shared.errorInternalError, errorDescription: "Server E2EE version " + NCGlobal.shared.capabilityE2EEApiVersion + ", not compatible"))
        }
    }

    // --------------------------------------------------------------------------------------------
    // MARK: Decode JSON Metadata V1.1
    // --------------------------------------------------------------------------------------------

    func decoderMetadataV1(_ json: String, serverUrl: String, account: String, urlBase: String, userId: String) -> (version: Double, metadataKey: String, error: NKError) {
        guard let data = json.data(using: .utf8) else {
            return (0, "", NKError(errorCode: NCGlobal.shared.errorE2EE, errorDescription: "Error decoding JSON"))
        }

        let decoder = JSONDecoder()
        let privateKey = CCUtility.getEndToEndPrivateKey(account)
        var metadataVersion: Double = 0

        do {
            let json = try decoder.decode(E2eeV1.self, from: data)

            let metadata = json.metadata
            let files = json.files
            var metadataKeys: [String: String] = [:]

            metadataVersion = metadata.version

            // DATA
            NCManageDatabase.shared.deleteE2eEncryption(predicate: NSPredicate(format: "account == %@ AND serverUrl == %@", account, serverUrl))

            //
            // metadata
            //
            for metadataKey in metadata.metadataKeys {
                let data = Data(base64Encoded: metadataKey.value)
                if let decrypted = NCEndToEndEncryption.sharedManager().decryptAsymmetricData(data, privateKey: privateKey),
                   let keyData = Data(base64Encoded: decrypted) {
                    let key = String(data: keyData, encoding: .utf8)
                    metadataKeys[metadataKey.key] = key
                }
            }

            //
            // verify version
            //
            if let tableE2eMetadata = NCManageDatabase.shared.getE2eMetadata(account: account, serverUrl: serverUrl) {
                if tableE2eMetadata.version > metadataVersion {
                    return (metadataVersion, "", NKError(errorCode: NCGlobal.shared.errorE2EE, errorDescription: "Error verify version \(tableE2eMetadata.version)"))
                }
            }

            //
            // files
            //
            if let files = files {
                for files in files {
                    let fileNameIdentifier = files.key
                    let files = files.value as E2eeV1.Files

                    let encrypted = files.encrypted
                    let authenticationTag = files.authenticationTag
                    guard let metadataKey = metadataKeys["\(files.metadataKey)"] else { continue }
                    let metadataKeyIndex = files.metadataKey
                    let initializationVector = files.initializationVector

                    if let decrypted = NCEndToEndEncryption.sharedManager().decryptPayloadFile(encrypted, key: metadataKey),
                       let decryptedData = Data(base64Encoded: decrypted) {
                        do {
                            let encrypted = try decoder.decode(E2eeV1.Encrypted.self, from: decryptedData)

                            if let metadata = NCManageDatabase.shared.getMetadata(predicate: NSPredicate(format: "account == %@ AND fileName == %@", account, fileNameIdentifier)) {

                                let object = tableE2eEncryption()

                                object.account = account
                                object.authenticationTag = authenticationTag ?? ""
                                object.blob = "files"
                                object.fileName = encrypted.filename
                                object.fileNameIdentifier = fileNameIdentifier
                                object.fileNamePath = CCUtility.returnFileNamePath(fromFileName: encrypted.filename, serverUrl: serverUrl, urlBase: urlBase, userId: userId, account: account)
                                object.key = encrypted.key
                                object.initializationVector = initializationVector
                                object.metadataKey = metadataKey
                                object.metadataKeyIndex = metadataKeyIndex
                                object.metadataVersion = metadataVersion
                                object.mimeType = encrypted.mimetype
                                object.serverUrl = serverUrl

                                // Write file parameter for decrypted on DB
                                NCManageDatabase.shared.addE2eEncryption(object)

                                // Update metadata on tableMetadata
                                metadata.fileNameView = encrypted.filename

                                let results = NextcloudKit.shared.nkCommonInstance.getInternalType(fileName: encrypted.filename, mimeType: metadata.contentType, directory: metadata.directory)

                                metadata.contentType = results.mimeType
                                metadata.iconName = results.iconName
                                metadata.classFile = results.classFile

                                NCManageDatabase.shared.addMetadata(metadata)
                            }

                        } catch let error {
                            return (metadataVersion, metadataKey, NKError(errorCode: NCGlobal.shared.errorE2EE, errorDescription: "Error decrypt file: " + error.localizedDescription))
                        }
                    }
                }
            }
        } catch let error {
            return (metadataVersion, "", NKError(errorCode: NCGlobal.shared.errorE2EE, errorDescription: error.localizedDescription))
        }

        return (metadataVersion, "", NKError())
    }

    // --------------------------------------------------------------------------------------------
    // MARK: Decode JSON Metadata V1.2
    // --------------------------------------------------------------------------------------------

    func decoderMetadataV12(_ json: String, serverUrl: String, account: String, urlBase: String, userId: String, ownerId: String?) -> (version: Double, metadataKey: String, error: NKError) {
        guard let data = json.data(using: .utf8) else {
            return (0, "", NKError(errorCode: NCGlobal.shared.errorE2EE, errorDescription: "Error decoding JSON"))
        }

        let decoder = JSONDecoder()
        let privateKey = CCUtility.getEndToEndPrivateKey(account)
        var metadataVersion: Double = 0
        var metadataKey = ""

        do {
            let json = try decoder.decode(E2eeV12.self, from: data)

            let metadata = json.metadata
            let files = json.files
            let filedrop = json.filedrop
            var fileNameIdentifiers: [String] = []

            metadataVersion = metadata.version

            //
            // metadata
            //
            let data = Data(base64Encoded: metadata.metadataKey)

            /* TEST CMS

            if let cmsData = NCEndToEndEncryption.sharedManager().generateSignatureCMS(data, certificate: CCUtility.getEndToEndCertificate(account), privateKey: CCUtility.getEndToEndPrivateKey(account), publicKey: CCUtility.getEndToEndPublicKey(account), userId: userId) {
                
                let cms = cmsData.base64EncodedString()
                print(cms)

                let cmsTest = "MIAGCSqGSIb3DQEHAqCAMIACAQExCzAJBgUrDgMCGgUAMAsGCSqGSIb3DQEHAaCAMIIDpzCCAo+gAwIBAgIBADANBgkqhkiG9w0BAQUFADBuMRowGAYDVQQDDBF3d3cubmV4dGNsb3VkLmNvbTESMBAGA1UECgwJTmV4dGNsb3VkMRIwEAYDVQQHDAlTdHV0dGdhcnQxGzAZBgNVBAgMEkJhZGVuLVd1ZXJ0dGVtYmVyZzELMAkGA1UEBhMCREUwHhcNMTcwOTI2MTAwNDMwWhcNMzcwOTIxMTAwNDMwWjBuMRowGAYDVQQDDBF3d3cubmV4dGNsb3VkLmNvbTESMBAGA1UECgwJTmV4dGNsb3VkMRIwEAYDVQQHDAlTdHV0dGdhcnQxGzAZBgNVBAgMEkJhZGVuLVd1ZXJ0dGVtYmVyZzELMAkGA1UEBhMCREUwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQDsn0JKS/THu328z1IgN0VzYU53HjSX03WJIgWkmyTaxbiKpoJaKbksXmfSpgzVGzKFvGfZ03fwFrN7Q8P8R2e8SNiell7mh1TDw9/0P7Bt/ER8PJrXORo+GviKHxaLr7Y0BJX9i/nW/L0L/VaE8CZTAqYBdcSJGgHJjY4UMf892ZPTa9T2Dl3ggdMZ7BQ2kiCiCC3qV99b0igRJGmmLQaGiAflhFzuDQPMifUMq75wI8RSRPdxUAtjTfkl68QHu7Umyeyy33OQgdUKaTl5zcS3VSQbNjveVCNM4RDH1RlEc+7Wf1BY8APqT6jbiBcROJD2CeoLH2eiIJCi+61ZkSGfAgMBAAGjUDBOMB0GA1UdDgQWBBTFrXz2tk1HivD9rQ75qeoyHrAgIjAfBgNVHSMEGDAWgBTFrXz2tk1HivD9rQ75qeoyHrAgIjAMBgNVHRMEBTADAQH/MA0GCSqGSIb3DQEBBQUAA4IBAQARQTX21QKO77gAzBszFJ6xVnjfa23YZF26Z4X1KaM8uV8TGzuNJA95XmReeP2iO3r8EWXS9djVCD64m2xx6FOsrUI8HZaw1JErU8mmOaLAe8q9RsOm9Eq37e4vFp2YUEInYUqs87ByUcA4/8g3lEYeIUnRsRsWsA45S3wD7wy07t+KAn7jyMmfxdma6hFfG9iN/egN6QXUAyIPXvUvlUuZ7/BhWBj/3sHMrF9quy9Q2DOI8F3t1wdQrkq4BtStKhciY5AIXz9SqsctFHTv4Lwgtkapoel4izJnO0ZqYTXVe7THwri9H/gua6uJDWH9jk2/CiZDWfsyFuNUuXvDSp05AAAxggIlMIICIQIBATBzMG4xGjAYBgNVBAMMEXd3dy5uZXh0Y2xvdWQuY29tMRIwEAYDVQQKDAlOZXh0Y2xvdWQxEjAQBgNVBAcMCVN0dXR0Z2FydDEbMBkGA1UECAwSQmFkZW4tV3VlcnR0ZW1iZXJnMQswCQYDVQQGEwJERQIBADAJBgUrDgMCGgUAoIGIMBgGCSqGSIb3DQEJAzELBgkqhkiG9w0BBwEwHAYJKoZIhvcNAQkFMQ8XDTIzMDUxMDA4NDYxOVowIwYJKoZIhvcNAQkEMRYEFKlnk+/ov3trKM1XlXzkC65w0BgeMCkGCSqGSIb3DQEJNDEcMBowCQYFKw4DAhoFAKENBgkqhkiG9w0BAQEFADANBgkqhkiG9w0BAQEFAASCAQAvEpKP2xYZh8C3baa9CXumMaUrtp5Ez0nKuFAoQEDMxRDsqoRnKDiJQDITaG4s79Pxj61OUU2YTyM5BATCP6Hag/mqvTEXyPy06E09bcGjNoeZi/unCCyuc77M3rlUOgdP03l+BxQ0lPDlX2N2cAhiDzsMiAbcYhrsYo9aX2ue4O3emp4InfHqVEQaMxsVb0OZH1coxazvGLk5UougrGESigbFhZq2CLMpo/B2WU774YaZ2TRbpDObPl5wl4dV43pPmIQtp7Z90Io93G7JthFgrVNVerIrAyiqrZSLAGTzIRdhvwolf1Ole87bP8zrlb6oHvZt0DqOtOP0fk9wY9ibAAAAAAAA"

                let data = Data(base64Encoded: cmsTest)
                NCEndToEndEncryption.sharedManager().verifySignatureCMS(data, data: nil, publicKey: CCUtility.getEndToEndPublicKey(account), userId: userId)
            }
             */

            if let decrypted = NCEndToEndEncryption.sharedManager().decryptAsymmetricData(data, privateKey: privateKey),
                let keyData = Data(base64Encoded: decrypted),
                let key = String(data: keyData, encoding: .utf8) {
                metadataKey = key
            } else {
                return (metadataVersion, "", NKError(errorCode: NCGlobal.shared.errorE2EE, errorDescription: "Error decrypt metadataKey"))
            }

            // DATA
            NCManageDatabase.shared.deleteE2eEncryption(predicate: NSPredicate(format: "account == %@ AND serverUrl == %@", account, serverUrl))

            //
            // files
            //
            if let files = files {
                for file in files {
                    let fileNameIdentifier = file.key
                    let files = file.value as E2eeV12.Files
                    let encrypted = files.encrypted
                    let authenticationTag = files.authenticationTag
                    let initializationVector = files.initializationVector

                    fileNameIdentifiers.append(fileNameIdentifier)

                    if let decrypted = NCEndToEndEncryption.sharedManager().decryptPayloadFile(encrypted, key: metadataKey),
                       let decryptedData = Data(base64Encoded: decrypted) {
                        do {
                            decryptedData.printJson()
                            let encrypted = try decoder.decode(E2eeV12.Encrypted.self, from: decryptedData)

                            if let metadata = NCManageDatabase.shared.getMetadata(predicate: NSPredicate(format: "account == %@ AND fileName == %@", account, fileNameIdentifier)) {

                                let object = tableE2eEncryption()

                                object.account = account
                                object.authenticationTag = authenticationTag ?? ""
                                object.blob = "files"
                                object.fileName = encrypted.filename
                                object.fileNameIdentifier = fileNameIdentifier
                                object.fileNamePath = CCUtility.returnFileNamePath(fromFileName: encrypted.filename, serverUrl: serverUrl, urlBase: urlBase, userId: userId, account: account)
                                object.key = encrypted.key
                                object.initializationVector = initializationVector
                                object.metadataKey = metadataKey
                                object.metadataVersion = metadataVersion
                                object.mimeType = encrypted.mimetype
                                object.serverUrl = serverUrl

                                // Write file parameter for decrypted on DB
                                NCManageDatabase.shared.addE2eEncryption(object)

                                // Update metadata on tableMetadata
                                metadata.fileNameView = encrypted.filename

                                let results = NextcloudKit.shared.nkCommonInstance.getInternalType(fileName: encrypted.filename, mimeType: metadata.contentType, directory: metadata.directory)

                                metadata.contentType = results.mimeType
                                metadata.iconName = results.iconName
                                metadata.classFile = results.classFile

                                NCManageDatabase.shared.addMetadata(metadata)
                            }

                        } catch let error {
                            return (metadataVersion, metadataKey, NKError(errorCode: NCGlobal.shared.errorE2EE, errorDescription: "Error decrypt file: " + error.localizedDescription))
                        }
                    }
                }
            }

            //
            // filedrop
            //
            if let filedrop = filedrop {
                for filedrop in filedrop {
                    let fileNameIdentifier = filedrop.key
                    let filedrop = filedrop.value as E2eeV12.Filedrop
                    var metadataKeyFiledrop: String?

                    if let encryptedKey = filedrop.encryptedKey,
                       let data = Data(base64Encoded: encryptedKey),
                       let decrypted = NCEndToEndEncryption.sharedManager().decryptAsymmetricData(data, privateKey: privateKey) {
                        let keyData = Data(base64Encoded: decrypted)
                        metadataKeyFiledrop = String(data: keyData!, encoding: .utf8)
                    }

                    if let decrypted = NCEndToEndEncryption.sharedManager().decryptPayloadFile(filedrop.encrypted, key: metadataKeyFiledrop, initializationVector: filedrop.encryptedInitializationVector, authenticationTag: filedrop.encryptedTag),
                       let decryptedData = Data(base64Encoded: decrypted) {
                        do {
                            decryptedData.printJson()
                            let encrypted = try decoder.decode(E2eeV1.Encrypted.self, from: decryptedData)

                            if let metadata = NCManageDatabase.shared.getMetadata(predicate: NSPredicate(format: "account == %@ AND fileName == %@", account, fileNameIdentifier)) {

                                let object = tableE2eEncryption()

                                object.account = account
                                object.authenticationTag = filedrop.authenticationTag ?? ""
                                object.blob = "filedrop"
                                object.fileName = encrypted.filename
                                object.fileNameIdentifier = fileNameIdentifier
                                object.fileNamePath = CCUtility.returnFileNamePath(fromFileName: encrypted.filename, serverUrl: serverUrl, urlBase: urlBase, userId: userId, account: account)
                                object.key = encrypted.key
                                object.metadataKeyFiledrop = metadataKeyFiledrop ?? ""
                                object.initializationVector = filedrop.initializationVector
                                object.metadataKey = metadataKey
                                object.metadataVersion = metadataVersion
                                object.mimeType = encrypted.mimetype
                                object.serverUrl = serverUrl

                                // Write file parameter for decrypted on DB
                                NCManageDatabase.shared.addE2eEncryption(object)

                                // Update metadata on tableMetadata
                                metadata.fileNameView = encrypted.filename

                                let results = NextcloudKit.shared.nkCommonInstance.getInternalType(fileName: encrypted.filename, mimeType: metadata.contentType, directory: metadata.directory)

                                metadata.contentType = results.mimeType
                                metadata.iconName = results.iconName
                                metadata.classFile = results.classFile

                                NCManageDatabase.shared.addMetadata(metadata)
                            }

                        } catch let error {
                            return (metadataVersion, metadataKey, NKError(errorCode: NCGlobal.shared.errorE2EE, errorDescription: "Error decrypt filedrop: " + error.localizedDescription))
                        }
                    }
                }
            }

            // verify checksum
            let passphrase = CCUtility.getEndToEndPassphrase(account).replacingOccurrences(of: " ", with: "")
            let checksum = NCEndToEndEncryption.sharedManager().createSHA256(passphrase + fileNameIdentifiers.sorted().joined() + metadata.metadataKey)
            if metadata.checksum != checksum {
                return (metadataVersion, metadataKey, NKError(errorCode: NCGlobal.shared.errorE2EE, errorDescription: "Error checksum"))
            }
        } catch let error {
            return (metadataVersion, metadataKey, NKError(errorCode: NCGlobal.shared.errorE2EE, errorDescription: error.localizedDescription))
        }

        return (metadataVersion, metadataKey, NKError())
    }

    // --------------------------------------------------------------------------------------------
    // MARK: Decode JSON Metadata V2
    // --------------------------------------------------------------------------------------------

    func decoderMetadataV20(_ json: String, serverUrl: String, account: String, urlBase: String, userId: String, ownerId: String?) -> (version: Double, metadataKey: String, error: NKError) {
        guard let data = json.data(using: .utf8) else {
            return (0, "", NKError(errorCode: NCGlobal.shared.errorE2EE, errorDescription: "Error decoding JSON"))
        }

        let decoder = JSONDecoder()
        let privateKey = CCUtility.getEndToEndPrivateKey(account)
        var metadataVersion: Double = 0
        var metadataKey = ""

        do {
            let json = try decoder.decode(E2eeV12.self, from: data)

            let metadata = json.metadata

            metadataVersion = metadata.version

            /*
            if let users = users {
                for user in users {
                    if user.userId == ownerId,
                       let data = Data(base64Encoded: user.encryptedMetadataKey) {
                        if let decrypted = NCEndToEndEncryption.sharedManager().decryptAsymmetricData(data, privateKey: privateKey) {
                            let key = decrypted.base64EncodedString()
                            if let decrypted = NCEndToEndEncryption.sharedManager().decryptPayloadFile(metadata.ciphertext, key: key, tag: metadata.authenticationTag, nonce: metadata.nonce) {
                                if decrypted.isGzipped {
                                    do {
                                        let data = try decrypted.gunzipped()
                                        let jsonText = String(data: data, encoding: .utf8)
                                        print(jsonText)
                                    } catch let error {
                                        print("Serious internal error in decoding metadata (" + error.localizedDescription + ")")
                                        return false
                                    }
                                } else {
                                    print("Serious internal error in decoding metadata")
                                    return false
                                }
                            }
                        }
                    }
                }
            }
            */

        } catch let error {
            return (metadataVersion, metadataKey, NKError(errorCode: NCGlobal.shared.errorE2EE, errorDescription: error.localizedDescription))
        }

        return (metadataVersion, metadataKey, NKError())
    }
}
