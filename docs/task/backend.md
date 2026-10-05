Api : user/equipped-skills
input : header Cookie
output: EquippedSkillsResponse
handler : getEquippedSkillsHandler

Api : user/equipped-clothes
input : header Cookie
output: EquippedClothesResponse
handler : getEquippedClothesHandler

Api : user/tickets
input : header Cookie
output: TicketsResponse
handler : getTicketsHandler

Api : user/avatar
input : header Cookie
output: AvatarResponse
handler : getAvatarHandler

Api : gacha/x1
input : header Cookie
output: GachaResponse
handler : gachaX1Handler

Api : gacha/x10
input : header Cookie
output: GachaResponse
handler : gachaX10Handler

Api : gacha/skills/x1
input : header Cookie
output: GachaResponse
handler : gachaSkillX1Handler

Api : gacha/skills/x10
input : header Cookie
output: GachaResponse
handler : gachaSkillX10Handler

Api : room/create
input : CreateRoomRequest
output: CreateRoomResponse
handler : createRoomHandler

Api : room/getRooms
input : none
output: [RoomSummary]
handler : getRoomsHandler

Api : room/joinRoom
input : JoinRoomRequest
output: StatusResponse
handler : joinRoomHandler

Api : room/leave
input : LeaveRoomRequest
output: StatusResponse
handler : leaveRoomHandler

### task 6

Api : user/owned-items
input : header Cookie
output: OwnedItemsResponse
handler : getOwnedItemsHandler

Api : pool
input : header Cookie
output: PoolResponse
handler : getPoolHandler