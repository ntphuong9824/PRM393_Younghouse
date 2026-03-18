# Young House - Database Schema (Firestore)

## 1. users
| Field | Type | Note |
|-------|------|------|
| id | String | PK (Firebase Auth UID) |
| email | String | |
| phone | String | |
| full_name | String | |
| avatar_url | String | |
| role | String | `admin` / `tenant` |
| landlord_id | String | FK → users.id (nếu là tenant, trỏ về admin quản lý) |
| date_of_birth | Timestamp | |
| id_number | String | Số CCCD/CMND |
| id_front_url | String | Ảnh mặt trước CCCD (base64 data URL: `data:image/jpeg;base64,...`) |
| id_back_url | String | Ảnh mặt sau CCCD (base64 data URL: `data:image/jpeg;base64,...`) |
| is_profile_confirmed | Boolean | Admin xác nhận hồ sơ |
| fcm_token | String | Firebase Cloud Messaging token |
| created_at | Timestamp | |
| updated_at | Timestamp | |

---

## 2. guardians (Người giám hộ) - Top-level collection
| Field | Type | Note |
|-------|------|------|
| id | String | PK Format: `{userId}_father` or `{userId}_mother` |
| user_id | String | FK → users.id |
| full_name | String | Họ tên người giám hộ |
| phone | String | Số điện thoại (9-11 digits) |
| relationship | String | Quan hệ: `bo` (bố), `me` (mẹ) |

**Note:** Guardian records are also stored in subcollection `users/{userId}/guardians` for backup/query purposes.

---

## 2.1 users/{userId}/guardians (Subcollection)
| Field | Type | Note |
|-------|------|------|
| id | String | Same as top-level: `{userId}_father` or `{userId}_mother` |
| user_id | String | FK → users.id |
| full_name | String | Họ tên người giám hộ |
| phone | String | Số điện thoại |
| relationship | String | `bo` hoặc `me` |

**Dual storage reason:** Ensures flexibility in querying:
- Query all tenants' guardians via top-level collection
- Query specific tenant's guardians via subcollection

## 3. properties (Tòa nhà)
| Field | Type | Note |
|-------|------|------|
| id | String | PK |
| landlord_id | String | FK → users.id |
| name | String | Tên tòa |
| address | String | Số nhà, tên đường |
| ward | String | Phường/Xã |
| district | String | Quận/Huyện |
| city | String | Tỉnh/Thành phố |
| description | String | Mô tả |
| total_rooms | Integer | Tổng số phòng |
| status | String | `active` / `inactive` |
| images | Array\<String\> | Danh sách URL ảnh tòa nhà (Firebase Storage) |
| created_at | Timestamp | |
| updated_at | Timestamp | |

---

## 3. rooms (Phòng)
| Field | Type | Note |
|-------|------|------|
| id | String | PK |
| property_id | String | FK → properties.id |
| current_tenant_id | String | FK → users.id (nullable) |
| current_contract_id | String | FK → contracts.id (nullable) |
| room_number | String | Tên/số phòng |
| floor | Integer | Tầng |
| area_sqm | Real | Diện tích (m²) |
| base_price | Real | Giá thuê |
| deposit_amount | Real | Tiền cọc |
| description | String | Mô tả (bao gồm tiện nghi: điều hòa, nóng lạnh...) |
| images | Array\<String\> | Danh sách URL ảnh (Firebase Storage) |
| status | String | `vacant` / `occupied` / `maintenance` |
| created_at | Timestamp | |
| updated_at | Timestamp | |

---

## 4. room_services (Dịch vụ phòng)
| Field | Type | Note |
|-------|------|------|
| id | String | PK |
| room_id | String | FK → rooms.id |
| service_name | String | Tên dịch vụ: `electric` / `water` / `internet` / `trash`... |
| unit | String | Đơn vị: `kWh` (điện theo số), `person` (dịch vụ khác theo đầu người) |
| price_per_unit | Real | Đơn giá |
| created_at | Timestamp | |
| updated_at | Timestamp | |

---

## 5. contracts (Hợp đồng)
| Field | Type | Note |
|-------|------|------|
| id | String | PK |
| room_id | String | FK → rooms.id |
| tenant_id | String | FK → users.id |
| landlord_id | String | FK → users.id |
| start_date | Timestamp | Ngày bắt đầu |
| end_date | Timestamp | Ngày kết thúc |
| co_tenants | Array\<String\> | Danh sách userId ở cùng |
| terms | String | Điều khoản hợp đồng |
| status | String | `active` / `expired` / `terminated` |
| pdf_url | String | Link file PDF hợp đồng |
| signed_at | Timestamp | |
| terminated_at | Timestamp | nullable |
| termination_reason | String | nullable |
| created_at | Timestamp | |
| updated_at | Timestamp | |

---

## 6. invoices (Hóa đơn)
| Field | Type | Note |
|-------|------|------|
| id | String | PK |
| contract_id | String | FK → contracts.id |
| room_id | String | FK → rooms.id |
| tenant_id | String | FK → users.id |
| landlord_id | String | FK → users.id |
| month | Integer | Tháng (1-12) |
| year | Integer | Năm |
| electric_prev | Integer | Chỉ số điện đầu kỳ |
| electric_curr | Integer | Chỉ số điện cuối kỳ |
| electric_price | Real | Đơn giá điện (lấy từ room_services) |
| rent_amount | Real | Tiền thuê tháng này (lấy từ rooms.base_price) |
| other_fees | Real | Phí khác (dịch vụ theo đầu người: nước, internet, rác...) |
| total_amount | Real | Tổng cộng |
| status | String | `unpaid` / `paid` / `overdue` |
| due_date | Timestamp | Hạn thanh toán |
| paid_at | Timestamp | nullable |
| payment_method | String | `cash` / `transfer` / `payos` |
| notes | String | Ghi chú |
| created_by | String | FK → users.id |
| created_at | Timestamp | |
| updated_at | Timestamp | |

---

## 7. invoice_services (Chi tiết dịch vụ trong hóa đơn)
| Field | Type | Note |
|-------|------|------|
| id | String | PK |
| invoice_id | String | FK → invoices.id |
| service_name | String | Tên dịch vụ |
| quantity | Real | Số lượng (số kWh hoặc số người) |
| unit_price | Real | Đơn giá |
| amount | Real | Thành tiền |
| note | String | |

---

## 8. payments (Thanh toán)
| Field | Type | Note |
|-------|------|------|
| id | String | PK |
| invoice_id | String | FK → invoices.id |
| tenant_id | String | FK → users.id |
| landlord_id | String | FK → users.id |
| amount | Real | Số tiền |
| method | String | `cash` / `transfer` / `payos` |
| note | String | |
| receipt_url | String | Ảnh biên lai |
| paid_at | Timestamp | |
| created_by | String | FK → users.id |

---

## 9. notifications
| Field | Type | Note |
|-------|------|------|
| id | String | PK |
| title | String | Tiêu đề |
| message | String | Nội dung |
| createdAt | Timestamp | |
| targetUserId | String | FK → users.id (null = gửi tất cả) |
| readBy | Array\<String\> | Danh sách userId đã đọc |

---

## 10. chat_rooms
| Field | Type | Note |
|-------|------|------|
| id | String | PK |
| room_id | String | FK → rooms.id |
| landlord_id | String | FK → users.id |
| tenant_id | String | FK → users.id |
| last_message | String | |
| last_message_at | Timestamp | |
| unread_landlord | Integer | Số tin chưa đọc của admin |
| unread_tenant | Integer | Số tin chưa đọc của tenant |
| created_at | Timestamp | |

---

## 11. messages
| Field | Type | Note |
|-------|------|------|
| id | String | PK |
| chat_room_id | String | FK → chat_rooms.id |
| sender_id | String | FK → users.id |
| content | String | Nội dung tin nhắn |
| type | String | `text` / `image` / `file` |
| file_url | String | nullable |
| sent_at | Timestamp | |
| is_read | Boolean | |

---

## Quan hệ tổng quan

```
users (admin)
  └── properties (tòa nhà)
        └── rooms (phòng)
              ├── room_services (dịch vụ: điện theo số, các dịch vụ khác theo đầu người)
              ├── contracts → users (tenant)
              │     └── invoices
              │           ├── invoice_services
              │           └── payments
              └── chat_rooms
                    └── messages

notifications (gửi từ admin → tenant)
```
