"use client";

import { useParams, useRouter } from "next/navigation";
import { useState } from "react";

import page from "@/styles/page.module.css";
import { useAuth } from "@/contexts/auth/useAuth";
import { useRoomSocket } from "@/websocket/useRoomSocket";
import { useRooms } from "@/api/rooms";

import PlayerSlot from "@/components/PlayerSlot";
import { leaveRoom } from "@/api/rooms";

export default function RoomIdPage() {
  const { id } = useParams<{ id: string }>();
  const router = useRouter();
  const { user } = useAuth();
  const { mutate } = useRooms();

  const { room, connection, closedReason, send } = useRoomSocket(id);
  const [leaving, setLeaving] = useState(false);

  const isOwner = !!user && room?.owner.id === user.user_id;
  const canStart =
    isOwner && room?.status === "waiting" && !!room.guest?.online;

  const handlePressFight = () => {
    send("room.start");
  };
  const handleLeave = async () => {
    setLeaving(true);
    const leaveSend: leaveRoomRequest = { room_id: id };
    const data = await leaveRoom(leaveSend);
    if (data.status === "success") handleLobby();
  };
  const handleLobby = () => {
    mutate();
    router.push("/rooms");
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

          <div className="row w-100 align-items-center justify-content-center">
            <div className="col-12 col-md-5">
              <PlayerSlot
                player={room.owner}
                label="Owner"
                meId={user?.user_id}
              />
            </div>
            <div className="col-12 col-md-2 text-center fs-1 fw-bold my-3">
              VS
            </div>
            <div className="col-12 col-md-5">
              <PlayerSlot
                player={room.guest}
                label="Guest"
                meId={user?.user_id}
              />
            </div>
          </div>

          {room.status === "waiting" && !isOwner ? (
            <p className="mt-4 text-muted">Waiting For Owner To Start</p>
          ) : (
            <p className="mt-4 text-muted">Press FIGHT to engage</p>
          )}
          {room.status === "playing" && (
            <div className="alert alert-success mt-4">
              Fight started !!! the fight awaited
            </div>
          )}
          {room.status === "finished" && (
            <div className="alert alert-info mt-4">
              {room.winnerId === user?.user_id ? (
                <p>
                  YOU <span className="fs-5 text-success">WON</span> !!
                </p>
              ) : (
                <p>
                  YOU <span className="fs-5 text-danger">WON</span> !!
                </p>
              )}
            </div>
          )}

          <div className="d-flex gap-3 mt-4">
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
    </div>
  );
}
