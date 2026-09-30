task 1 : ... quên r
task 2 : thêm daatbase va api moơ trong doc
task 3 :

- an cabal build se hiên cac loi va warning sau

- warning rooms.hs line 72 co tao validusers nhung khong su dung, ham create room cung khong truyen owner_id
- loi t2 o line 104 roomcontroller
- warning line 131 User model co the bo qua k can sua, ly do thi ong doc warning la hieu nhe
- warning import monad o line 10 authcontroller la vo dung, system.random line 16 cung vay
- warning o line 18 thi tuy thoi, neu ong import san de sau nay lam gacha thi cu giu lai

#### do la warning con day la loi cua ong an

- chua export cac ham can dung trong authcontroller
- roomcontroller, usercontroller thi chua khai bao module export
- chua khai bao module cho tui model

#### con gio la task ong chua lam

- ong chua projectile query cho dong query (ong chua ranh thi tutu con ranh thi lam nhanh nha, hoac ong khong hieu la gi thi ong hoi tui nhe)
