//
//  ProgressRepository.swift
//  AppLearnEnglish
//

import Foundation
import Combine

protocol ProgressRepositoryProtocol {
    var currentUserPublisher: AnyPublisher<UserModel?, Never> { get }
}

final class ProgressRepository: ProgressRepositoryProtocol {
    var currentUserPublisher: AnyPublisher<UserModel?, Never> {
        SessionManager.shared.$currentUserModel.eraseToAnyPublisher()
    }
}
