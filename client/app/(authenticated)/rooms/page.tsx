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
  const [searchOpen, setSearchOpen] = useState(false);

  const handleCreateRoom = () => {
    setSearchOpen(false);
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
    <div className={`${page.roomsPage} mx-3 mb-3`}>
      <div className={page.roomsLayout}>
        <aside className={page.roomsSidebar}>
          <div className={page.sidebarActions}>
            <button
              type="button"
              className={home.optionBtn}
              onClick={() => setSearchOpen((open) => !open)}
              aria-expanded={searchOpen}
              style={{
                visibility: rightView === "detail" ? "visible" : "hidden",
              }}
            >
              {searchOpen ? "CLOSE FIND" : "FIND"}
            </button>

            <button
              className={home.optionBtn}
              onClick={handleCreateRoom}
              style={{
                visibility: rightView === "detail" ? "visible" : "hidden",
              }}
            >
              CREATE
            </button>

            <button
              className={home.optionBtn}
              style={{ color: "white", background: "red" }}
              onClick={handleDetail}
            >
              RETURN
            </button>
          </div>
        </aside>

        <main className={page.roomsContent}>
          <div className={page.roomsContentInner}>
            {rightView === "detail" ? (
              <RoomDetail searchOpen={searchOpen} />
            ) : (
              <CreateRoomForm />
            )}
          </div>
        </main>
      </div>
    </div>
  );
}
