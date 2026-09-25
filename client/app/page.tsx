"use client";

import { useState } from "react";
import Link from "next/link";
import Image from "next/image";
import { useRouter } from "next/navigation";

import styles from "../styles/home.module.css";
import gameLogo from "../public/game-logo-small.png";
import LogInPage from "@/components/LogIn";
import RegisterPage from "@/components/Register";
import { useAuth } from "@/contexts/auth/useAuth";

export default function Home() {
  const router = useRouter();
  const [isStart, setIsStart] = useState(false);
  const [showRegister, setShowRegister] = useState(false);
  const [showLogIn, setShowLogIn] = useState(false);
  const { user, loading, fetchMe } = useAuth();

  const handleStart = () => {
    setIsStart((prev) => !prev);
  };
  const handleLeave = () => {
    setShowRegister(false);
    setShowLogIn(false);
  };
  const handleShowLogIn = () => {
    setShowLogIn(true);
    setShowRegister(false);
  };
  const handleShowRegister = () => {
    setShowLogIn(false);
    setShowRegister(true);
  };
  const handleRefresh = () => {
    if (!loading && !user) {
      fetchMe();
      router.refresh();
      setShowLogIn(false);
      setShowRegister(false);
    }
  };

  if (loading) {
    return <div className="text-center mt-5">Checking user...</div>;
  }
  return (
    <div
      className={`d-flex justify-content-center align-items-center vh-100 vw-100 flex-column`}
    >
      <div
        className={`${styles.logoWrapper}`}
        style={{
          transform: isStart
            ? "var(--logo-scale) var(--logo-translate)"
            : "scale(1)",
          transition: "all 0.5s ease-in-out",
          marginBottom: isStart ? "var(--logo-margin)" : "0px",
        }}
      >
        <Image
          className="img-fluid"
          src={gameLogo}
          alt="AURA FARMING BATTLE"
          preload={true}
        />
      </div>
      <div>
        <div
          className="w-100 d-flex justify-content-center"
          style={{
            maxHeight: !isStart ? "60px" : "0px",
            opacity: !isStart ? 1 : 0,
            visibility: !isStart ? "visible" : "hidden",
            transition: "all 0.6s ease-in-out",
          }}
        >
          {user ? (
            <button
              className={`${styles.btnFill} w-md-auto`}
              onClick={handleStart}
            >
              PLAY NOW
            </button>
          ) : (
            <button
              className={`${styles.playBtn} w-md-auto`}
              onClick={handleShowLogIn}
            >
              LOG IN
            </button>
          )}
        </div>

        <div
          className="w-100 d-flex flex-column justify-content-center align-items-center"
          style={{
            maxWidth: "300px",
            maxHeight: isStart ? "350px" : "10px",
            opacity: isStart ? 1 : 0,
            visibility: isStart ? "visible" : "hidden",
            transition: "all 0.6s ease-in-out",
            overflow: "hidden",
          }}
        >
          <div className={`w-100 pb-2`}>
            <Link href="/rooms" style={{ textDecoration: "none" }}>
              <div
                className={`${styles.optionBtn} py-3 px-4 text-center rounded fw-bold game-option`}
              >
                1 VS 1
              </div>
            </Link>
          </div>
          <div className={`w-100 pb-2 `}>
            <Link href="/gacha" style={{ textDecoration: "none" }}>
              <div
                className={`${styles.optionBtn} py-3 px-4 text-center rounded fw-bold game-option`}
              >
                GACHA
              </div>
            </Link>
          </div>
          <div className={`w-100 pb-2`}>
            <Link href="/custom" style={{ textDecoration: "none" }}>
              <div
                className={`${styles.optionBtn} py-3 px-4 text-center rounded fw-bold game-option`}
              >
                CUSTOMIZE
              </div>
            </Link>
          </div>
          <div className={`w-100 pb-2`}>
            <div
              onClick={handleStart}
              className={`${styles.optionBtn} py-3 px-4 text-center rounded fw-bold game-option`}
              style={{
                color: "white",
                background: "red",
              }}
            >
              LEAVE
            </div>
          </div>
        </div>
      </div>
      {showLogIn && (
        <LogInPage
          onRegister={handleShowRegister}
          onLeave={handleLeave}
          onSuccess={handleRefresh}
        />
      )}
      {showRegister && (
        <RegisterPage
          onLogIn={handleShowLogIn}
          onLeave={handleLeave}
          onSuccess={handleRefresh}
        />
      )}
    </div>
  );
}
