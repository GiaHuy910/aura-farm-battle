# Chi tiết thay đổi Backend & Database (Auth & Room)

Tài liệu này tổng hợp các thay đổi thực tế trong logic xử lý và cấu trúc dữ liệu để team Router và Frontend nắm thông tin.

## 1. Database (`Game_database`)
**File `User.hs`:**
*   **Hàm mới:** Thêm `getUserById :: Text -> IO (Maybe User)` để truy vấn thông tin người dùng trực tiếp bằng ID. Thêm `verifyUserLogin`.
*   **Tối ưu Output:** 
    *   Cập nhật `RegisterStatus` thành `Success Text | UserAlreadyExists` để trả về ngay `user_id` khi tạo tài khoản thành công.
    *   Cập nhật `LoginStatus` thành `LoginSuccess Text | LoginFailed` để gom luôn `user_id` trả về khi kiểm tra mật khẩu hợp lệ.

**File `Session.hs`:**
*   **Cấu trúc dữ liệu:** Thay đổi model `Session` để lưu trường `user_id` thay vì `username`.
*   **Hàm xử lý:**
    *   Cập nhật `createSession` để nhận đầu vào là `uId` (kiểu `Text`).
    *   Tối ưu `getUserBySession` để đọc thẳng `user_id` từ bảng `sessions` (không cần quét lại bảng `user` như trước).

## 2. Controllers
**File `RoomController.hs`:**
*   **Input Body:** Gỡ bỏ hoàn toàn việc nhận `owner_id` từ Request Body của client trong cấu trúc `CreateRoomRequest`.
*   **Logic Tạo Phòng:** Nâng cấp `createRoomHandler` để nhận Header Cookie, giải mã lấy `session_id`, truy vấn DB lấy `user_id` và tự động gán giá trị đó vào `owner_id` cũng như `user_ids` của phòng mới.
*   **Helper:** Thêm hàm phụ trợ `parseSessionId` để tự cắt chuỗi Cookie.

**File `AuthController.hs`:**
*   **Output:** Giữ nguyên cấu trúc `AuthResponse` gồm `status :: String` và `message :: String` (trả về câu thông báo tiếng Việt).
*   **Logic Đăng Ký & Đăng Nhập (Quan trọng):** 
    *   Sửa lỗi truyền nhầm tham số: `createSession` hiện tại đã nhận chính xác biến `user_id` (được hứng từ `Success newUserID` và `LoginSuccess uID`) thay vì `username`.
    *   Tối ưu hiệu suất: Xóa bỏ hoàn toàn các đoạn code gọi hàm `getUser` thừa thãi.
*   **Logic Xác Thực (`/auth/me`):** Trích xuất `user_id` từ session rồi dùng hàm mới `getUserById` để lấy và trả về toàn bộ thông tin người dùng.
*   **Helper:** Tích hợp hàm `parseSessionId`.

## 3. Yêu cầu cập nhật dành cho team Router
Để code biên dịch thành công, hai file Router cần được cập nhật khớp với Controller:
*   **`RoomRouter.hs`:** API `create` cần bổ sung `Header "Cookie" String` và đổi kiểu Output sang `CreateRoomResponse`.
*   **`AuthRouter.hs`:** Các API cần bổ sung `Header "Cookie" String` cho đầu vào (với `me`, `logout`) và `Headers '[Header "Set-Cookie" String]` cho đầu ra (với `register`, `login`, `logout`).