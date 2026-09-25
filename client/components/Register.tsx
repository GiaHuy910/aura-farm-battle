import { useState } from "react";

import styles from "../styles/home.module.css";
import { registerUser } from "@/api/auth";

type Props = {
  onLogIn: () => void;
  onLeave: () => void;
  onSuccess: () => void;
};
export default function RegisterPage({ onLogIn, onLeave, onSuccess }: Props) {
  const [fields, setFields] = useState({
    username: "",
    password: "",
  });
  const [errors, setErrors] = useState({
    username: "",
    password: "",
  });

  const handleSetLogIn = () => {
    onLogIn();
  };
  const validateUsernames = (value: string) => {
    if (!value.trim()) {
      return "Username is required";
    }
    return "";
  };
  const validatePasswords = (value: string) => {
    if (!value.trim()) {
      return "Password is required";
    }
    if (value.length < 6) {
      return "Password must be at least 6 characters";
    }
    return "";
  };
  const handleChanges = (e: React.ChangeEvent<HTMLInputElement>) => {
    const { name, value } = e.target;
    setFields((prev) => ({
      ...prev,
      [name]: value,
    }));
  };
  const handleSubmitRegister = async () => {
    const usernameError = validateUsernames(fields.username);
    const passwordError = validatePasswords(fields.password);
    setErrors({
      username: usernameError,
      password: passwordError,
    });
    if (!usernameError && !passwordError) {
      try {
        const RegisterSend = fields;
        //
        await registerUser(RegisterSend.username, RegisterSend.password);
        onSuccess();
      } catch (error) {
        console.error("Error Registering:", error);
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
            <label>REGISTER</label>
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
              onChange={handleChanges}
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
              onChange={handleChanges}
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
              onClick={handleSetLogIn}
            >
              LOG IN
            </button>
          </div>
          <div className="ms-auto">
            <button
              className={`${styles.optionBtn} m-3`}
              onClick={handleSubmitRegister}
            >
              REGISTER
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}
