# Cập nhật API Backend (Auth & Room)

## 1. API: `POST /auth/register`
*   **Đầu vào:** Nhận `username` và `password` từ Body[cite: 8].
*   **Đầu ra:** Trả về `AuthResponse` kèm theo Header `Set-Cookie`[cite: 8].
*   **Hàm xử lý:** Hàm `registerUser` giờ sẽ trả về trực tiếp `user_id` mới tạo[cite: 4, 8]. Controller lấy ID đó truyền thẳng vào `createSession`[cite: 8].

## 2. API: `POST /auth/login`
*   **Đầu vào:** Nhận `username` và `password` từ Body[cite: 8].
*   **Đầu ra:** Trả về `AuthResponse` kèm theo Header `Set-Cookie`[cite: 8].
*   **Hàm xử lý:** Hàm `loginUser` được cập nhật để trả về luôn `user_id` nếu mật khẩu đúng[cite: 4, 8]. Truyền thẳng ID đó vào `createSession` (đã xóa code query thừa)[cite: 8].

## 3. API: `POST /auth/logout`
*   **Đầu vào:** Yêu cầu thêm Header `Cookie`[cite: 2, 8].
*   **Đầu ra:** Trả về `AuthResponse` kèm Header `Set-Cookie` rỗng (Max-Age=0) để xoá ở client[cite: 8].
*   **Hàm xử lý:** Phân tích `session_id` từ Cookie và gọi `deleteSession`[cite: 8].

## 4. API: `GET /auth/me`
*   **Đầu vào:** Yêu cầu thêm Header `Cookie`[cite: 2, 8].
*   **Đầu ra:** Trả về `MeResponse` (thông báo + thông tin user)[cite: 8].
*   **Hàm xử lý:** Lấy `user_id` từ session đang đăng nhập, sau đó gọi hàm mới `getUserById` để lấy toàn bộ thông tin tài khoản[cite: 4, 8].

## 5. API: `POST /room/create`
*   **Đầu vào:** 
    *   Bắt buộc gửi kèm Header `Cookie`[cite: 7].
    *   Body rút gọn: Xóa trường `owner_id` (client không cần gửi nữa)[cite: 7].
*   **Đầu ra:** Cấu trúc đổi sang `CreateRoomResponse`[cite: 1, 7].
*   **Hàm xử lý:** Tự động cắt `Cookie` lấy `session_id`, truy xuất DB lấy `user_id` hiện tại và tự động gán nó làm `owner_id` cho phòng mới[cite: 7].