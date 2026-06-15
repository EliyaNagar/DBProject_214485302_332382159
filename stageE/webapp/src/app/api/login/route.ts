import { NextResponse } from "next/server";
import { canConnect } from "@/lib/db";
import { SESSION_COOKIE, signSession } from "@/lib/session";

export async function POST(req: Request) {
  const { username, password } = await req.json();

  if (!username || !password) {
    return NextResponse.json({ ok: false, message: "אנא הזן שם משתמש וסיסמה." }, { status: 400 });
  }
  if (username !== process.env.APP_USERNAME || password !== process.env.APP_PASSWORD) {
    return NextResponse.json({ ok: false, message: "שם משתמש או סיסמה שגויים. נסה שוב." }, { status: 401 });
  }
  if (!(await canConnect())) {
    return NextResponse.json({ ok: false, message: "שגיאת רשת: לא ניתן להתחבר למסד הנתונים." }, { status: 503 });
  }

  const token = signSession(username, process.env.SESSION_SECRET ?? "");
  const res = NextResponse.json({ ok: true, message: `ברוך הבא למערכת, ${username}!` });
  res.cookies.set(SESSION_COOKIE, token, { httpOnly: true, sameSite: "lax", path: "/" });
  return res;
}
