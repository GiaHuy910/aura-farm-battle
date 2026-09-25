import gameLogoSmallMini from "../public/game-logo-mini.png";
import Image from "next/image";

const Navbar = () => {
  return (
    <nav>
      <div className="logo navbar">
        <Image
          className="img-fluid ps-3"
          src={gameLogoSmallMini}
          width={700}
          height={400}
          alt="AURA FARMING BATTLE"
          preload={true}
        />
      </div>
    </nav>
  );
};
export default Navbar;
