import { useContext, useEffect, useState } from "react";
import { FaAngleUp } from "react-icons/fa6";
import Markdown from "react-markdown";
import { CFG_LATEST_NEWS, MENU_DEFAULT } from "../constant/menu";
import MenuContext from "../context/MenuContext";
import { t } from "../i18n";

const buildDayName = (idx) => {
  const keys = [
    "day_sunday",
    "day_monday",
    "day_tuesday",
    "day_wednesday",
    "day_thursday",
    "day_friday",
    "day_saturday",
  ];
  return t(keys[idx] || "") || "";
};

const buildMonthName = (idx) => {
  const keys = [
    "month_january",
    "month_february",
    "month_march",
    "month_april",
    "month_may",
    "month_june",
    "month_july",
    "month_august",
    "month_september",
    "month_october",
    "month_november",
    "month_december",
  ];
  return t(keys[idx] || "") || "";
};

const LockScreenComponent = ({ isShow }) => {
  const { time, resolution, profile, setMenu, news } = useContext(MenuContext);
  const [isOpen, setIsOpen] = useState(false);

  const dateNow = new Date();
  const dateNumber = dateNow.getDate();
  const day = buildDayName(dateNow.getDay());
  const month = buildMonthName(dateNow.getMonth());

  useEffect(() => {
    setIsOpen(false);
  }, [isShow]);

  useEffect(() => {
    if (isOpen) {
      setTimeout(() => {
        setMenu(MENU_DEFAULT);
      }, 1000);
    }
  }, [isOpen]);

  const hasNews = Array.isArray(news) && news.length > 0;
  const latest = hasNews ? { first: news[0], second: news[1] } : null;

  const lockImage = latest?.first?.image && latest.first.image !== "" ? latest.first.image : CFG_LATEST_NEWS.IMG_URL;
  const lockCompany = latest?.first?.company || latest?.first?.source || CFG_LATEST_NEWS.AUTHOR;
  const lockTitle = latest?.first?.title || t("lock_latest_news");
  const lockContent = latest?.first?.excerpt || latest?.first?.body || CFG_LATEST_NEWS.content;
  const lockMore = latest?.second?.title || CFG_LATEST_NEWS.more_updates;
  return (
    <div
      className="relative flex flex-col justify-between w-full h-full"
      style={{
        backgroundImage: `url(${profile.wallpaper})`,
        backgroundSize: "cover",
        display: isShow ? "block" : "none",
      }}
    >
      <div className={`relative ${isOpen ? "animate-slideUp" : ""}`}>
        <div
          className="flex flex-col pt-10 items-center"
          // style={{
          //   transform: `scale(${resolution.scale})`,
          // }}
        >
          <svg
            xmlns="http://www.w3.org/2000/svg"
            className="h-8 w-8 text-white"
            viewBox="0 0 20 20"
            fill="currentColor"
          >
            <path d="M10 2a5 5 0 00-5 5v2a2 2 0 00-2 2v5a2 2 0 002 2h10a2 2 0 002-2v-5a2 2 0 00-2-2H7V7a3 3 0 015.905-.75 1 1 0 001.937-.5A5.002 5.002 0 0010 2z" />
          </svg>
          <p
            className={`text-white font-extralight`}
            style={{
              fontSize: resolution.frameHeight
                ? resolution.frameHeight / 14
                : 0,
            }}
          >
            {time}
          </p>
          <p
            className="text-white font-light"
            style={{
              fontSize: resolution.frameHeight
                ? resolution.frameHeight / 33
                : 0,
            }}
          >
            {day}, {month} {dateNumber}
          </p>
        </div>
        <div className="relative mt-4 mx-2.5">
          <div
            className="px-3 py-4 rounded-3xl shadow"
            style={{
              backgroundColor: "rgb(255 255 255 / 0.5)",
            }}
          >
                <div className="flex justify-between items-start">
                  <div>
                    <p className="text-xs font-bold">{lockCompany}</p>
                    <h2 className="text-lg font-bold">{t("lock_latest_news")}</h2>
                  </div>
                </div>
                <div className="mt-2 flex flex-col">
                  <div className="flex space-x-3">
                    {lockImage ? (
                      <img
                        className="rounded-lg h-24 w-24 object-cover"
                        src={lockImage}
                        alt=""
                        onError={(error) => {
                          error.target.src = "./images/noimage.jpg";
                        }}
                      />
                    ) : null}

                    <div>
                      <h3 className="mt-2 text-sm font-bold leading-tight">
                        {lockTitle}
                      </h3>
                      <Markdown className="mt-1 text-xs line-clamp-3">
                        {lockContent}
                      </Markdown>
                    </div>
                  </div>
                </div>
                <hr className="mt-4 border-black/20" />
                <div className="col-span-2 pt-2">
                  <h3 className="text-xs font-bold">{t("lock_more_updates")}</h3>
                  <p className="mt-0.5 text-xs line-clamp-2">
                    {lockMore}
                  </p>
                </div>
          </div>
        </div>
        <div
          className="flex justify-center pt-5 cursor-pointer my-5"
          onClick={() => setIsOpen(true)}
        >
          <FaAngleUp className="text-4xl text-white animate-bounce" />
        </div>
      </div>
    </div>
  );
};
export default LockScreenComponent;
