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
  const layers = [
    { src: base_user_url, alt: "base_char" },
    { src: shoes_user_url, alt: "shoes_char" },
    { src: shirt_user_url, alt: "shirt_char" },
    { src: acc_user_url, alt: "acc_char" },
  ];
  return (
    <div
      className="position-relative"
      style={{
        width: 256,
        height: 256,
        filter: "drop-shadow(0px 0px 30px red)",
      }}
    >
      {layers.map(({ src, alt }) => (
        <Image
          key={alt}
          className="position-absolute top-0 start-0"
          width={256}
          height={256}
          src={src}
          alt={alt}
          priority
        />
      ))}
    </div>
  );
};

export default UserCharacter;
