type logInForm = {
  username: string;
  password: string;
};

type AuthMeResponse = {
  auth: {
    message: string;
    status: string;
  };
  me: UserInfo;
};
