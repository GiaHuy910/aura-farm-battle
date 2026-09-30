"use client";
import { useState, Suspense, use, useEffect } from "react";

import { useRooms } from "@/api/rooms";

export default function RoomDetail() {
  const [rooms, setRooms] = useState<Room[] | [] | undefined>([]);
  const { data, mutate } = useRooms();

  useEffect(() => {
    setRooms(data);
  }, [data]);
  const fetchRooms = async () => {
    await mutate();
  };
  return (
    <div className="w-100 h-100 d-flex flex-column justify-content-start overflow-auto">
      {rooms?.length ? (
        <div className="d-flex flex-column gap-2">
          {rooms?.map((room) => (
            <div
              key={room.room_name}
              className="d-flex align-items-center justify-content-between rounded p-1"
              style={{ border: "5px solid white" }}
            >
              <div className="ps-2">{room.room_name}</div>
              <div className="ps-2">
                {room.is_private ? <div>Private</div> : <div>Public</div>}
              </div>
              <button
                className="btn btn-secondary rounded-0 d-flex"
                disabled={!(room.occupancy === 1)}
              >
                <div>{room.occupancy}/2 </div>
                <div className="ms-2">Join</div>
              </button>
            </div>
          ))}
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
