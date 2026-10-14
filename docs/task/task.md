### task 1 : ... quên r

### task 2 : thêm daatbase va api moơ trong doc

### task 3 :

- an cabal build se hiên cac loi va warning sau

- warning rooms.hs line 72 co tao validusers nhung khong su dung,
- loi t2 o line 104 roomcontroller
- warning line 131 User model co the bo qua k can sua, ly do thi ong doc warning la hieu nhe
- warning import monad o line 10 authcontroller la vo dung, system.random line 16 cung vay
- warning o line 18 thi tuy thoi, neu ong import san de sau nay lam gacha thi cu giu lai

##### do la warning con day la loi cua ong an

- chua export cac ham can dung trong authcontroller
- roomcontroller, usercontroller thi chua khai bao module export
- chua khai bao module cho tui model

##### con gio la task ong chua lam

- ong chua projectile query cho dong query (ong chua ranh thi tutu con ranh thi lam nhanh nha, hoac ong khong hieu la gi thi ong hoi tui nhe)
- ong hay sua api auth/me, bay gio hay tra ve khong chi userid username ma con them avatar, tickets, owned_skills,owned_clothes nha, tui cung da sua tren doc ong khang

### task 4

- chua export cac ham can dung trong authcontroller
- roomcontroller, usercontroller thi chua khai bao module export
- chua khai bao module cho tui model
-
- ong da projectile cac query nma con thieu 1 so, tui vi du 1 cai nha,line 103 user model, muc dich cua viec di vao db lay ra la chi de check xem no co ton tai hay khong, vi the ong co the chi can lay ra moi id cua no thoi thay vi toan bo field

### task 5 6 qua roi

### task 7

- chay cabal build ong se thay warning, sua cac warning do di
- warning dong thu 42 o session.hs hinh nhu la do ten bien trung voi ten field, chac la ong lam ten bien khac lai xem no van hoat dong bth khong nha

### task 8

- dau tien la sua lai cho dung ten api user/equip-item
- lam 1 viec nay nha, ong hay sap xep toan bo code trong controller lai sao cho request,response,handler cua moi api dung gan nhau cho de nhin hon (bay h la no dang request dung 1 ben, handler dung 1 ben kieu v)

### task 9

- them remaining_tickets vao trong response cua api user/gacha (nam chung voi addedItem, status,message)

### task 10

- tui ms check lai logic cua api pool thi co ty van de, viec ong dang cho clothe : [Clothe] voi skill : [Skill] khien cho no tao ra cac field khong can thiet nhu in_pool, item_name rong de tra ve luo

## BIG TASK 11

- them field status : string. default "waiting" cho database room, api tao phong, cac api co tra ve phong thi tra ve cho no luon

- dau tien la ong viet file Config/BaseMultiplier.hs theo file game-stats-formulas.txt o ben canh
- sau do la minh phai viet ham khoi tao cho clothe va skill ( de co the viet script test/kiem tra), sau do viet script de khoi tao ra 51 skills, va 45 clothes ma chung ta da co (nho phai kiem tra trong database thieu cai nay moi chay cai do truoc)
- hau nhu cac field moi trong acc,skill,ult,user deu co tra ve client nen hay them vao cac api co lien quan ( cai nao can moi tra ra nha tr),
- chi khi da sua xong database cua clothes vs skill thi moi viet tiep user. minh se them cac thuoc tinh cua user vao model truoc, sau do them thuoc tinh vao phan khoi tao.
- Tao 1 ham dung de tinh final_stats cho user, bang cach lay array equipped_clothes cua user, tim ra thong tin cua tung clothe va lay bonus_stats.aura cua tung clothe cong vao nhau de ra bonus_stats cuoi cung , hay lay bonus_stats + base_stats de ra duoc final_stats, return xong thi ra ngoai thay thay doi gia tri ban dau "bonus_stats" va "final_stats" cua user la xong,
- sau khi xong cac buoc do thi phai xoa toan bo database, chay lai server, chay client va thu moi chuc nang xem co cho nao hong hoc hay k da roi moi qua buoc tiep theo - lam room.
- neu qua roi thi bat dau voi viec viet websocket( tutu thoi kieu gi cung chua toi)

#### task 12

- bay gio api pool chi tra ve
- clothe : clothe_id,clothe_name,rarity
- skill : skill_id,skill_name,rarity
- gio ong hay tra ra them
- clothe : clothe_id,clothe_name,rarity,aura_bonus
- skill : skill_id,skill_name,rarity,energy_consumption,energy_recovery,aura_multiplier,effect

#### task 13

- Thiet lap model GachaHistory, xem kdl ben file json ben kia
- Ghi chú model : "\_id" la id mac dinh cua monôdb, khong can khai bao, no se tu tao khi minh tao 1 document
- api gacha-history/
- method : GET
- hoan toan khong gui body request, co header cookie, param query co "limit" = Int mac dinh 6 va "cursor" = "" | "\_id"
- response request xem file json ten la response
- ghi chu api : input cua api nay se hoi khac ty voi cac api ong da lam, luc truoc minh thuong hay lay input trong request body nen o co the lay dau vao ...Request tuy thich. con bay gio input cua minh se nam trong param query, chua hai thuoc tinh limit va cursor, cursor co 2 trang thai , 1 la "" khi lan dau lay data nen co tinh gui string rong,2 la "\_id " la tra ra \_id cua item cuoi cung trong list ma ong tra ra user
- ghi chu response : nextCursor la tra ve \_id cua item cuoi cung trong list ma ong tra ve de front end co the lay de gui tiep cho ong trong api tiep theo
- ghi chu cach hoat dong : Khi gacha ra ket qua thi phai luu vao database GachaHistory, moi 1 item 1 document, x10 thi 10 item do deu se co cung 1 thoi gian createdAt, khi da co trong data. Khi goi api gacha-history/ ong phai lay header kiem tra user co ton tai khong, neu khong tra loi 401 Unauthorized, neu co lay param query trich xuat ra duoc limit va cursor, limit dinh nghia 1 lan lay bao nhieu item, cursor dinh nghia \_id cua item cuoi cung, neu nhu cursor la chuoi rong thi ong coi do la lay cac item dau tien, neu cursor= "\_id cua 1 history nao do" thi dung syntax $lt de lay tiep cac item co \_id nho hon \_id hien tai
- khi nao database gacha history da xuat hien trong mongodbcompass cua ong roi thi ong vao shell cua no chay cau lenh nay : db.gachahistories.createIndex({ user_id: 1, item_type: 1, \_id: -1 })
- ghi chu cuoi : ong se query de tim ra document dua tren user id, itemtype va \_id va cursor( nho neu cursor trong thi khong can phai cho vao)
- db.gacha_histories.find({
  user_id: "b3b1c2d3-e4f5-5678-abcd-ef1234567890",
  item_type: "clothe",
  \_id: { $lt: ObjectId(cursor) }
  })
  .sort({ \_id: -1 })
  .limit(20)
