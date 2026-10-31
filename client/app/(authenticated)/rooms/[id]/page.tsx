"use client";

import { useParams, useRouter } from "next/navigation";
import { useEffect, useRef, useState } from "react";

import page from "@/styles/page.module.css";
import { useAuth } from "@/contexts/auth/useAuth";
import { useRoomSocket } from "@/websocket/useRoomSocket";
import { leaveRoom } from "@/api/rooms";

import PlayerSlot from "@/components/PlayerSlot";
import BattleScreen from "@/components/battle/BattleScreen";

export default function RoomIdPage() {
  const { id } = useParams<{ id: string }>();
  const router = useRouter();
  const { user, fetchMe } = useAuth();

  const { room, game, connection, closedReason, error, send } =
    useRoomSocket(id);
  const [leaving, setLeaving] = useState(false);
  const [confirmingLeave, setConfirmingLeave] = useState(false);
  const [leaveError, setLeaveError] = useState<string | null>(null);
  const cancelLeaveRef = useRef<HTMLButtonElement>(null);

  const refreshedMatch = useRef<string | null>(null);
  const settledMatchId = game?.result?.matchId ?? null;
  useEffect(() => {
    if (settledMatchId && refreshedMatch.current !== settledMatchId) {
      refreshedMatch.current = settledMatchId;
      fetchMe();
    }
  }, [settledMatchId, fetchMe]);

  useEffect(() => {
    if (!confirmingLeave) return;

    const handleKeyDown = (event: KeyboardEvent) => {
      if (event.key === "Escape") setConfirmingLeave(false);
    };
    document.addEventListener("keydown", handleKeyDown);
    cancelLeaveRef.current?.focus();
    return () => document.removeEventListener("keydown", handleKeyDown);
  }, [confirmingLeave]);

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

  const confirmLeaveRoom = async () => {
    setConfirmingLeave(false);
    setLeaveError(null);
    setLeaving(true);
    try {
      const leaveSend: leaveRoomRequest = { room_id: id };
      const data = await leaveRoom(leaveSend);
      if (data.status === "success") handleLobby();
      else setLeaveError("Unable to leave this room. Please try again.");
    } catch {
      setLeaveError("Unable to leave this room. Please try again.");
    } finally {
      setLeaving(false);
    }
  };

  const handleLeave = () => {
    if (leaving) return;
    setLeaveError(null);
    if (game?.phase === "battle") {
      setConfirmingLeave(true);
      return;
    }
    void confirmLeaveRoom();
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
      {leaveError && (
        <div className="alert alert-warning mt-3 mb-0" role="alert">
          {leaveError}
        </div>
      )}
      {confirmingLeave && (
        <div
          className="position-fixed top-0 start-0 w-100 h-100 d-flex align-items-center justify-content-center p-3"
          style={{ zIndex: 1100, background: "rgba(0, 0, 0, 0.72)" }}
          onMouseDown={(event) => {
            if (event.target === event.currentTarget) {
              setConfirmingLeave(false);
            }
          }}
        >
          <div
            className="bg-white rounded shadow-lg p-4 w-100"
            style={{ maxWidth: 460, borderTop: "6px solid #dc3545" }}
            role="alertdialog"
            aria-modal="true"
            aria-labelledby="leave-match-title"
            aria-describedby="leave-match-description"
          >
            <h2 id="leave-match-title" className="h5 mb-2">
              Leave this match?
            </h2>
            <p id="leave-match-description" className="text-muted mb-4">
              You will lose the battle and some of your items!!
            </p>
            <div className="d-flex justify-content-end gap-2">
              <button
                ref={cancelLeaveRef}
                type="button"
                className="btn btn-outline-secondary"
                onClick={() => setConfirmingLeave(false)}
              >
                Stay
              </button>
              <button
                type="button"
                className="btn btn-danger"
                onClick={() => void confirmLeaveRoom()}
                disabled={leaving}
              >
                {leaving ? "Leaving..." : "Leave"}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
