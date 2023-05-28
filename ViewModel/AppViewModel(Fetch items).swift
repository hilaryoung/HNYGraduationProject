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
    
}
