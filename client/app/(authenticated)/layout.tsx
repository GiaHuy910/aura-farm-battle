import "bootstrap/dist/css/bootstrap.min.css";
import { AuthProvider } from "@/contexts/auth/AuthProvider";

export default async function RootLayout({ children }: LayoutProps<"/">) {
  return (
    <div>
      <AuthProvider>{children}</AuthProvider>
    </div>
  );
}
