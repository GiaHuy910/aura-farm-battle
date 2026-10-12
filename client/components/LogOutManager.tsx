"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";

import home from "@/styles/home.module.css";
import { useAuth } from "@/contexts/auth/useAuth";

export default function LogOutManager() {
  const router = useRouter();
  const { user, logout } = useAuth();
  const [isShowBoard, setIsShowBoard] = useState(false);

  const toggleLogoutBoard = async () => {
    setIsShowBoard((prev) => !prev);
  };
  const handleConfirmLogout = async () => {
    setIsShowBoard(false);
    logout();
    router.push("/");
  };
  return (
    <div>
      {isShowBoard && (
        <div
          className="modal fade show d-flex align-items-center justify-content-center animate-fade-in"
          style={{
            zIndex: 15,
          }}
        >
          <div className="modal-dialog modal-dialog-centered text-dark">
            <div
              className="modal-content shadow-lg border-0"
              style={{ borderRadius: "12px" }}
            >
              <div className="modal-header border-0 pb-0">
                <h5 className="modal-title w-100 text-center fw-bold">
                  Confirm Logout
                </h5>
              </div>
              <div className="modal-body text-center text-muted py-3">
                Are you sure you want to log out on{" "}
                <span className="h5 fw-bold text-info">{user?.username}</span>{" "}
                account?
              </div>
              <div className="modal-footer border-0 d-flex justify-content-center gap-3 pb-4">
                <button
                  type="button"
                  className="btn btn-secondary px-4"
                  style={{ borderRadius: "8px" }}
                  onClick={toggleLogoutBoard}
                >
                  Cancel
                </button>
                <button
                  type="button"
                  className="btn px-4 text-light"
                  style={{ borderRadius: "8px", background: "red" }}
                  onClick={handleConfirmLogout}
                >
                  Yes
                </button>
              </div>
            </div>
          </div>
        </div>
      )}
      {user && (
        <button
          className={`${home.optionBtn}`}
          onClick={toggleLogoutBoard}
          style={{
            padding: "5px 7x",
            background: "red",
            color: "#fff",
          }}
        >
          Log Out
        </button>
      )}
    </div>
  );
}
