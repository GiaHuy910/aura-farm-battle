"use client";

import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";

import { getRooms, joinRoom } from "@/api/rooms";

const pageSize = 5;

export default function RoomDetail() {
  const [pages, setPages] = useState<RoomsResponse[]>([]);
  const [pageIndex, setPageIndex] = useState(0);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [selectedRoom, setSelectedRoom] = useState<Room | null>(null);
  const [password, setPassword] = useState("");
  const [joining, setJoining] = useState(false);
  const [joinError, setJoinError] = useState<string | null>(null);
  const router = useRouter();

  useEffect(() => {
    let active = true;
    getRooms({ limit: pageSize, cursor: "" })
      .then((response) => {
        if (active) setPages([response]);
      })
      .catch(() => {
        if (active) setError("Unable to load rooms. Please try again.");
      })
      .finally(() => {
        if (active) setLoading(false);
      });
    return () => {
      active = false;
    };
  }, []);

  const currentPage = pages[pageIndex];
  const currentRooms = currentPage?.rooms ?? [];
  const hasNextPage =
    pageIndex < pages.length - 1 || !!currentPage?.pagination.nextCursor;

  const closeRoomDialog = () => {
    setSelectedRoom(null);
    setPassword("");
    setJoinError(null);
  };

  const refreshPage = async () => {
    const cursor =
      pageIndex === 0
        ? ""
        : (pages[pageIndex - 1]?.pagination.nextCursor ?? "");
    setLoading(true);
    setError(null);
    try {
      const response = await getRooms({ limit: pageSize, cursor });
      setPages((previous) =>
        previous.length === 0
          ? [response]
          : previous.map((page, index) =>
              index === pageIndex ? response : page,
            ),
      );
    } catch {
      setError("Unable to refresh rooms. Please try again.");
    } finally {
      setLoading(false);
    }
  };

  const handleNextPage = async () => {
    if (pageIndex < pages.length - 1) {
      setPageIndex((index) => index + 1);
      return;
    }

    const cursor = currentPage?.pagination.nextCursor;
    if (!cursor) return;

    setLoading(true);
    setError(null);
    try {
      const response = await getRooms({ limit: pageSize, cursor });
      setPages((previous) => [...previous, response]);
      setPageIndex((index) => index + 1);
    } catch {
      setError("Unable to load the next page. Please try again.");
    } finally {
      setLoading(false);
    }
  };

  const handleJoinRoom = async (room: Room) => {
    setJoining(true);
    setJoinError(null);
    try {
      const response = await joinRoom({
        room_id: room.room_id,
        password,
      });
      if (response.status === "success") {
        router.push(`/rooms/${response.room_id}`);
        return;
      }
      setJoinError(
        "This room is no longer available or the password is incorrect.",
      );
    } catch {
      setJoinError("Unable to join this room. Please try again.");
    } finally {
      setJoining(false);
    }
  };

  const openRoom = (room: Room) => {
    if (room.is_private) {
      setSelectedRoom(room);
      setJoinError(null);
      return;
    }
    void handleJoinRoom(room);
  };

  return (
    <section
      className="w-100 h-100 d-flex flex-column"
      aria-labelledby="room-browser-title"
      style={{ minHeight: 0 }}
    >
      <header className="d-flex justify-content-between align-items-center flex-wrap gap-2 mb-3">
        <p className="small text-muted mb-0">
          Find an open room and join the battle.
        </p>
        <button
          type="button"
          className="btn btn-outline-dark"
          onClick={() => void refreshPage()}
          disabled={loading}
        >
          {loading ? "Loading..." : "Refresh"}
        </button>
      </header>

      {error && (
        <div className="alert alert-warning py-2" role="alert">
          {error}
        </div>
      )}

      <div className="flex-grow-1 overflow-auto pe-1" style={{ minHeight: 0 }}>
        {loading && pages.length === 0 ? (
          <div className="h-100 d-flex flex-column align-items-center justify-content-center">
            <div
              className="spinner-border"
              role="status"
              aria-label="Loading rooms"
            />
            <span className="small mt-3">Loading rooms...</span>
          </div>
        ) : error && pages.length === 0 ? (
          <div className="h-100 d-flex flex-column align-items-center justify-content-center text-center">
            <p className="text-muted">Rooms could not be loaded.</p>
            <button
              type="button"
              className="btn btn-outline-dark"
              onClick={() => void refreshPage()}
              disabled={loading}
            >
              Try again
            </button>
          </div>
        ) : currentRooms.length > 0 ? (
          <div className="d-flex flex-column gap-2">
            {currentRooms.map((room) => {
              const canJoin =
                room.status === "waiting" && room.occupation === "1/2";
              return (
                <article
                  key={room.room_id}
                  className="d-flex align-items-center justify-content-between gap-3 ps-3 pe-1 py-1 rounded bg-white shadow-sm"
                  style={{ border: "3px solid rgba(178, 140, 15, 0.8)" }}
                >
                  <div className="overflow-hidden">
                    <h3 className="h6 text-truncate mb-2">{room.room_name}</h3>
                    <div className="d-flex flex-wrap gap-2">
                      <span className="badge fs-6">
                        {room.is_private ? (
                          <span className="text-danger">&#128274;&#xFE0E;</span>
                        ) : (
                          <span className="text-info">&#128275;&#xFE0E;</span>
                        )}
                      </span>
                      <span className="d-flex justify-content-center align-items-center badge text-bg-info border text-dark">
                        {room.status === "waiting" ? "Waiting" : room.status}
                      </span>
                    </div>
                  </div>
                  <div className="d-flex align-items-center gap-2 flex-shrink-0">
                    <span className="small text-nowrap">{room.occupation}</span>
                    <button
                      type="button"
                      className="btn btn-success"
                      disabled={!canJoin || joining}
                      onClick={() => openRoom(room)}
                    >
                      Join
                    </button>
                  </div>
                </article>
              );
            })}
          </div>
        ) : (
          <div className="h-100 d-flex flex-column align-items-center justify-content-center text-center">
            <h3 className="h6">No rooms found</h3>
            <p className="small text-muted mb-0">
              Try refreshing the room list in a moment.
            </p>
          </div>
        )}
      </div>

      <footer className="d-flex align-items-center justify-content-center gap-3 py-3">
        <button
          type="button"
          className="btn btn-outline-secondary"
          onClick={() => setPageIndex((index) => Math.max(0, index - 1))}
          disabled={pageIndex === 0 || loading}
        >
          Previous
        </button>
        <span className="small" aria-live="polite">
          Page {pageIndex + 1}
        </span>
        <button
          type="button"
          className="btn btn-outline-secondary"
          onClick={() => void handleNextPage()}
          disabled={!hasNextPage || loading}
        >
          Next
        </button>
      </footer>

      {selectedRoom && (
        <div
          className="position-fixed top-0 start-0 w-100 h-100 d-flex align-items-center justify-content-center p-3"
          style={{ zIndex: 1100, background: "rgba(0, 0, 0, 0.65)" }}
          onMouseDown={(event) => {
            if (event.target === event.currentTarget) closeRoomDialog();
          }}
        >
          <form
            className="bg-white rounded shadow-lg p-4 w-100"
            style={{ maxWidth: 420 }}
            role="dialog"
            aria-modal="true"
            aria-labelledby="room-password-title"
            onSubmit={(event) => {
              event.preventDefault();
              void handleJoinRoom(selectedRoom);
            }}
          >
            <h3 id="room-password-title" className="h5 mb-2">
              Join private room
            </h3>
            <p className="text-muted mb-3">{selectedRoom.room_name}</p>
            <label htmlFor="room-password" className="form-label">
              Room password
            </label>
            <input
              id="room-password"
              type="password"
              className="form-control"
              autoFocus
              value={password}
              onChange={(event) => setPassword(event.target.value)}
              disabled={joining}
            />
            {joinError && (
              <p className="small text-danger mt-2 mb-0" role="alert">
                {joinError}
              </p>
            )}
            <div className="d-flex justify-content-end gap-2 mt-4">
              <button
                type="button"
                className="btn btn-outline-secondary"
                onClick={closeRoomDialog}
                disabled={joining}
              >
                Cancel
              </button>
              <button
                type="submit"
                className="btn btn-success"
                disabled={joining}
              >
                {joining ? "Joining..." : "Join room"}
              </button>
            </div>
          </form>
        </div>
      )}
    </section>
  );
}
