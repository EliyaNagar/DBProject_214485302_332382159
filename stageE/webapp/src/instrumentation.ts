// Next.js calls register() once when the server process boots.
// We pre-warm the DB pool so the first user request (e.g. login) is hot.
export async function register() {
  if (process.env.NEXT_RUNTIME === "nodejs") {
    const { warmPool } = await import("@/lib/db");
    await warmPool();
  }
}
