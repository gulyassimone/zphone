import { useContext, useEffect } from "react";
import useSound from "use-sound";
import MenuContext from "../../context/MenuContext";
import { t } from "../../i18n";

const NewMessageNotificationComponent = ({ isShow }) => {
  const { notificationMessage, setNotificationMessage } =
    useContext(MenuContext);
  const [play] = useSound("/sounds/sms.ogg");

  const isService = notificationMessage?.is_service;
  const iconSrc = isService ? "./images/services.svg" : ".//images/message.svg";
  const borderClass = isService ? "border-yellow-500" : "border-gray-900";
  const pillText = isService ? t("menu_services") : t("new_message_title");
  const pillTextClass = isService ? "text-yellow-100" : "text-gray-300";
  const bgStyle = isService
    ? { background: "rgba(234, 179, 8, 0.9)" }
    : { background: "rgba(0, 0, 0, 0.9)" };
  const senderText = isService
    ? t("service_inbox_title")
    : notificationMessage.from;
  const senderClass = isService ? "text-yellow-100" : "text-white";

  useEffect(() => {
    if (isShow) {
      play();
      setTimeout(() => {
        setNotificationMessage({ type: "" });
      }, 4000);
    }
  }, [isShow]);

  return (
    <div
      className={`flex w-full cursor-pointer px-2 pt-8 animate-slideDownThenUp`}
      style={{
        display: isShow ? "block" : "none",
      }}
    >
      <div
        className={`flex px-3 py-2 space-x-2 w-full items-center rounded-xl border ${borderClass}`}
        style={bgStyle}
      >
        <div className="flex w-full items-center space-x-2 w-full">
          <img src={iconSrc} className="w-8 h-8" alt="" />
          <div className="flex flex-col">
            <span className={`text-sm font-semibold ${senderClass} line-clamp-1`}>
              {senderText}
            </span>
            <span className={`text-xs ${pillTextClass} line-clamp-1`}>
              {pillText}
            </span>
          </div>
        </div>
      </div>
    </div>
  );
};
export default NewMessageNotificationComponent;
