import React from "react";

type Props = {
  imageUrl: string;
  buttonName: string;
  onOpen: () => void;
  isDisabled: boolean;
  isEquipped: boolean;
};

const BackgroundButton: React.FC<Props> = ({
  imageUrl,
  buttonName,
  onOpen,
  isDisabled,
  isEquipped,
}) => {
  const buttonStyle: React.CSSProperties = {
    backgroundImage: `url('${imageUrl}')`,
    backgroundSize: "cover",
    backgroundPosition: "center",
    width: buttonName === "ULT" ? "250px" : "150px",
    height: buttonName === "ULT" ? "80px" : "60px",
    border: "4px solid grey",
  };

  const handleClick = () => {
    onOpen();
  };
  return (
    <button
      type="button"
      className={`${buttonName === "ULT" ? "rounded-5" : ""} ${isDisabled} d-flex justify-content-center align-items-center rounded-0 btn overflow-hidden position-relative`}
      style={buttonStyle}
      onClick={handleClick}
      disabled={isDisabled}
    >
      <div
        style={{ maxWidth: "150px" }}
        className="py-1 px-2 rounded-5 border border-light bg-info text-light fw-bold"
      >
        {isEquipped ? "Equipped" : buttonName}
      </div>
    </button>
  );
};

export default BackgroundButton;
