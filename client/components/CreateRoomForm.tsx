import { useState } from "react";

import { createRoom } from "@/api/rooms";
import styles from "../styles/home.module.css";
import { useAuth } from "@/contexts/auth/useAuth";

type Props = {
  onSuccess: () => void;
};

export default function CreateRoomForm({ onSuccess }: Props) {
  const { user } = useAuth();
  const [errors, setErrors] = useState({
    roomName: "",
    password: "",
  });
  const [fields, setFields] = useState({
    roomName: "",
    password: "",
    isPrivate: false,
  });

  const validateRoomName = (value: string) => {
    if (!value.trim()) {
      return "Room name is required";
    }
    return "";
  };
  const validatePassword = (value: string) => {
    if (!value.trim()) {
      return "Password is required";
    }
    if (value.length < 6) {
      return "Password must be at least 6 characters";
    }
    return "";
  };
  const handleChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const { name, value } = e.target;
    setFields((prev) => ({
      ...prev,
      [name]: value,
    }));
  };
  const handleCheck = () => {
    setFields((prev) => ({
      ...prev,
      password: "",
      isPrivate: !prev.isPrivate,
    }));
  };
  const handleCreate = async () => {
    const roomNameError = validateRoomName(fields.roomName);
    const passwordError = fields.isPrivate
      ? validatePassword(fields.password)
      : "";
    setErrors({
      roomName: roomNameError,
      password: passwordError,
    });
    if (!roomNameError && !passwordError) {
      try {
        if (user) {
          const owner_id = user.user_id;
          const createRoomSend = {
            room_name: fields.roomName,
            owner_id,
            password: fields.password,
            is_private: fields.isPrivate,
          };
          const response = await createRoom(createRoomSend);
          onSuccess();
        }
      } catch (error) {
        console.error("Error Fetching rooms:", error);
      }
    }
  };
  return (
    <div className="d-flex justify-content-center align-items-center h-100">
      <div
        className="w-100"
        style={{
          border: "5px solid brown",
          background: "#f7dacefa",
        }}
      >
        <div className="d-flex flex-column flex-grow-1 gap-3 p-3 ">
          <div className="d-flex align-items-center">
            <label className="col-3 fw-bold" style={{ width: "150px" }}>
              Room Name
            </label>
            <input
              type="text"
              name="roomName"
              value={fields.roomName}
              className="form-control"
              onChange={handleChange}
            />
          </div>
          <div className="d-flex align-items-center">
            <div className="col-3" style={{ width: "150px" }}>
              <label className="me-auto fw-bold">Private</label>
            </div>
            <div>
              <input
                className="form-check-input "
                type="checkbox"
                name="isPrivate"
                checked={fields.isPrivate}
                onChange={handleCheck}
              />
            </div>
          </div>
          <div>
            <div
              className="d-flex align-items-center"
              style={{
                opacity: fields.isPrivate ? 1 : 0,
                visibility: fields.isPrivate ? "visible" : "hidden",
                transition: "all 0.1s ease-in-out",
              }}
            >
              <label className="col-3 fw-bold" style={{ width: "150px" }}>
                Password
              </label>
              <input
                type="password"
                className="form-control"
                name="password"
                value={fields.password}
                onChange={handleChange}
              />
            </div>
          </div>
        </div>

        <div className="mt-5 d-flex justify-content-end">
          <div>
            {errors.roomName && (
              <div className="invalid-feedback d-block ms-3">
                {errors.roomName}
              </div>
            )}
            {errors.password && (
              <div className="invalid-feedback d-block ms-3 ">
                {errors.password}
              </div>
            )}
          </div>
          <button className={`${styles.optionBtn} m-3`} onClick={handleCreate}>
            Create
          </button>
        </div>
      </div>
    </div>
  );
}
