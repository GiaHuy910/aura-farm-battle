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
