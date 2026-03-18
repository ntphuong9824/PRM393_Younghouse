Firestore rules:
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    function signedIn() {
      return request.auth != null;
    }

    function isAdmin() {
      return signedIn() &&
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == "admin";
    }

    match /users/{uid} {
      allow create: if signedIn() && request.auth.uid == uid;
      allow read, update: if signedIn() && (request.auth.uid == uid || isAdmin());
    }

    match /avatars/{uid} {
      allow read, write: if signedIn() && request.auth.uid == uid;
    }

    // Top-level guardians collection
    match /guardians/{guardianId} {
      allow read, write: if isAdmin() ||
        (signedIn() && resource.data.user_id == request.auth.uid) ||
        (signedIn() && request.resource.data.user_id == request.auth.uid);
    }

    // Subcollection guardians dưới users
    match /users/{uid}/guardians/{guardianId} {
      allow read, write: if isAdmin() || (signedIn() && request.auth.uid == uid);
    }

    match /notifications/{id} {
      // admin xem/gửi toàn bộ
      allow read, create: if isAdmin();

      // tenant chỉ đọc broadcast hoặc thông báo gửi riêng cho chính mình
      allow read: if signedIn() &&
        (resource.data.targetUserId == null || resource.data.targetUserId == request.auth.uid);

      // cho user tự mark đã đọc, admin có toàn quyền update
      allow update: if isAdmin() || (
        signedIn() &&
        request.resource.data.diff(resource.data).changedKeys().hasOnly(['readBy']) &&
        request.resource.data.readBy.hasAll(resource.data.readBy) &&
        request.resource.data.readBy.hasAny([request.auth.uid])
      );
    }
  }
}

realtimedatabase rules:
{
  "rules": {
    "users": {
      "$uid": {
        ".read": "auth != null && auth.uid == $uid",
        ".write": "auth != null && auth.uid == $uid"
      }
    }
  }
}