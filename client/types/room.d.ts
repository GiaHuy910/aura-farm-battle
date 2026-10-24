type createRoomForm = {
  room_name: string;
  password: string;
  owner_id: string;
  is_private: boolean;
};
type createRoomResponse = {
  status: string;
  room: {
    room_id: string;
    room_name: string;
    owner_id: string;
    status: string;
  };
};
type Room = {
  room_id: string;
  room_name: string;
  occupation: string;
  is_private: Boolean;
  status: string;
};
type joinRoomRequest = {
  room_id: string;
  password: string;
};
type joinRoomResponse = {
  status: string;
  room_id: string;
};
type leaveRoomRequest = {
  room_id: string;
};
type leaveRoomResponse = {
  status: string;
};
