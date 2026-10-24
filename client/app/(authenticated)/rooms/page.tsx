"use client";

import { useRouter } from "next/navigation";
import { useState } from "react";

import page from "@/styles/page.module.css";
import home from "@/styles/home.module.css";
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
  return (
    <div
      className={`${page.roomsPage} mx-3 mb-3`}
      style={{
        border: "5px solid rgba(178, 140, 15, 0.69)",
        backgroundColor: "#eae2c7",
      }}
    >
      <div className="row h-100 m-0">
        <div
          className={`col-12 col-md-2 h-25 ${page.hmd100} ${page.panelColumn} text-white`}
          style={{ border: "5px solid rgba(178, 140, 15, 0.69)" }}
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
              RETURN
            </button>
          </div>
        </div>
        <div
          className={`position-relative col-12 col-md-10 h-75 ${page.hmd100} ${page.panelColumn} text-black`}
          style={{ border: "5px solid rgba(178, 140, 15, 0.69)" }}
        >
          <div className="h-100 d-flex justify-content-center align-items-center">
            <div className="w-100">
              {rightView === "detail" ? <RoomDetail /> : <CreateRoomForm />}
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
