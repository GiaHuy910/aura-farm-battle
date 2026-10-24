const NEXT_PUBLIC_API_URL = process.env.NEXT_PUBLIC_API_URL;
const NEXT_PUBLIC_WS_URL = process.env.NEXT_PUBLIC_WS_URL;
if (!NEXT_PUBLIC_API_URL) {
  console.log("Missing env variables :" + NEXT_PUBLIC_API_URL);
}
if (!NEXT_PUBLIC_WS_URL) {
  console.log("Missing env variables :" + NEXT_PUBLIC_WS_URL);
}

export const config = {
  server: {
    apiUrl: NEXT_PUBLIC_API_URL || "http://localhost:3001",
    wsUrl: NEXT_PUBLIC_WS_URL || "ws://localhost:3001",
  },
  client: {
    clientUrl:
      process.env.NEXT_PUBLIC_PROD_URL ||
      process.env.NEXT_PUBLIC_DEV_URL ||
      `http://localhost:4000`,
  },
} as const;
