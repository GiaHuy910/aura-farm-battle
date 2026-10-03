import Image from "next/image";

const base_char = "/clothes/base-character.png";

const UserCharacter = () => {
  return (
    <div style={{ filter: "drop-shadow(20px 20px 3px yellow)" }}>
      <Image width={256} height={256} src={base_char} alt="base_char" preload />
    </div>
  );
};

export default UserCharacter;
