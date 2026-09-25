import { useEffect, useState, Suspense } from "react";

import { getRooms } from "@/api/rooms";

type Room = {
  room_name: string;
  occupancy: number;
  is_private: Boolean;
};

export default function RoomDetail() {
  const [rooms, setRooms] = useState<Room[]>([]);

  const fetchRooms = async () => {
    try {
      const response = await getRooms();
      setRooms(response || []);
    } catch (error) {
      console.error("Error Fetching rooms:", error);
    }
  };
  const handleRefresh = () => {
    fetchRooms();
  };
  useEffect(() => {
    fetchRooms();
  }, []);
  return (
    <div className="w-100 h-100 d-flex flex-column justify-content-start overflow-auto">
      {rooms.length > 0 ? (
        <div className="d-flex flex-column gap-2">
          <Suspense fallback={<div>Loading...........</div>}>
            {rooms.map((room) => (
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
          </Suspense>
        </div>
      ) : (
        <div className="h5 h-100 d-flex flex-column align-items-center justify-content-center">
          No room exists
          <button onClick={handleRefresh}>Refresh?</button>
        </div>
      )}
    </div>
  );
}
