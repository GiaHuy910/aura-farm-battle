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
