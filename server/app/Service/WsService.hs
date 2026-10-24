{-# LANGUAGE OverloadedStrings #-}

module Service.WsService
  ( notifyPlayerJoined
  , joinRoom
  , handleLeave
  , startGame
  , onDisconnect
  ) where

import           Control.Concurrent (forkIO, threadDelay)
import           Control.Monad (forM_, unless, when)
import           Data.Aeson (object, (.=))
import           Data.Maybe (isJust)
import           Data.Text (Text)
import           Ws.Env
import qualified Ws.Hub as Hub
import           Ws.Message
import           Ws.Types

-- Chỉ báo cho WebSocket. Dùng khi REST join của bạn đã tự ghi DB xong.
notifyPlayerJoined :: Env -> RoomId -> UserId -> IO ()
notifyPlayerJoined env rid uid = do
  p <- playerValue (envStore env) uid False
  Hub.broadcast (envHub env) rid (msg "room.player_joined" (object ["guest" .= p]))

-- Ghi DB (atomic) rồi báo WebSocket. Dùng nếu muốn REST join đi qua đây luôn.
joinRoom :: Env -> RoomId -> UserId -> IO Bool
joinRoom env rid uid = do
  ok <- rsAddGuest (envStore env) rid uid
  when ok (notifyPlayerJoined env rid uid)
  pure ok

-- Dùng chung cho: nút thoát (REST), room.leave (WS), và hết grace period lúc đang chờ.
--   * Đang đánh mà thoát: xử thua trước, rồi mới thoát.
--   * Chủ thoát: xoá phòng, báo room.closed, đóng mọi socket trong phòng.
--   * Khách thoát: bỏ ghế bên phải, báo room.player_left.
--       Nếu trận đã bắt đầu/kết thúc và chủ phòng không còn ở đó thì dọn luôn phòng.
--   * user không thuộc phòng: bỏ qua (REST nên trả lỗi trước khi gọi vào đây).
handleLeave :: Env -> RoomId -> UserId -> IO ()
handleLeave env rid uid = do
  mRoom <- rsGetRoom st rid
  forM_ mRoom $ \room -> do
    when (riStatus room == Playing && isMember uid room) $
      forfeit env room uid
    if uid == riOwner room
      then do
        rsDeleteRoom st rid
        Hub.broadcast hub rid (msg "room.closed" (object []))
        Hub.closeRoom hub rid
      else when (riGuest room == Just uid) $ do
        rsRemoveGuest st rid
        Hub.closeUser hub rid uid
        Hub.broadcast hub rid (msg "room.player_left" (object ["userId" .= uid]))
        -- Phòng đang chờ thì chủ phòng vẫn cần nó. Còn sau khi đã đánh, nếu chủ phòng
        -- đã rớt mạng từ trước thì không còn ai cần phòng này nữa.
        when (riStatus room /= Waiting) $ deleteIfAbandoned env rid
  where
    st  = envStore env
    hub = envHub env

-- Chỉ chủ phòng bắt đầu được, khi phòng đang chờ và đã có khách.
startGame :: Env -> RoomId -> UserId -> IO ()
startGame env rid uid = do
  mRoom <- rsGetRoom (envStore env) rid
  forM_ mRoom $ \room ->
    when (riStatus room == Waiting && uid == riOwner room && isJust (riGuest room)) $ do
      rsSetStatus (envStore env) rid Playing
      -- TODO: server tự tải chỉ số + trang bị của hai người từ DB, tính chỉ số cuối,
      --       dựng state trận (HP, lượt đi) và đưa vào game.start
      Hub.broadcast (envHub env) rid (msg "game.start" (object []))

-- Socket đóng (rớt mạng, đóng tab, F5...). Chưa xoá ngay: chờ grace period.
onDisconnect :: Env -> RoomId -> UserId -> Int -> IO ()
onDisconnect env rid uid cid = do
  wasCurrent <- Hub.unregisterIfCurrent (envHub env) rid uid cid
  -- False: socket này đã bị tab mới thay thế hoặc bị chủ động đóng, không phải rớt mạng
  when wasCurrent $ do
    Hub.broadcast (envHub env) rid (msg "room.player_offline" (object ["userId" .= uid]))
    tid <- forkIO $ do
      threadDelay (envGraceSecs env * 1000000)
      onGraceExpired env rid uid
    Hub.setTimer (envHub env) rid uid tid

onGraceExpired :: Env -> RoomId -> UserId -> IO ()
onGraceExpired env rid uid = do
  Hub.dropTimer (envHub env) rid uid
  -- Kiểm tra lại: có thể vừa quay lại đúng lúc timer chạy xong
  online <- Hub.isOnline (envHub env) rid uid
  unless online $ do
    mRoom <- rsGetRoom (envStore env) rid
    forM_ mRoom $ \room -> case riStatus room of
      Playing -> forfeit env room uid            -- đang đánh: xử thua, giữ phòng để người kia xem kết quả
      _       -> handleLeave env rid uid         -- đang chờ hoặc đã xong: như bấm thoát
    -- Sau khi xử lý, nếu không còn ai online (và không ai đang chờ quay lại) thì dọn phòng.
    -- Ví dụ: trận đang đánh mà cả hai cùng rớt mạng, hoặc người thắng đã đóng tab.
    deleteIfAbandoned env rid

-- Bên bỏ cuộc thua, trận sang Finished, báo cho cả phòng
forfeit :: Env -> RoomInfo -> UserId -> IO ()
forfeit env room loser = do
  let winner = if loser == riOwner room then riGuest room else Just (riOwner room)
  rsSetStatus (envStore env) (riId room) Finished
  Hub.broadcast (envHub env) (riId room)
    (msg "game.finished" (object ["winnerId" .= winner, "reason" .= ("forfeit" :: Text)]))

-- Phòng bị bỏ hoang: không còn ai online VÀ không còn ai đang trong thời gian chờ quay lại.
-- Điều kiện thứ hai quan trọng: nếu một người chỉ đang F5 thì timer của họ còn đó, chưa được xoá phòng.
-- Người hết hạn chờ SAU CÙNG sẽ là người xoá phòng.
deleteIfAbandoned :: Env -> RoomId -> IO ()
deleteIfAbandoned env rid = do
  online  <- Hub.onlineUsers (envHub env) rid
  pending <- Hub.hasTimer (envHub env) rid
  when (null online && not pending) $
    rsDeleteRoom (envStore env) rid