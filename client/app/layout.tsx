import type { Metadata } from "next";

import { Slide, ToastContainer } from "react-toastify";

import "bootstrap/dist/css/bootstrap.min.css";
import BootstrapClient from "@/components/BootstrapClient";
import BackgroundMusicProvider from "@/contexts/music/BackgroundMusicProvider";
import "./global.css";
import { AuthProvider } from "@/contexts/auth/AuthProvider";

export const metadata: Metadata = {
  title: "aurafarmbattle",
  description: "Maybe it's time to farm.. the AURAS",
};

export default async function RootLayout({ children }: LayoutProps<"/">) {
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
          <AuthProvider>
            {children}
            <BootstrapClient />
            <ToastContainer
              position="bottom-right"
              autoClose={3000}
              hideProgressBar={false}
              newestOnTop={false}
              closeOnClick
              rtl={false}
              pauseOnFocusLoss={false}
              draggable
              pauseOnHover
              theme="light"
              transition={Slide}
            />
          </AuthProvider>
        </BackgroundMusicProvider>
      </body>
    </html>
  );
}
