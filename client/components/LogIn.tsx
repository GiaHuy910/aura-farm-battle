import { useState } from "react";

import styles from "../styles/home.module.css";
import { useAuth } from "@/contexts/auth/useAuth";

type Props = {
  onRegister: () => void;
  onLeave: () => void;
  onSuccess: () => void;
};
export default function LogInPage({ onRegister, onLeave, onSuccess }: Props) {
  const { login } = useAuth();
  const [fields, setFields] = useState({
    username: "",
    password: "",
  });
  const [errors, setErrors] = useState({
    username: "",
    password: "",
  });

  const handleSetRegister = () => {
    onRegister();
  };
  const validateUsername = (value: string) => {
    if (!value.trim()) {
      return "Username is required";
    }
    return "";
  };
  const validatePassword = (value: string) => {
    if (!value.trim()) {
      return "Password is required";
    }
    if (value.length < 6) {
      return "Password must be at least 6 characters";
    }
    return "";
  };
  const handleChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const { name, value } = e.target;
    setFields((prev) => ({
      ...prev,
      [name]: value,
    }));
  };
  const handleSubmitLogIn = async () => {
    const usernameError = validateUsername(fields.username);
    const passwordError = validatePassword(fields.password);
    setErrors({
      username: usernameError,
      password: passwordError,
    });
    if (!usernameError && !passwordError) {
      try {
        const LogInSend = fields;
        await login(LogInSend);
        onSuccess();
      } catch (error) {
        console.error("Error Logging in:", error);
      }
    }
  };
  return (
    <div
      className="position-absolute d-flex justify-content-center align-items-center h-100"
      style={{ width: "85%" }}
    >
      <div
        className="w-100"
        style={{
          border: "5px solid brown",
          background: "#f7dacefa",
        }}
      >
        <div className="d-flex flex-column flex-grow-1 gap-3 p-3 ">
          <div className="d-flex justify-content-center h1">
            <label>LOG IN</label>
          </div>
          <div className="d-flex align-items-center">
            <label className="col-3 fw-bold" style={{ width: "150px" }}>
              Username
            </label>
            <input
              type="text"
              name="username"
              value={fields.username}
              className="form-control"
              onChange={handleChange}
            />
          </div>
          <div className="d-flex align-items-center">
            <label className="col-3 fw-bold" style={{ width: "150px" }}>
              Password
            </label>
            <input
              type="password"
              className="form-control"
              name="password"
              value={fields.password}
              onChange={handleChange}
            />
          </div>
        </div>

        <div>
          <div>
            {errors.username && (
              <div className="invalid-feedback d-block ms-3">
                {errors.username}
              </div>
            )}
            {errors.password && (
              <div className="invalid-feedback d-block ms-3">
                {errors.password}
              </div>
            )}
          </div>
        </div>

        <div className="mt-5 d-flex justify-content-center">
          <div className="me-auto">
            <button
              className={`${styles.optionBtn} m-3`}
              onClick={() => onLeave()}
              style={{
                color: "white",
                background: "red",
              }}
            >
              LEAVE
            </button>
            <button
              className={`${styles.optionBtn} m-3`}
              onClick={handleSetRegister}
            >
              REGISTER
            </button>
          </div>
          <div className="ms-auto">
            <button
              className={`${styles.optionBtn} m-3`}
              onClick={handleSubmitLogIn}
            >
              LOG IN
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}
