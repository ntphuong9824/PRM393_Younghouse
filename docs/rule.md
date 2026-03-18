rules_version = '2';
service cloud.firestore {
match /databases/{database}/documents {

    // ===== FUNCTIONS =====
    function signedIn() {
      return request.auth != null;
    }

    function userDoc() {
      return get(/databases/$(database)/documents/users/$(request.auth.uid));
    }

    function isAdmin() {
      return signedIn() &&
        exists(/databases/$(database)/documents/users/$(request.auth.uid)) &&
        userDoc().data.role == "admin";
    }

    // ===== USERS =====
    match /users/{uid} {
      allow create: if signedIn() && request.auth.uid == uid;
      allow read, update: if signedIn() && (request.auth.uid == uid || isAdmin());
      allow delete: if isAdmin();
    }

    // ===== AVATARS =====
    match /avatars/{uid} {
      allow read, write: if signedIn() && request.auth.uid == uid;
    }

    // ===== GUARDIANS =====
    match /guardians/{guardianId} {
      allow create: if signedIn() &&
        request.resource.data.user_id == request.auth.uid;

      allow read: if isAdmin() ||
        (signedIn() && resource.data.user_id == request.auth.uid);

      allow update, delete: if isAdmin() ||
        (signedIn() && resource.data.user_id == request.auth.uid);
    }

    // Subcollection guardians
    match /users/{uid}/guardians/{guardianId} {
      allow read, write: if isAdmin() || (signedIn() && request.auth.uid == uid);
    }

    // ===== NOTIFICATIONS =====
    match /notifications/{id} {
      allow create: if isAdmin();

      allow read: if isAdmin() || (
        signedIn() &&
        (resource.data.targetUserId == null ||
         resource.data.targetUserId == request.auth.uid)
      );

      allow update: if isAdmin() || (
        signedIn() &&
        request.resource.data.diff(resource.data).changedKeys().hasOnly(['readBy']) &&
        request.resource.data.readBy.hasAll(resource.data.readBy) &&
        request.resource.data.readBy.hasAny([request.auth.uid])
      );

      allow delete: if isAdmin();
    }

    // ===== ROOMS =====
    match /rooms/{id} {
      allow read: if signedIn();
      allow create, update, delete: if isAdmin();
    }

    // ===== CHAT ROOMS =====
    match /chat_rooms/{id} {
      allow read, write: if signedIn();
    }

    // ===== CONTRACTS =====
    match /contracts/{id} {
      allow read: if signedIn();
      allow write: if isAdmin();
    }

    // ===== INVOICES =====
    match /invoices/{id} {
      allow read: if signedIn();
      allow write: if isAdmin();
    }

    // ===== PAYMENTS =====
    match /payments/{id} {
      allow read: if signedIn();
      allow write: if isAdmin();
    }

}
}