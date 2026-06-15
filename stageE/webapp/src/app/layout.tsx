import "./globals.css";
import { Heebo } from "next/font/google";
import { ToastProvider } from "@/components/Toast";

const heebo = Heebo({ subsets: ["hebrew", "latin"], display: "swap" });

export const metadata = { title: "מערכת ניהול בית חולים" };

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="he" dir="rtl" className={heebo.className}>
      <body>
        <ToastProvider>{children}</ToastProvider>
      </body>
    </html>
  );
}
