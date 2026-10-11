import type { Metadata } from "next";
import { cookies } from "next/headers";

import { ToastContainer } from "react-toastify";

import "bootstrap/dist/css/bootstrap.min.css";
import BootstrapClient from "@/components/BootstrapClient";
import BackgroundMusicProvider from "@/contexts/music/BackgroundMusicProvider";
import "./global.css";
import { getCurrentUser } from "@/api/auth";
import { AuthProvider } from "@/contexts/auth/AuthProvider";

export const metadata: Metadata = {
  title: "aurafarmbattle",
  description: "Click to start your experience",
};

const getMe = async () => {
  const cookieStore = await cookies();
  const sessionId = cookieStore.get("session_id")?.value;
  if (!sessionId) return null;
  try {
    const data = await getCurrentUser();
    return data;
  } catch {
    return null;
  }
};

export default async function RootLayout({ children }: LayoutProps<"/">) {
  const user = await getMe();
  return (
    <html lang="en">
      <head>
        <style>
          @import
          url('https://fonts.googleapis.com/css2?family=Press+Start+2P&display=swap');
        </style>
      </head>
      <body className={`backgroundContainer`}>
        <BackgroundMusicProvider>
          <AuthProvider initialUser={user}>
            {children}
            <BootstrapClient />
            <ToastContainer />
          </AuthProvider>
        </BackgroundMusicProvider>
      </body>
    </html>
  );
}
