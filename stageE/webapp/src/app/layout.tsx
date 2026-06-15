import "./globals.css";
import { Frank_Ruhl_Libre, Assistant } from "next/font/google";
import { ToastProvider } from "@/components/Toast";

const display = Frank_Ruhl_Libre({
  subsets: ["hebrew", "latin"],
  weight: ["500", "700", "900"],
  variable: "--font-display",
  display: "swap",
});
const body = Assistant({
  subsets: ["hebrew", "latin"],
  weight: ["400", "500", "600", "700"],
  variable: "--font-body",
  display: "swap",
});

export const metadata = { title: "מערכת ניהול בית חולים" };

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="he" dir="rtl" className={`${display.variable} ${body.variable}`}>
      <body>
        <ToastProvider>{children}</ToastProvider>
      </body>
    </html>
  );
}
