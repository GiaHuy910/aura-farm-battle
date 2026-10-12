import { useState } from "react";

import home from "@/styles/home.module.css";
import LogOutManager from "./LogOutManager";
import MusicControls from "./MusicControls";
import { useAuth } from "@/contexts/auth/useAuth";

export default function Setting() {
  const [showSetting, setShowSetting] = useState(false);
  const { user, loading } = useAuth();

  const handleToggleSetting = () => {
    setShowSetting((prev) => !prev);
  };
  return (
    <div className="position-absolute ">
      {showSetting ? (
        <div>
          <div
            style={{
              zIndex: 3,
            }}
          ></div>
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
                    Settings
                  </h5>
                </div>
                <div className="modal-body text-center text-muted py-3 d-flex flex-column gap-2">
                  <MusicControls />
                  <div className="p-2 border border-dark rounded-0 d-flex justify-content-start align-items-center">
                    <div>
                      Account :{" "}
                      {loading ? (
                        "Loading..."
                      ) : (
                        <span className="text-info">{user?.username}</span>
                      )}
                    </div>{" "}
                  </div>
                </div>
                <div className="modal-footer border-0 d-flex justify-content-center gap-3 pb-4">
                  <LogOutManager />{" "}
                  <button
                    className={`${home.optionBtn}`}
                    style={{ padding: "8px 12px" }}
                    onClick={handleToggleSetting}
                  >
                    RETURN
                  </button>
                </div>
              </div>
            </div>
          </div>
        </div>
      ) : (
        <button
          onClick={handleToggleSetting}
          style={{
            position: "fixed",
            bottom: "10px",
            right: "10px",
            zIndex: 4,
            padding: "10px 15px",
            background: "#000",
            color: "#fff",
            borderRadius: "8px",
            cursor: "pointer",
          }}
        >
          Setting
        </button>
      )}
    </div>
  );
}
