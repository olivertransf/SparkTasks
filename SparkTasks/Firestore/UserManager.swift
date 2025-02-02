//
//  UserManager.swift
//  Fire
//
//  Created by Oliver Tran on 1/9/25.
//

import Foundation
import FirebaseFirestore

struct DBUser: Codable {
    let userId: String
    let dateCreated: Date?
    let email: String?
    let photoUrl: String?
    
    init(auth: AuthDataResultModel) {
        self.userId = auth.uid
        self.email = auth.email
        self.photoUrl = auth.photoUrl
        self.dateCreated = Date()
    }
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case dateCreated = "date_created"
        case email = "email"
        case photoUrl = "photo_url"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.userId = try container.decode(String.self, forKey: .userId)
        self.dateCreated = try container.decodeIfPresent(Date.self, forKey: .dateCreated)
        self.email = try container.decodeIfPresent(String.self, forKey: .email)
        self.photoUrl = try container.decodeIfPresent(String.self, forKey: .photoUrl)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(userId, forKey: .userId)
        try container.encodeIfPresent(dateCreated, forKey: .dateCreated)
        try container.encodeIfPresent(email, forKey: .email)
        try container.encodeIfPresent(photoUrl, forKey: .photoUrl)
    }
}

final class UserManager {
    
    static let shared = UserManager()
    private init() { }
    
    private let encoder: Firestore.Encoder = {
        let encoder = Firestore.Encoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        return encoder
    }()

    private let decoder: Firestore.Decoder = {
        let decoder = Firestore.Decoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }()
    
    private let userCollection = Firestore.firestore().collection("users")
    
    private func userDocument(userId: String) -> DocumentReference {
        userCollection.document(userId)
    }
    
    func createNewUser(user: DBUser) async throws {
        try userDocument(userId: user.userId).setData(from: user, merge: false)
    }
    
    func getUser(userId: String) async throws -> DBUser {
        try await userDocument(userId: userId).getDocument(as: DBUser.self)
    }
    
    func checkUserExists(uid: String) async throws -> Bool {
        let document = try await userDocument(userId: uid).getDocument()
        return document.exists
    }

}
