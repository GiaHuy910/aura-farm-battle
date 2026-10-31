"use client";

import { useParams, useRouter } from "next/navigation";
import { useEffect, useRef, useState } from "react";

import page from "@/styles/page.module.css";
import { useAuth } from "@/contexts/auth/useAuth";
import { useRoomSocket } from "@/websocket/useRoomSocket";
import { useRooms, leaveRoom } from "@/api/rooms";

import PlayerSlot from "@/components/PlayerSlot";
import BattleScreen from "@/components/battle/BattleScreen";

export default function RoomIdPage() {
  const { id } = useParams<{ id: string }>();
  const router = useRouter();
  const { user, fetchMe } = useAuth();
  // const { mutate } = useRooms();

  const { room, game, connection, closedReason, error, send } =
    useRoomSocket(id);
  const [leaving, setLeaving] = useState(false);

  const refreshedMatch = useRef<string | null>(null);
  const settledMatchId = game?.result?.matchId ?? null;
  useEffect(() => {
    if (settledMatchId && refreshedMatch.current !== settledMatchId) {
      refreshedMatch.current = settledMatchId;
      fetchMe();
    }
  }, [settledMatchId, fetchMe]);

  const meId = user?.user_id;
  const isOwner = !!meId && room?.owner.id === meId;
  const canStart =
    isOwner && room?.status === "waiting" && !!room.guest?.online;
  const inBattle = !!room && room.status !== "waiting" && !!game;

  const handlePressFight = () => send("room.start");

  const handleLobby = () => {
    fetchMe();
    router.push("/rooms");
  };

  const handleLeave = async () => {
    if (
      game?.phase === "battle" &&
      !window.confirm("Leaving now makes you lose the match. Leave?")
    )
      return;
    setLeaving(true);
    try {
      const leaveSend: leaveRoomRequest = { room_id: id };
      const data = await leaveRoom(leaveSend);
      if (data.status === "success") handleLobby();
      else setLeaving(false);
    } catch {
      setLeaving(false);
    }
  };

  return (
    <div
      className={`${page.roomsPage} position-relative mb-3 mt-1 px-lg-5 py-3 d-flex justify-content-center align-items-center flex-column container w-100 h-100`}
      style={{
        backgroundColor: "#eae2c7",
        border: "10px solid rgba(178, 140, 15, 0.69)",
        padding: "10px",
      }}
    >
      {closedReason && !leaving ? (
        <div className="text-center">
          <div className="alert alert-warning">{closedReason}</div>
          <button className="btn btn-primary" onClick={handleLobby}>
            LOBBY
          </button>
        </div>
      ) : !room ? (
        <div className="text-center">
          <div className="spinner-border" role="status" />
          <p className="mt-3">Connecting To Room</p>
        </div>
      ) : (
        <>
          {connection === "reconnecting" && (
            <div className="alert alert-warning py-1 px-3">
              Lost Connection, Retrying...
            </div>
          )}

          {inBattle && meId ? (
            <>
              <BattleScreen
                room={room}
                game={game}
                meId={meId}
                send={send}
                error={error}
                onLeave={handleLeave}
                leaving={leaving}
              />
              {game.phase === "battle" && (
                <button
                  className="btn btn-outline-danger mt-3"
                  onClick={handleLeave}
                  disabled={leaving}
                >
                  LEAVE
                </button>
              )}
            </>
          ) : (
            <>
              <div className="row w-100 align-items-center justify-content-center">
                <div className="col-12 col-md-5">
                  <PlayerSlot player={room.owner} label="Owner" meId={meId} />
                </div>
                <div
                  className="col-12 col-md-2 text-center fw-bold my-1 my-md-0"
                  style={{ fontSize: "clamp(1.25rem, 5vw, 2.5rem)" }}
                >
                  VS
                </div>
                <div className="col-12 col-md-5">
                  <PlayerSlot player={room.guest} label="Guest" meId={meId} />
                </div>
              </div>

              {room.status === "waiting" && !isOwner ? (
                <p className="mt-2 mt-md-4 mb-1 text-muted text-center">
                  Waiting For Owner To Start
                </p>
              ) : (
                <p className="mt-2 mt-md-4 mb-1 text-muted text-center">
                  Press FIGHT to engage
                </p>
              )}

              <div
                className="d-flex justify-content-center gap-3 mt-2 mt-md-4 py-2 w-100 sticky-bottom"
                style={{ background: "#eae2c7" }}
              >
                {isOwner && room.status === "waiting" && (
                  <button
                    className="btn btn-success btn-lg"
                    disabled={!canStart}
                    onClick={handlePressFight}
                  >
                    FIGHT
                  </button>
                )}
                <button
                  className="btn btn-outline-danger btn-lg"
                  onClick={handleLeave}
                  disabled={leaving}
                >
                  LEAVE
                </button>
              </div>
            </>
          )}
        </>
      )}
    </div>
  );
}
