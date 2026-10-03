import Link from "next/link";
import Image from "next/image";

import chatBobble from "../public/chat-bobble.png";
import mommyImage from "../public/mommy.png";
import page from "../styles/page.module.css";

const NotFound = () => {
  return (
    <div
      className={`${page.roomsPage} d-flex justify-content-center align-items-center not-found text-dark h-100 w-100`}
    >
      <div className="row w-100 justify-content-center m-0">
        <div className="col-12 col-md-6 col-lg-5 position-relative d-flex flex-column justify-content-center p-0">
          <Image
            className="w-100 h-auto"
            src={chatBobble}
            alt="404 NOT FOUND"
            preload
          />
          <Image
            className="w-100 h-auto"
            src={mommyImage}
            alt="mommy"
            preload
          />
          <div
            style={{ top: "85%" }}
            className="position-absolute start-50 translate-middle text-center"
          >
            <Link
              href="/"
              className="p-2 h5 bg-light text-primary text-decoration-none"
              style={{ border: "3px dashed pink" }}
            >
              HomePage
            </Link>
          </div>
        </div>
      </div>
    </div>
  );
};
export default NotFound;
