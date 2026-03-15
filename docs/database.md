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
| id_front_url | String | Ảnh mặt trước CCCD |
| id_back_url | String | Ảnh mặt sau CCCD |
| is_profile_confirmed | Boolean | Admin xác nhận hồ sơ |
| fcm_token | String | Firebase Cloud Messaging token |
| created_at | Timestamp | |
| updated_at | Timestamp | |

---

## 2. properties (Tòa nhà)
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
| description | String | Mô tả |
| amenities | Array\<String\> | Tiện nghi: điều hòa, nóng lạnh... |
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
| service_name | String | Tên dịch vụ: điện, nước, internet... |
| unit | String | Đơn vị: kWh, m³, người, tháng |
| price_per_unit | Real | Đơn giá |
| is_metered | Boolean | Có đồng hồ đo không |
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
| monthly_rent | Real | Giá thuê hàng tháng |
| deposit | Real | Tiền cọc |
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
| electric_price | Real | Đơn giá điện |
| water_prev | Integer | Chỉ số nước đầu kỳ |
| water_curr | Integer | Chỉ số nước cuối kỳ |
| water_price | Real | Đơn giá nước |
| rent_amount | Real | Tiền thuê tháng này |
| other_fees | Real | Phí khác (gửi xe, rác...) |
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
| quantity | Real | Số lượng |
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

## 9. meter_readings (Chỉ số đồng hồ)
| Field | Type | Note |
|-------|------|------|
| id | String | PK |
| room_id | String | FK → rooms.id |
| recorded_by | String | FK → users.id |
| type | String | `electric` / `water` |
| value | Integer | Chỉ số hiện tại |
| previous_value | Integer | Chỉ số kỳ trước |
| image_url | String | Ảnh chụp đồng hồ |
| note | String | |
| reading_month | Integer | |
| reading_year | Integer | |
| recorded_at | Timestamp | |

---

## 10. notifications
| Field | Type | Note |
|-------|------|------|
| id | String | PK |
| sender_id | String | FK → users.id |
| target_user_id | String | FK → users.id (nullable = gửi tất cả) |
| target_role | String | `all` / `tenant` / `admin` |
| title | String | |
| body | String | |
| type | String | `general` / `invoice` / `contract` / `maintenance` |
| reference_id | String | ID của invoice/contract liên quan |
| reference_type | String | `invoice` / `contract` / `room` |
| is_read | Boolean | |
| created_at | Timestamp | |

---

## 11. chat_rooms
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

## 12. messages
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
              ├── room_services (dịch vụ)
              ├── contracts → users (tenant)
              │     └── invoices
              │           ├── invoice_services
              │           └── payments
              ├── meter_readings
              └── chat_rooms
                    └── messages

notifications (gửi từ admin → tenant)
```
