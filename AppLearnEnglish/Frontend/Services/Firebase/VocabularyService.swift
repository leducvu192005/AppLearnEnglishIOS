//
//  VocabularyService.swift
//  AppLearnEnglish
//

import Foundation
import FirebaseFirestore

class VocabularyService {
    static let shared = VocabularyService()
    private let db = Firestore.firestore()
    
    private init() {}
    
    // MARK: - Fetch Topics (Firestore with Mock Fallback)
    func fetchTopics() async throws -> [Topic] {
        do {
            let snapshot = try await db.collection("topics").getDocuments()
            if snapshot.documents.isEmpty {
                print("Firebase Firestore is empty. Auto-seeding default vocabulary...")
                await seedDefaultData()
                return mockTopics
            }
            return snapshot.documents.compactMap { doc in
                try? doc.data(as: Topic.self)
            }
        } catch {
            print("Firestore fetch topics failed: \(error.localizedDescription). Using Mock data.")
            return mockTopics
        }
    }
    
    private func loadOxfordWords() -> [VocabularyWord] {
        guard let url = Bundle.main.url(forResource: "oxford_3000", withExtension: "json") else {
            print("Resource oxford_3000.json not found in main bundle. Using static mocks.")
            return []
        }
        do {
            let data = try Data(contentsOf: url)
            let decoded = try JSONDecoder().decode([VocabularyWord].self, from: data)
            return decoded
        } catch {
            print("Error parsing oxford_3000.json: \(error.localizedDescription). Using static mocks.")
            return []
        }
    }
    
    // MARK: - Auto-Seeding Database
    func seedDefaultData() async {
        print("Starting Firestore Auto-Seeding...")
        let batch = db.batch()
        
        // 1. Seed Topics
        for topic in mockTopics {
            let docRef = db.collection("topics").document(topic.id)
            try? batch.setData(from: topic, forDocument: docRef)
        }
        
        // 2. Seed Vocabulary (Mock + Oxford 3000 bundle words)
        let allWordsToSeed = mockVocabulary + loadOxfordWords()
        var uniqueWords: [VocabularyWord] = []
        var seenIds = Set<String>()
        for w in allWordsToSeed {
            if !seenIds.contains(w.id) {
                seenIds.insert(w.id)
                uniqueWords.append(w)
            }
        }
        
        for word in uniqueWords {
            let docRef = db.collection("vocabulary").document(word.id)
            try? batch.setData(from: word, forDocument: docRef)
        }
        
        do {
            try await batch.commit()
            print("Firestore Auto-Seeding Completed Successfully! ✅")
        } catch {
            print("Firestore Auto-Seeding Failed: \(error.localizedDescription) ❌")
        }
    }
    
    // MARK: - Fetch Words for Topic (Firestore with Mock Fallback)
    func fetchWords(for topicId: String) async throws -> [VocabularyWord] {
        do {
            let snapshot = try await db.collection("vocabulary")
                .whereField("topicId", isEqualTo: topicId)
                .getDocuments()
            
            if snapshot.documents.isEmpty {
                return mockVocabulary.filter { $0.topicId == topicId }
            }
            
            return snapshot.documents.compactMap { doc in
                try? doc.data(as: VocabularyWord.self)
            }
        } catch {
            print("Firestore fetch words failed: \(error.localizedDescription). Using Mock data.")
            return mockVocabulary.filter { $0.topicId == topicId }
        }
    }
    
    // MARK: - Mark Word as Learned
    func markWordAsLearned(userId: String, wordId: String) async throws {
        let learnedDocRef = db.collection("users")
            .document(userId)
            .collection("learned_words")
            .document(wordId)
        
        // Write to learned_words subcollection
        try await learnedDocRef.setData([
            "wordId": wordId,
            "status": "learned",
            "learnedAt": FieldValue.serverTimestamp()
        ])
        
        // Dynamically update user's XP (+10) and streak in their profile
        try await UserService.shared.updateProgressAndStreak(uid: userId, xp: 10)
    }
    
    // MARK: - Toggle Favorite status
    func toggleFavoriteWord(userId: String, wordId: String, isFavorite: Bool) async throws {
        let favDocRef = db.collection("users")
            .document(userId)
            .collection("favorite_words")
            .document(wordId)
        
        if isFavorite {
            try await favDocRef.setData([
                "wordId": wordId,
                "createdAt": FieldValue.serverTimestamp()
            ])
        } else {
            try await favDocRef.delete()
        }
    }
    
    // MARK: - Fetch All Vocabulary Words (Firestore with Mock Fallback)
    func fetchAllVocabulary() async throws -> [VocabularyWord] {
        do {
            let snapshot = try await db.collection("vocabulary").getDocuments()
            if snapshot.documents.isEmpty {
                return mockVocabulary
            }
            return snapshot.documents.compactMap { doc in
                try? doc.data(as: VocabularyWord.self)
            }
        } catch {
            print("Error fetching all vocabulary words: \(error.localizedDescription). Using Mock data.")
            return mockVocabulary
        }
    }
    
    // MARK: - Fetch user specific learned word IDs
    func fetchLearnedWordIds(userId: String) async throws -> Set<String> {
        do {
            let snapshot = try await db.collection("users")
                .document(userId)
                .collection("learned_words")
                .getDocuments()
            
            let ids = snapshot.documents.compactMap { doc -> String? in
                doc.documentID
            }
            return Set(ids)
        } catch {
            print("Error fetching learned words: \(error)")
            return []
        }
    }
    
    // MARK: - Fetch user specific favorite word IDs
    func fetchFavoriteWordIds(userId: String) async throws -> Set<String> {
        do {
            let snapshot = try await db.collection("users")
                .document(userId)
                .collection("favorite_words")
                .getDocuments()
            
            let ids = snapshot.documents.compactMap { doc -> String? in
                doc.documentID
            }
            return Set(ids)
        } catch {
            print("Error fetching favorite words: \(error)")
            return []
        }
    }
    
    // MARK: - Mock Data Definition
    
    private let mockTopics = [
        Topic(id: "travel", name: "Du lịch", description: "Từ vựng thông dụng tại sân bay, khách sạn, di chuyển", image: "airplane.circle.fill", totalWords: 20),
        Topic(id: "business", name: "Công sở", description: "Đàm phán văn phòng, email, cuộc họp chuyên nghiệp", image: "briefcase.circle.fill", totalWords: 5),
        Topic(id: "tech", name: "Công nghệ", description: "Các thuật ngữ công nghệ thông tin, lập trình và AI", image: "cpu.circle.fill", totalWords: 5),
        Topic(id: "dailylife", name: "Đời sống", description: "Giao tiếp hàng ngày, mua sắm và ăn uống sinh hoạt", image: "cart.circle.fill", totalWords: 5)
    ]
    
    private let mockVocabulary = [
        // 20 Travel Words
        VocabularyWord(id: "tr1", word: "airport", phonetic: "/ˈeəpɔːt/", meaning: "sân bay", example: "I will meet you at the airport.", image: "", audio: "", topicId: "travel", level: "Beginner"),
        VocabularyWord(id: "tr2", word: "passport", phonetic: "/ˈpɑːspɔːt/", meaning: "hộ chiếu", example: "You must show your passport at the border.", image: "", audio: "", topicId: "travel", level: "Beginner"),
        VocabularyWord(id: "tr3", word: "luggage", phonetic: "/ˈlʌɡɪdʒ/", meaning: "hành lý", example: "We packed our luggage the night before.", image: "", audio: "", topicId: "travel", level: "Beginner"),
        VocabularyWord(id: "tr4", word: "flight", phonetic: "/flaɪt/", meaning: "chuyến bay", example: "The flight was delayed by two hours.", image: "", audio: "", topicId: "travel", level: "Beginner"),
        VocabularyWord(id: "tr5", word: "ticket", phonetic: "/ˈtɪkɪt/", meaning: "vé", example: "Please buy a train ticket in advance.", image: "", audio: "", topicId: "travel", level: "Beginner"),
        VocabularyWord(id: "tr6", word: "boarding", phonetic: "/ˈbɔːdɪŋ/", meaning: "lên máy bay / tàu", example: "Boarding will start 30 minutes before departure.", image: "", audio: "", topicId: "travel", level: "Intermediate"),
        VocabularyWord(id: "tr7", word: "hotel", phonetic: "/həʊˈtel/", meaning: "khách sạn", example: "We stayed in a small, quiet hotel.", image: "", audio: "", topicId: "travel", level: "Beginner"),
        VocabularyWord(id: "tr8", word: "reservation", phonetic: "/ˌrezəˈveɪʃn/", meaning: "sự đặt chỗ", example: "I have a reservation under the name Alex.", image: "", audio: "", topicId: "travel", level: "Intermediate"),
        VocabularyWord(id: "tr9", word: "destination", phonetic: "/ˌdestɪˈneɪʃn/", meaning: "điểm đến", example: "Our final destination was London.", image: "", audio: "", topicId: "travel", level: "Intermediate"),
        VocabularyWord(id: "tr10", word: "tourist", phonetic: "/ˈtʊərɪst/", meaning: "khách du lịch", example: "Paris is always full of tourists.", image: "", audio: "", topicId: "travel", level: "Beginner"),
        VocabularyWord(id: "tr11", word: "baggage", phonetic: "/ˈbæɡɪdʒ/", meaning: "hành lý (xách tay/ký gửi)", example: "Only one piece of hand baggage is allowed.", image: "", audio: "", topicId: "travel", level: "Beginner"),
        VocabularyWord(id: "tr12", word: "customs", phonetic: "/ˈkʌstəmz/", meaning: "hải quan", example: "It took us an hour to get through customs.", image: "", audio: "", topicId: "travel", level: "Intermediate"),
        VocabularyWord(id: "tr13", word: "departure", phonetic: "/dɪˈpɑːtʃə/", meaning: "sự khởi hành", example: "Check the departure screen for your gate.", image: "", audio: "", topicId: "travel", level: "Intermediate"),
        VocabularyWord(id: "tr14", word: "arrival", phonetic: "/əˈraɪvl/", meaning: "sự đến nơi", example: "They sent an SMS upon their arrival.", image: "", audio: "", topicId: "travel", level: "Intermediate"),
        VocabularyWord(id: "tr15", word: "souvenir", phonetic: "/ˌsuːvəˈnɪə/", meaning: "quà lưu niệm", example: "I bought a model of the Eiffel Tower as a souvenir.", image: "", audio: "", topicId: "travel", level: "Beginner"),
        VocabularyWord(id: "tr16", word: "itinerary", phonetic: "/aɪˈtɪnərəri/", meaning: "lịch trình chuyến đi", example: "We planned our travel itinerary carefully.", image: "", audio: "", topicId: "travel", level: "Advanced"),
        VocabularyWord(id: "tr17", word: "passenger", phonetic: "/ˈpæsɪndʒə/", meaning: "hành khách", example: "The airplane carried over 200 passengers.", image: "", audio: "", topicId: "travel", level: "Beginner"),
        VocabularyWord(id: "tr18", word: "airline", phonetic: "/ˈeəlaɪn/", meaning: "hãng hàng không", example: "Which airline are you flying with?", image: "", audio: "", topicId: "travel", level: "Beginner"),
        VocabularyWord(id: "tr19", word: "compass", phonetic: "/ˈkʌmpəs/", meaning: "la bàn", example: "A compass is useful if you get lost.", image: "", audio: "", topicId: "travel", level: "Intermediate"),
        VocabularyWord(id: "tr20", word: "vacation", phonetic: "/vəˈkeɪʃn/", meaning: "kỳ nghỉ", example: "We are going on vacation next week.", image: "", audio: "", topicId: "travel", level: "Beginner"),
        
        // Business
        VocabularyWord(id: "bs1", word: "negotiate", phonetic: "/nɪˈɡəʊʃieɪt/", meaning: "đàm phán", example: "We managed to negotiate a lower price.", image: "", audio: "", topicId: "business", level: "Advanced"),
        VocabularyWord(id: "bs2", word: "meeting", phonetic: "/ˈmiːtɪŋ/", meaning: "cuộc họp", example: "The meeting will start in ten minutes.", image: "", audio: "", topicId: "business", level: "Beginner"),
        
        // Tech
        VocabularyWord(id: "tc1", word: "algorithm", phonetic: "/ˈælɡərɪðəm/", meaning: "thuật toán", example: "Google uses a complex search algorithm.", image: "", audio: "", topicId: "tech", level: "Advanced"),
        VocabularyWord(id: "tc2", word: "database", phonetic: "/ˈdeɪtəbeɪs/", meaning: "cơ sở dữ liệu", example: "All customer information is stored in the database.", image: "", audio: "", topicId: "tech", level: "Intermediate")
    ]
}
