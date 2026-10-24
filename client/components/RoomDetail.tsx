"use client";
import { useState, useEffect } from "react";
import { useRouter } from "next/navigation";

import { useRooms, joinRoom } from "@/api/rooms";

export default function RoomDetail() {
  const [rooms, setRooms] = useState<Room[] | [] | undefined>([]);
  const { data, mutate } = useRooms();
  const router = useRouter();

  const [selectedRoom, setSelectedRoom] = useState<Room | null>(null);
  const [password, setPassword] = useState<string>("");
  const handleChangePassword = (e: React.ChangeEvent<HTMLInputElement>) => {
    const value = e.target.value;
    setPassword(value);
  };

  useEffect(() => {
    setRooms(data);
  }, [data]);

  const fetchRooms = async () => {
    await mutate();
  };
  const handleJoinRoom = async (roomId: string, pass: string) => {
    const joinRoomSend: joinRoomRequest = { room_id: roomId, password: pass };
    const data = await joinRoom(joinRoomSend);
    if (data.status === "success") {
      router.push(`/rooms/${data.room_id}`);
    }
    handleRefreshSelectedRoom();
  };
  const handleCheckRoom = (room: Room) => {
    if (!room.is_private) {
      handleJoinRoom(room.room_id, password);
    } else {
      setSelectedRoom(room);
    }
  };
  const handleRefreshSelectedRoom = () => {
    setSelectedRoom(null);
    setPassword("");
  };
  return (
    <div className="w-100 h-100 d-flex flex-column justify-content-start overflow-auto">
      {rooms?.length ? (
        <div className="d-flex flex-column gap-2 overflow-hidden">
          {selectedRoom && (
            <div
              className="position-absolute vw-100 vh-100"
              style={{ zIndex: 3 }}
            ></div>
          )}
          {selectedRoom && (
            <div
              className="position-absolute mt-5 d-flex justify-content-center align-items-center w-100"
              style={{ zIndex: 4 }}
            >
              <div className="bg-white p-3 border border-3 border-dark">
                <p className="small mb-4">Room : {selectedRoom.room_name}</p>
                <input
                  type="password"
                  placeholder="1x3428@arH"
                  value={password}
                  onChange={handleChangePassword}
                  className="border-4 p-2 rounded mb-4 w-100"
                />
                <div className="d-flex justify-content-between align-items-center">
                  <button
                    onClick={handleRefreshSelectedRoom}
                    className="text-secondary text-decoration-none border-1 px-2 py-2"
                  >
                    Cancel
                  </button>
                  <button
                    onClick={() =>
                      handleJoinRoom(selectedRoom.room_id, password)
                    }
                    className="rounded-1 border-5 border-dark btn btn-success px-4 py-2 text-white"
                  >
                    Enter
                  </button>
                </div>
              </div>
            </div>
          )}
          {rooms?.map((room) => {
            return (
              <div
                key={room.room_id}
                className="d-flex align-items-center justify-content-between rounded p-1"
                style={{ border: "5px solid white" }}
              >
                <div
                  className="ps-2 overflow-hidden text-truncate"
                  style={{ maxWidth: "500px" }}
                >
                  {room.room_name}
                </div>
                <div className="d-flex justify-content-center align-items-center">
                  {room.is_private ? (
                    <span className="text-danger">&#128274;&#xFE0E;</span>
                  ) : (
                    <span className="text-info">&#128275;&#xFE0E;</span>
                  )}
                  <button
                    className="btn btn-secondary rounded-0 d-flex ms-3"
                    disabled={!(room.occupation === "1/2")}
                    value={room.room_id}
                    onClick={() => handleCheckRoom(room)}
                  >
                    <div>{room.occupation}</div>
                    <div className="ms-2">Join</div>
                  </button>
                </div>
              </div>
            );
          })}
          <div className="justify-content-start">
            <button onClick={fetchRooms}>Refresh?</button>
          </div>
        </div>
      ) : (
        <div className="h5 h-100 d-flex flex-column align-items-center justify-content-center">
          No room exists
          <button onClick={fetchRooms}>Refresh?</button>
        </div>
      )}
    </div>
  );
}
