type createRoomForm = {
  room_name: string;
  password: string;
  owner_id: string;
  is_private: boolean;
};
type Room = {
  room_name: string;
  occupancy: number;
  is_private: Boolean;
};
