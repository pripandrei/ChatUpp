//
//  SupabaseStorageManager.swift
//  ChatUpp
//
//  Created by Andrei Pripa on 11/25/25.
//

import Foundation
import Supabase

final class SupabaseStorageManager
{
    private let client = SupabaseClient(supabaseURL: SupabaseConfig.url, supabaseKey: SupabaseConfig.anonKey)
    private let bucketName = "chatupp"
    static let shared = SupabaseStorageManager()
    private let maxImageSize: Int64 = 3 * 1024 * 1024  // 3MB
    private let maxVoiceSize: Int64 = 20 * 1024 * 1024  // 20MB

    private init() {}
}

//MARK: - themes fetch
extension SupabaseStorageManager
{
    func getTheme(from path: StoragePathType, themePath: String) async throws -> Data
    {
        let data = try await downloadData(from: "\(path.path)/\(themePath)")
        return try validatedData(data, withMaxSize: maxImageSize)
    }
}

//MARK: - message image save/get
extension SupabaseStorageManager
{
    func getImage(from path: StoragePathType, imagePath: String) async throws -> Data {
        let data = try await downloadData(from: "\(path.path)/\(imagePath)")
        return try validatedData(data, withMaxSize: maxImageSize)
    }

    func getImageURL(from path: StoragePathType, imagePath: String) async throws -> URL {
        try client.storage.from(bucketName).getPublicURL(path: "\(path.path)/\(imagePath)")
    }

    @discardableResult
    func saveImage(data: Data,
                   to path: StoragePathType,
                   imagePath: String? = nil) async throws -> ImageMetadata
    {
        let finalPath = imagePath ?? "\(UUID().uuidString).jpeg"
        let objectPath = "\(path.path)/\(finalPath)"

        let response = try await client.storage.from(bucketName).upload(
            objectPath,
            data: data,
            options: FileOptions(contentType: "image/jpeg", upsert: true)
        )

        return ImageMetadata(path: response.path, name: finalPath)
    }

    func deleteImage(from path: StoragePathType, imagePath: String) async throws {
        let _ = try await client.storage.from(bucketName).remove(paths: ["\(path.path)/\(imagePath)"])
    }

    func deleteVoice(from path: StoragePathType, voicePath: String) async throws {
        let _ = try await client.storage.from(bucketName).remove(paths: ["\(path.path)/\(voicePath)"])
    }
}

//MARK: - message voice save/get
extension SupabaseStorageManager
{
    func getVoiceData(from path: StoragePathType, voicePath: String) async throws -> Data
    {
        let data = try await downloadData(from: "\(path.path)/\(voicePath)")
        return try validatedData(data, withMaxSize: maxVoiceSize)
    }

    func saveVoice(fromURL url: URL,
                   to path: StoragePathType) async
    {
        let objectPath = "\(path.path)/\(url.lastPathComponent)"

        do {
            let _ = try await client.storage.from(bucketName).upload(
                objectPath,
                fileURL: url,
                options: FileOptions(contentType: "audio/m4a", upsert: true)
            )
        } catch {
            print("Error while saving voice message to storage")
        }
    }
}

//MARK: - helpers
private extension SupabaseStorageManager
{
    func downloadData(from objectPath: String) async throws -> Data
    {
        let url = try client.storage.from(bucketName).getPublicURL(path: objectPath)
        let (data, response) = try await URLSession.shared.data(from: url)

        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        return data
    }

    func validatedData(_ data: Data, withMaxSize maxSize: Int64) throws -> Data
    {
        guard Int64(data.count) <= maxSize else {
            throw URLError(.dataNotAllowed)
        }
        return data
    }
}
