Api : user/getTickets
input : header Cookie
output: TicketsResponse
handler : getTicketsHandler

Api : user/getAvatar
input : header Cookie
output: AvatarResponse
handler : getAvatarHandler

Api : user/getCurrentSkills
input : header Cookie
output: CurrentSkillsResponse
handler : getCurrentSkillsHandler

Api : user/getOwnedSkills
input : header Cookie
output: OwnedSkillsResponse
handler : getOwnedSkillsHandler

Api : user/getCurrentClothes
input : header Cookie
output: CurrentClothesResponse
handler : getCurrentClothesHandler

Api : user/getOwnedClothes
input : header Cookie
output: OwnedClothesResponse
handler : getOwnedClothesHandler

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