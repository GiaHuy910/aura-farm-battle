const baseApi = `http://localhost:3001/auth`;

export const getCurrentUser = async () => {
  const response = await fetch(`${baseApi}/me`, {
    credentials: "include",
  });
  const data: AuthMeResponse = await response.json();
  if (!response.ok) {
    throw new Error(data.auth.message || "Unauthorized");
  }
  return data.me;
};
export const logOutUser = async () => {
  const response = await fetch(`${baseApi}/logout`, {
    method: "POST",
    credentials: "include",
  });
  const data = await response.json();
  if (!response.ok) {
    throw new Error(data.message || "Logout failed");
  }
  return data;
};
export const logInUser = async (loginData: logInForm) => {
  const response = await fetch(`${baseApi}/login`, {
    method: "POST",
    credentials: "include",
    headers: {
      "Content-Type": "application/json",
    },
    body: JSON.stringify(loginData),
  });
  const data = await response.json();
  if (!response.ok) {
    throw new Error(data.message || "Login Failed");
  }
  return data;
};
export const registerUser = async (username: string, password: string) => {
  const response = await fetch(`${baseApi}/register`, {
    method: "POST",
    credentials: "include",
    headers: {
      "Content-Type": "application/json",
    },
    body: JSON.stringify({ username, password }),
  });
  const data = await response.json();
  if (!response.ok) {
    throw new Error(data.message || "Unauthorized");
  }
  return data;
};
