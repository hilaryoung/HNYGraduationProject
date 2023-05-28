//
//  AppViewModel.swift
//  MakanLagi
//
//  Created by Hilary Young on 16/04/2023.
//

import SwiftUI
import FirebaseAuth
import Firebase
import FirebaseFirestore
import FirebaseFirestoreSwift


class AppViewModel: ObservableObject {
    
    let auth = Auth.auth()
    let db = Firestore.firestore()
    
    
    @Published var signedIn = false
    @Published var userName = ""
    
    var isSignedIn: Bool {
        return auth.currentUser != nil
    }
    
    // Function 1: Sign In
    func signIn(email: String, password: String) {
        auth.signIn(withEmail: email, password: password) { [weak self] result, error in
            guard result != nil, error == nil else {
                return
            }
            DispatchQueue.main.async {
                // Success
                self?.signedIn = true
            }
        }
    }
    
    // Function 2: Sign Up Function
    func signUp(email: String, password: String, firstName: String, lastName: String) {
        // Creating user account with Firebase Auth
        auth.createUser(withEmail: email, password: password) { [weak self] result, error in
            guard let user = result?.user, error == nil else {
                return
            }
            DispatchQueue.main.async { // Success
                self?.signedIn = true
            }
            
            // Storing user's first name, last name, email, UUID in Firestore
            let userDocRef = self?.db.collection("Users").document(user.uid)
            userDocRef?.setData([
                "firstName": firstName,
                "lastName": lastName,
                "email": email,
                "uid": user.uid
            ]) { error in
                if let error = error {
                    print("Error adding document: \(error)")
                } else {
                    print("Document added successfully")
                }
            }
        }
    }
    
    // Function 3: Sign Out Function
    func signOut() {
        try? auth.signOut()
        
        self.signedIn = false
        
        print("User is signed out")
    }
    
    
    // Function 4: Fetch User Name
    @Published var userData: [User] = []
    
    
    // Function 5: Add Leftover to User's Database (Firestore)
    var uuid: String? {
        auth.currentUser?.uid // asking for user ID
    }
    
    func addItem(newItemName: String, newExpDate: Date){
        let db = Firestore.firestore()
        let ref = db.collection("userCollection").document(self.uuid!).collection("virtualPantry").document(newItemName) // name of the doccument
        // what is inside the doccument
        ref.setData(["itemName": newItemName, "expDate": newExpDate]) { error in
            if let error = error {
                print(error.localizedDescription)
            }
        }
    }
    
    
    // Function 6: Fetching User's Virtual Pantry Data (Firestore)
    @Published var items: [UserVirtualPantry] = []
    
    func fetchItems() {
        items.removeAll()
        let db = Firestore.firestore()
        if let uuid = self.uuid {
            let ref = db.collection("userCollection").document(uuid).collection("virtualPantry")
            ref.getDocuments { snapshot, error in
                guard error == nil else{
                    print(error!.localizedDescription)
                    return
                }
                
                if let snapshot = snapshot {
                    for document in snapshot.documents{
                        let data = document.data()
                        
                        let id = UUID().uuidString
                        let itemName = data["itemName"] as? String ?? ""
                        let expDate = (data["expDate"] as? Timestamp)?.dateValue() ?? Date()
                        
                        let item = UserVirtualPantry(id: id, itemName: itemName, expDate: expDate)
                        self.items.append(item)
                    }
                }
            }
        }
    }
    
    // Function 7: Delete document from firebase database
    func deleteItem(itemName: String) {
        if let uuid = self.uuid {
            let db = Firestore.firestore()
            let ref = db.collection("userCollection").document(uuid).collection("virtualPantry").document(itemName)
            ref.delete { error in
                if let error = error {
                    print("Error deleting item: \(error.localizedDescription)")
                } else {
                    print("Item deleted successfully")
                    self.items.removeAll(where: { $0.itemName == itemName })
                }
            }
        }
    }
    
    
    // Function 8: Add user's awards to firebase database
    func addAward(awardImg: String, awardDetailImg: String, photoImg: String, windowText: String, title: String, subtitle: String, body: String){
        let db = Firestore.firestore()
        
        let awardID = String(format: "%05d", Int.random(in: 0...99999)) // generating 5 digit random number
        
        let ref = db.collection("userCollection").document(self.uuid!).collection("awards").document(awardID)
        // what is inside the doccument
        ref.setData([
            "awardImg": awardImg,
            "awardDetailImg": awardDetailImg,
            "photoImg": photoImg,
            "windowText": windowText,
            "title": title,
            "subtitle": subtitle,
            "body": body
        ]) { error in
            if let error = error {
                print(error.localizedDescription)
            }
        }
    }
    
    
    // Function 9: Fetch user's awards from firestore database
    @Published var awards: [Award] = []
    
    func fetchAwards() {
        awards.removeAll()
        let db = Firestore.firestore()
        if let uuid = self.uuid {
            let ref = db.collection("userCollection").document(uuid).collection("awards") // change this
            ref.getDocuments { snapshot, error in
                guard error == nil else{
                    print(error!.localizedDescription)
                    return
                }
                
                if let snapshot = snapshot {
                    for document in snapshot.documents{
                        let data = document.data()
                        
                        let id = UUID().uuidString
                        let awardImg = data["awardImg"] as? String ?? ""
                        let awardDetailImg = data["awardDetailImg"] as? String ?? ""
                        let photoImg = data["photoImg"] as? String ?? ""
                        let windowText = data["windowText"] as? String ?? ""
                        let title = data["title"] as? String ?? ""
                        let subtitle = data["subtitle"] as? String ?? ""
                        let body = data["body"] as? String ?? ""
                        
                        let award = Award(
                            id: id,
                            awardImg: awardImg,
                            awardDetailImg: awardDetailImg,
                            photoImg:photoImg,
                            windowText:windowText,
                            title:title,
                            subtitle:subtitle,
                            body:body
                        )
                        
                        self.awards.append(award)
                    }
                }
            }
        }
    }
    
    
    // Function 10: Fetch leftovers
    // Note: created a fetch function to avoid error between retriving data in VirtualPantryView and ReinventView
    @Published var leftovers: [UserVirtualPantry] = []
    
    func fetchLeftovers() {
        leftovers.removeAll()
        let db = Firestore.firestore()
        if let uuid = self.uuid {
            let ref = db.collection("userCollection").document(uuid).collection("virtualPantry")
            ref.getDocuments { snapshot, error in
                guard error == nil else{
                    print(error!.localizedDescription)
                    return
                }
                
                if let snapshot = snapshot {
                    for document in snapshot.documents{
                        let data = document.data()
                        
                        let id = UUID().uuidString
                        let itemName = data["itemName"] as? String ?? ""
                        let expDate = (data["expDate"] as? Timestamp)?.dateValue() ?? Date()
                        
                        let leftover = UserVirtualPantry(id: id, itemName: itemName, expDate: expDate)
                        self.leftovers.append(leftover)
                    }
                }
            }
        }
    }
    
    
    // Function 11: Add Kit Code
    
    func addKitCode(newKitCode: String){
        let db = Firestore.firestore()
        let ref = db.collection("userCollection").document(self.uuid!).collection("starterKit").document("kitCode") // name of the doccument
        // what is inside the doccument
        ref.setData(["kitCode": newKitCode]) { error in
            if let error = error {
                print(error.localizedDescription)
            }
        }
    }
    
    // Function 12: Retrieving starter kit data
    @Published var kitCodes: [StarterKit] = []
    
    func fetchKitCode() {
        kitCodes.removeAll()
        let db = Firestore.firestore()
        if self.uuid != nil {
            let ref = db.collection("userCollection").document(self.uuid!).collection("starterKit")
            ref.getDocuments { snapshot, error in
                guard error == nil else {
                    print(error!.localizedDescription)
                    return
                }
                
                if let snapshot = snapshot {
                    for document in snapshot.documents {
                        let data = document.data()
                        
                        let id = document.documentID
                        let kitCode = data["kitCode"] as? String ?? ""
                        
                        let starterKit = StarterKit(id: id, kitCode: kitCode)
                        self.kitCodes.append(starterKit)
                    }
                }
            }
        }
    }
    
    // Function 12: Retrieving starter kit data retrieving 1st information
    @Published var userKitCode: String = ""
    
    func fetchFirstKitCode() {
        userKitCode.removeAll()
        let db = Firestore.firestore()
        if let uuid = self.uuid {
            let ref = db.collection("userCollection").document(uuid).collection("starterKit").limit(to: 1)
            ref.getDocuments { snapshot, error in
                guard error == nil else {
                    print(error!.localizedDescription)
                    return
                }
                
                if let snapshot = snapshot {
                    for document in snapshot.documents {
                        let data = document.data()
                        
                        let kitCode = data["kitCode"] as? String ?? ""
                        self.userKitCode.append(kitCode)
                    }
                }
            }
        }
    }

    
}
