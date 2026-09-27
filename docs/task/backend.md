Api : auth/register
input : RegisterRequest
output: header AuthResponse
handler : registerHandler

Api : auth/login
input : LoginRequest
output: header AuthResponse
handler : loginHandler

Api : auth/logout
input : header Cookie
output: header AuthResponse
handler : logoutHandler

Api : auth/me
input : header Cookie
output: MeResponse
handler : meHandler

Api : room/create
input : header Cookie, CreateRoomRequest
output: CreateRoomResponse
handler : createRoomHandler