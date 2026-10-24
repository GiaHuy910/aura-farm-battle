const NEXT_PUBLIC_API_URL = process.env.NEXT_PUBLIC_API_URL;
const NEXT_PUBLIC_WS_URL = process.env.NEXT_PUBLIC_WS_URL;
if (!NEXT_PUBLIC_API_URL) {
  throw new Error("Missing environment variable: NEXT_PUBLIC_API_URL");
}
if (!NEXT_PUBLIC_WS_URL) {
  throw new Error("Missing environment variable: NEXT_PUBLIC_WS_URL");
}

export const config = {
  server: {
    apiUrl: NEXT_PUBLIC_API_URL,
    wsUrl: NEXT_PUBLIC_WS_URL,
  },
  client: {
    clientUrl:
      process.env.NEXT_PUBLIC_PROD_URL ||
      process.env.NEXT_PUBLIC_DEV_URL ||
      `http://localhost:4000`,
  },
} as const;
