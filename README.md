<div align="center">
  <a href="http://localhost:4000">
    <picture>
      <source media="(prefers-color-scheme: dark)" srcset="./client/public/game-logo-white.png">
      <source media="(prefers-color-scheme: light)" srcset="./client/public/game-logo-black.png">
      <img alt="Aura Farm Battle" src="./client/public/game-logo.png" width="35%">
    </picture>
  </a>
</div>

<div align="center">
    <h5>A funny turn-based solo game to challenge with your friends and gambling a lot</h5>
</div>

<div align="center">
  <a href="https://pypi.org/project/langchain/#history" target="_blank"><img src="https://img.shields.io/pypi/v/langchain?label=%20" alt="Version"></a>
</div>

## Web Status

🔴 INACTIVE

## Table of contents

- [Web Status](#web-status)
- [Table of contents](#table-of-contents)
- [Requirements](#requirements)
- [Quick Start](#quick-start)
- [Tech Stacks](#tech-stacks)
- [Contribution](#contribution)
  - [Cach khoi tao project](#cach-khoi-tao-project)
  - [Rules](#rules)
    - [Lam sao de lay code sau khi 1 nguoi lam xong](#lam-sao-de-lay-code-sau-khi-1-nguoi-lam-xong)
    - [đang o nhánh phu](#đang-o-nhánh-phu)
    - [để push code cua minh len](#để-push-code-cua-minh-len)
    - [lan dau mang code ve](#lan-dau-mang-code-ve)

## Requirements

- Make sure you installed [Nodejs](https://nodejs.org/en) for npm
- Make sure you installed [GHCup](https://haskell.org) for compiling haskell
- Make sure you installed [MongoDB](https://www.mongodb.com/try/download/community) either MongoDBcompass or Mongosh

## Quick Start

- Clone the repo: `git clone https://github.com/GiaHuy910/aura-farm-battle`
- In the client directory : `npm install`
- Run the client : `npm run dev`
  Front end will be hosting locally on port `4000` by default
- In the server directory : `cabal build`
- Run the server : `cabal run`
  Backend end will be hosting locally on port `3001` by default

## Tech Stacks

| Category | Technology                                         |
| -------- | -------------------------------------------------- |
| Frontend | Next.js, React, TypeScript, Bootstrap              |
| Backend  | Cabal, Haskell, Servant, Warp                      |
| Database | MongoDB                                            |
| Others   | RESTful API, MVC model, Client-Server architecture |

## Contribution

Thank you to all the people in the team who already contributed to aura-farm-battle!

<p align="center">
<a href="https://github.com/H-Hisoka"><img src="https://github.com/H-Hisoka.png" width="80px;" style="border-radius: 50%;" alt=""/></a>
<a href="https://github.com/HHai2006"><img src="https://github.com/HHai2006.png" width="80px;" style="border-radius: 50%;" alt=""/></a>
<a href="https://github.com/TheyCalledMeKC"><img src="https://github.com/TheyCalledMeKC.png" width="80px;" style="border-radius: 50%;" alt=""/></a>
<a href="https://github.com/GiaHuy910"><img src="https://github.com/GiaHuy910.png" width="80px;" style="border-radius: 50%;" alt=""/></a>
<a href="https://github.com/tukhidonglai"><img src="https://github.com/tukhidonglai.png" width="80px;" style="border-radius: 50%;" alt=""/></a>
</p>

And thank you to the people whom assets was borrowed from is credited here (but not have asked so shushhhh):

- First 30s of "F4M] Your Yandere Bully Forces You Into Her Dorm Room || ASMR Roleplay" on [Youtube](https://www.youtube.com/watch?v=lCIyrje1Nb0).
- The thumbnail of "The Rise of Mommy ASMR: Comfort in a Click ft. ‪@EinAudios‬" on [Youtube](https://www.youtube.com/watch?v=uVUgbiABZ_8)
- "Yuta Okkotsu - Jujutsu Kaisen.
  En mode Asian Squat" Art of [animathish](https://www.instagram.com/p/DXqsFLRiJN_/) on Instagram.
- "Rankbreaker" Item from [AOV-ArenaOfValor](https://www.arenaofvalor.com/)
- "Do Phu Quy" for using your image ingame, Vietnamese singer [instagram](https://www.instagram.com/dophuqui/)
- "Wowkie Zhang" for using your image ingame, Chinese singer [Youtube](https://www.youtube.com/playlist?list=PLrguboq_L_r5WMWt8vNoFYsqjRBemH75t)
- "KHÔNG CẦN LO CHO TAO - MCK (OFFICIAL MUSIC VIDEO)" for using your image ingame, [Youtube](https://www.youtube.com/watch?v=WmHIk7QNjac&list=RDWmHIk7QNjac&start_radio=1)

### Cach khoi tao project

- PHAI CO NODEJS (hay suy nghi xem mun tai hay khong), an vao day : [nodejs](https://nodejs.org/en)
- PHAI CO HASKELL COMPILER : [GHCup](https://haskell.org)
- PHAI CO MongodbCompass : [MongodbCompass](https://www.mongodb.com/try/download/community)

- B1 : clone github ve bang lenh nay :`git clone https://github.com/GiaHuy910/aura-farm-battle`
  B2 : vao trong thu muc client (trong terminal day nha) dung lenh nay : `npm install`
  B3 : vao trong thu muc server (trong terminal) dung lenh nay : `cabal build`
  B4 : vao trong thu muc client chay : `npm run dev`
  B5 : vao trong thu muc server chay : `cabal run`

server se duoc host o 3001
front end se duoc host o 4000
len google va search `http://localhost:4000` va enjoy

### Rules

- AE phai push len nhanh rieng cua minh truoc khi t merge vao main cho ae
- AE co the push nhanh cua minh, con nhanh main phai tao pull request va dc review truoc khi merge

#### Lam sao de lay code sau khi 1 nguoi lam xong

- Nguoi A lam xong phan dau, push code len nhanh rieng, va tao pull request
- Huy se review va merge no vao main
- Nguoi B tiep tuc lam thi, len local,nhảy qua nhánh main, git pull origin main ve, sau do nhay qua nhanh phu de lam tiep và git merge main
- Va lam tiep

---

#### đang o nhánh phu

- git checkout main
- git pull origin main
- git checkout <nhánh phụ>
- git merge main

---

#### để push code cua minh len

- dang o nhanh phu
- git add (dung folder)
- git commit -m "comment gi do"
- git push -u origin (ten nhanh phu) (lan dau)
- git push (lan sau)

---

#### lan dau mang code ve

- tao folder chua
- nhay vao folder
- git clone (url github)
- nhay vao folder
- git pull origin main
- git checkout -b (ten nhanh phu moi)
- git add .
- git commit -m "first commit"
- git push -u origin (tennhanh phu cua minh)
