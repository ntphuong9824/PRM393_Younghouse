# Firestore Security Rules

Paste vào Firebase Console → Firestore Database → Rules

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // Tạm thời cho phép tất cả (dev only)
    match /{document=**} {
      allow read, write: if true;
    }
  }
}
```

> ⚠️ Rule trên chỉ dùng khi dev/test. Trước khi release cần thay bằng rule chặt hơn.
