import { describe, it, expect } from "vitest";
import { signSession, verifySession } from "@/lib/session";

const SECRET = "test-secret";

describe("session", () => {
  it("verifies a token it just signed", async () => {
    const token = await signSession("admin", SECRET);
    expect(await verifySession(token, SECRET)).toBe("admin");
  });

  it("round-trips a username containing dots and unicode", async () => {
    const token = await signSession("דנה.admin", SECRET);
    expect(await verifySession(token, SECRET)).toBe("דנה.admin");
  });

  it("rejects a tampered token", async () => {
    const token = await signSession("admin", SECRET);
    const tampered = token.replace(/^[^.]+/, "hacker");
    expect(await verifySession(tampered, SECRET)).toBeNull();
  });

  it("rejects a token signed with another secret", async () => {
    const token = await signSession("admin", SECRET);
    expect(await verifySession(token, "other-secret")).toBeNull();
  });

  it("returns null for malformed input", async () => {
    expect(await verifySession("garbage", SECRET)).toBeNull();
  });
});
