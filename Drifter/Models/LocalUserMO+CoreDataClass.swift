//
//  LocalUserMO+CoreDataClass.swift
//  Drifter
//
//  Created by Chris on 11/7/18.
//  Copyright © 2018 Sun Canyon. All rights reserved.
//
//

import Foundation
import CoreData

@objc(LocalUserMO)
public class LocalUserMO: UserMO {
  private func randomString(length: Int) -> String {
    let allowedChars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    return String((0...length-1).map{ _ in allowedChars.randomElement()! })
  }
  
  func assignRandomPassword() {
    let keychainQuery = [kSecClass as String: kSecClassGenericPassword,
                         kSecAttrAccount as String: self.value(forKey: "username"),
                         kSecAttrService as String: "Drifter Password",
                         kSecValueData as String: randomString(length: 20).data(using: String.Encoding.utf8)]
    let status = SecItemAdd(keychainQuery as CFDictionary, nil)
    guard status == errSecSuccess else {
      print("failed to assign password")
      return
    }
  }
  
  func getPassword() -> String? {
    let keychainQuery = [kSecClass as String: kSecClassGenericPassword,
                         kSecAttrAccount as String: self.value(forKey: "username"),
                         kSecAttrService as String: "Drifter Password",
                         kSecMatchLimit as String: kSecMatchLimitOne,
                         kSecReturnAttributes as String: true,
                         kSecReturnData as String: true]
    var item: CFTypeRef?
    let status = SecItemCopyMatching(keychainQuery as CFDictionary, &item)
    guard status == errSecSuccess else {
      print("failed to retrieve user for password")
      return nil
    }
    guard let existingItem = item as? [String: Any],
          let passwordData = existingItem[kSecValueData as String] as? Data,
          let password = String(data: passwordData, encoding: String.Encoding.utf8)
    else {
      print("user retrieved but no password found")
      return nil
    }
    return password
  }
  
  func saveJWT(_ token: String) {
    let keychainQuery = [kSecClass as String: kSecClassGenericPassword,
                         kSecAttrAccount as String: self.value(forKey: "username"),
                         kSecAttrService as String: "Drifter Session Token",
                         kSecValueData as String: token.data(using: String.Encoding.utf8)]
    let status = SecItemAdd(keychainQuery as CFDictionary, nil)
    guard status == errSecSuccess else {
      print("failed to save JWT with status: ", status)
      return
    }
  }
  
  func getJWT() -> String? {
    let keychainQuery = [kSecClass as String: kSecClassGenericPassword,
                         kSecAttrAccount as String: self.value(forKey: "username"),
                         kSecAttrService as String: "Drifter Session Token",
                         kSecMatchLimit as String: kSecMatchLimitOne,
                         kSecReturnAttributes as String: true,
                         kSecReturnData as String: true]
    var item: CFTypeRef?
    let status = SecItemCopyMatching(keychainQuery as CFDictionary, &item)
    guard status == errSecSuccess else {
      print("failed to retrieve user for JWT with status: ", status)
      return nil
    }
    guard let existingItem = item as? [String: Any],
      let jwtData = existingItem[kSecValueData as String] as? Data,
      let jwt = String(data: jwtData, encoding: String.Encoding.utf8)
      else {
        print("user retrieved but no token found")
        return nil
    }
    return jwt
  }
}
