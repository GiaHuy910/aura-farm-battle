"use client";

import { useRouter } from "next/navigation";
import { useState } from "react";

import styles from "../../styles/page.module.css";
import home from "../../styles/home.module.css";
import RoomDetail from "@/components/RoomDetail";
import CreateRoomForm from "@/components/CreateRoomForm";

export default function RoomsPage() {
  const router = useRouter();
  const [rightView, setRightView] = useState<"detail" | "create">("detail");

  const handleCreateRoom = () => {
    setRightView("create");
  };
  const handleDetail = () => {
    if (rightView === "detail") {
      router.push("/");
    } else {
      setRightView("detail");
    }
  };
  const handleCreateRoomSuccess = () => {
    router.push("/rooms");
  };
  return (
    <div
      className={`${styles.roomsPage} mx-3 mb-3`}
      style={{ border: "5px solid brown", background: "#f7dacefa" }}
    >
      <div className="row h-100 m-0">
        <div
          className={`col-12 col-md-2 h-25 ${styles.hmd100} ${styles.panelColumn} text-white`}
          style={{ border: "5px solid brown" }}
        >
          <div className="d-flex flex-column justify-content-end h-100">
            <button
              className={`${home.optionBtn} `}
              style={{
                opacity: rightView === "detail" ? 1 : 0,
                visibility: rightView === "detail" ? "visible" : "hidden",
                transition: "all 0.1s ease-in-out",
              }}
            >
              FIND
            </button>
            <button
              className={`${home.optionBtn}`}
              onClick={handleCreateRoom}
              style={{
                opacity: rightView === "detail" ? 1 : 0,
                visibility: rightView === "detail" ? "visible" : "hidden",
                transition: "all 0.1s ease-in-out",
              }}
            >
              CREATE
            </button>
            <button
              className={`${home.optionBtn}`}
              style={{
                color: "white",
                background: "red",
              }}
              onClick={handleDetail}
            >
              LEAVE
            </button>
          </div>
        </div>
        <div
          className={`col-12 col-md-10 h-75 ${styles.hmd100} ${styles.panelColumn} text-black`}
          style={{ border: "5px solid brown" }}
        >
          <div className="h-100 d-flex justify-content-center">
            <div className="p-6 w-100 ">
              {rightView === "detail" ? (
                <RoomDetail />
              ) : (
                <CreateRoomForm onSuccess={handleCreateRoomSuccess} />
              )}
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
