export async function throwApiError(
  response: Response,
  fallback: string,
): Promise<never> {
  const body = (await response.text()).trim();
  let message = body;

  if (body.startsWith("{")) {
    try {
      const payload: unknown = JSON.parse(body);
      if (payload && typeof payload === "object") {
        const fields = payload as Record<string, unknown>;
        const detail = fields.message ?? fields.error ?? fields.status;
        if (typeof detail === "string") {
          message = detail;
        }
      }
    } catch {
      message = body;
    }
  }

  throw new Error(message || fallback);
}
