import { describe, it, expect } from "vitest";
import { signSession, verifySession } from "@/lib/session";

const SECRET = "test-secret";

describe("session", () => {
  it("verifies a token it just signed", () => {
    const token = signSession("admin", SECRET);
    expect(verifySession(token, SECRET)).toBe("admin");
  });

  it("rejects a tampered token", () => {
    const token = signSession("admin", SECRET);
    const tampered = token.replace(/^[^.]+/, "hacker");
    expect(verifySession(tampered, SECRET)).toBeNull();
  });

  it("rejects a token signed with another secret", () => {
    const token = signSession("admin", SECRET);
    expect(verifySession(token, "other-secret")).toBeNull();
  });

  it("returns null for malformed input", () => {
    expect(verifySession("garbage", SECRET)).toBeNull();
  });
});
