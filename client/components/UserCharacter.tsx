import Image from "next/image";

const base_char = "/clothes/base-character.png";
const acc_char = "/clothes/accs/acc_1.png";
const shirt_char = "/clothes/shirts/shirt_1.png";
const shoes_char = "/clothes/shoes/shoes_1.png";

const UserCharacter = () => {
  return (
    <div
      className="position-relative"
      style={{
        width: 256,
        height: 256,
        filter: "drop-shadow(0px 0px 30px red)",
      }}
    >
      <Image
        className="position-absolute"
        width={256}
        height={256}
        src={base_char}
        alt="base_char"
        priority
      />
      <Image
        className="position-absolute "
        width={256}
        height={256}
        src={shoes_char}
        alt="shoes_char"
        priority
      />
      <Image
        className="position-absolute"
        width={256}
        height={256}
        src={shirt_char}
        alt="shirt_char"
        priority
      />
      <Image
        className="position-absolute"
        width={256}
        height={256}
        src={acc_char}
        alt="shoes_char"
        priority
      />
    </div>
  );
};

export default UserCharacter;
