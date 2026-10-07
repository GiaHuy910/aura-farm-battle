import Image from "next/image";

type Props = {
  base_user_url: string;
  acc_user_url: string;
  shirt_user_url: string;
  shoes_user_url: string;
};
const UserCharacter = ({
  base_user_url,
  acc_user_url,
  shirt_user_url,
  shoes_user_url,
}: Props) => {
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
        src={base_user_url}
        alt="base_char"
        priority
      />
      <Image
        className="position-absolute "
        width={256}
        height={256}
        src={shoes_user_url}
        alt="shoes_char"
        priority
      />
      <Image
        className="position-absolute"
        width={256}
        height={256}
        src={shirt_user_url}
        alt="shirt_char"
        priority
      />
      <Image
        className="position-absolute"
        width={256}
        height={256}
        src={acc_user_url}
        alt="shoes_char"
        priority
      />
    </div>
  );
};

export default UserCharacter;
