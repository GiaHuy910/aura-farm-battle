import React from "react";
import Navbar from "@/components/Navbar";
import styles from "../../styles/page.module.css";

export default function RoomsLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <section>
      <div className={`${styles.roomsShell} d-flex flex-column`}>
        {children}
      </div>
    </section>
  );
}
