import axios from "axios";
import { useContext, useState } from "react";
import { BiTransfer } from "react-icons/bi";
import { FaDollarSign, FaSearch } from "react-icons/fa";
import {
    FaAngleRight,
    FaArrowRightLong,
    FaCheck,
    FaMoneyBillTransfer,
    FaRegUser,
} from "react-icons/fa6";
import { FiHome } from "react-icons/fi";
import { LuSun } from "react-icons/lu";
import { MdArrowBackIosNew, MdOutlineReceiptLong } from "react-icons/md";
import { LOGO, MENU_DEFAULT, NAME } from "../constant/menu";
import MenuContext from "../context/MenuContext";
import { t } from "../i18n";
import { currencyFormat } from "../utils/common";
import { CFG_WALLET } from "./../constant/menu";
import LoadingComponent from "./LoadingComponent";

const subMenuList = {
  balance: "balance",
  bill: "bill",
  history: "history",
  transfer: "transfer",
};

const BankComponent = ({ isShow }) => {
  const { setMenu, bank, profile, setBank, resolution } =
    useContext(MenuContext);
  const [subMenu, setSubMenu] = useState(subMenuList["balance"]);
  const [errorTransfer, setErrorTransfer] = useState(null);
  const [receiver, setReceiver] = useState({
    isValid: false,
    name: "",
  });

  const handleTransferChange = (e) => {
    const { value } = e.target;
    if (/^\d*$/.test(value)) {
      handleTransferFormChange(e);
    }
  };

  const handleTransferKeyDown = (e) => {
    if (
      e.key !== "Backspace" &&
      e.key !== "Delete" &&
      e.key !== "ArrowLeft" &&
      e.key !== "ArrowRight" &&
      !/^\d$/.test(e.key)
    ) {
      e.preventDefault();
    }
  };

  const [formDataTransfer, setFormDataTransfer] = useState({
    receiver: "",
    total: "",
    note: "",
  });

  const handleTransferFormChange = (e) => {
    const { name, value } = e.target;
    setFormDataTransfer({
      ...formDataTransfer,
      [name]: value,
    });
  };

  const handleTransferFormSubmit = async (e) => {
    e.preventDefault();
    if (!formDataTransfer.receiver) {
      return;
    }
    const targetId = parseInt(formDataTransfer.receiver, 10);
    if (Number.isNaN(targetId) || targetId <= 0) {
      return;
    }
    if (!formDataTransfer.total) {
      return;
    }
    const total = parseInt(formDataTransfer.total, 10);
    if (Number.isNaN(total)) {
      return;
    }
    if (!formDataTransfer.note) {
      return;
    }
    if (bank.balance < total) {
      setErrorTransfer("Your balance is not enough");
      return;
    }

    const payload = {
      serverId: targetId,
      total,
      note: formDataTransfer.note,
    };

    if (total < CFG_WALLET.MIN_TRANSFER) {
      setErrorTransfer(
        "$" + CFG_WALLET.MIN_TRANSFER + " is minimal amount for transfer."
      );
      return;
    }

    await axios
      .post("/transfer", payload)
      .then(function (response) {
        if (response.data) {
          setBank((prev) => ({
            ...prev,
            balance: bank.balance - total,
            histories: [
              {
                type: "withdraw",
                label: "creating...",
                total,
                created_at: "just now",
              },
              ...bank.histories,
            ],
          }));
          setSubMenu(subMenuList["balance"]);
          setReceiver({
            isValid: false,
            name: "",
          });
          setFormDataTransfer({
            receiver: "",
            total: "",
            note: "",
          });
        }

        setErrorTransfer(null);
      })
      .catch(function (error) {
        console.log(error);
      })
      .finally(function () {});
  };

  const handlePayInvoice = async (bill) => {
    await axios
      .post("/pay-invoice", bill)
      .then(function (response) {
        if (response.data) {
          setBank((prev) => ({
            ...prev,
            balance: bank.balance - bill.amount,
            bills: bank.bills.filter((item) => item.id !== bill.id),
            histories: [
              {
                type: "withdraw",
                label: bill.reason,
                total: bill.amount,
                created_at: "just now",
              },
              ...bank.histories,
            ],
          }));
        } else {
          setMenu(MENU_DEFAULT);
        }
      })
      .catch(function (error) {
        console.log(error);
      })
      .finally(function () {});
  };

  const handleCheckReceiver = async () => {
    if (!formDataTransfer.receiver) {
      return;
    }

    const targetId = parseInt(formDataTransfer.receiver, 10);
    if (Number.isNaN(targetId) || targetId <= 0) {
      return;
    }

    await axios
      .post("/transfer-check", {
        serverId: targetId,
      })
      .then(function (response) {
        if (response.data) {
          setReceiver(response.data);
        } else {
          setReceiver({
            isValid: false,
            name: "",
          });
        }
      })
      .catch(function (error) {
        setReceiver({
          isValid: false,
          name: "",
        });
        console.log(error);
      })
      .finally(function () {});
  };
  return (
    <div
      className="relative flex flex-col w-full h-full"
      style={{
        display: isShow ? "block" : "none",
      }}
    >
      <div className="absolute top-0 flex w-full justify-between py-2 bg-black pt-8 z-10">
        <div
          className="flex items-center px-2 text-blue-500 cursor-pointer"
          onClick={() => setMenu(MENU_DEFAULT)}
        >
          <MdArrowBackIosNew className="text-lg" />
          <span className="text-xs">{t("back")}</span>
        </div>
        <span className="absolute left-0 right-0 m-auto text-sm text-white w-fit">
          {t("bank_title")}
        </span>
        <div className="flex items-center px-2 text-blue-500">
          {/* <MdEdit className='text-lg' /> */}
        </div>
      </div>
      {bank == undefined ? (
        <LoadingComponent />
      ) : (
        <div
          className="no-scrollbar flex flex-col w-full h-full text-white overflow-y-auto"
          style={{
            paddingTop: 60,
          }}
        >
          <div
            className="h-full"
            style={{
              ...(subMenu !== subMenuList["balance"]
                ? { display: "none" }
                : {}),
            }}
          >
            <div className="w-full h-full pb-10">
              <div
                className="absolute right-0 w-full flex px-3 justify-between items-center space-x-3 z-10"
                style={{ top: 80 }}
              >
                <div className="flex space-x-1">
                  <span>
                    <LuSun className="text-white mt-1" />
                  </span>
                  <div className="flex flex-col">
                    <span className="text-base font-semibold line-clamp-1">
                      {t("bank_hi", [profile?.name?.split(" ")[0] || ""])}
                    </span>
                    <span className="text-xs text-gray-400">
                      {t("bank_welcome")}
                    </span>
                  </div>
                </div>
                <img src={LOGO} className="w-16 h-16 object-cover" alt="" />
              </div>
              <div
                className="relative z-20 flex flex-col w-full mt-24 bg-gray-900 rounded-t-2xl text-white px-4 py-4"
                style={{
                  height: `${resolution.layoutHeight - 120}px`,
                  marginBottom: 50,
                }}
              >
                <div className="flex flex-col space-y-3">
                  <div className="flex justify-between space-x-2 items-center">
                    <span className="text-xs font-semibold">
                      {t("bank_main_account")}
                    </span>
                    <span className="text-sm font-semibold">
                      {profile.serverId ?? profile.iban}
                    </span>
                  </div>
                  <div className="relative flex flex-col space-y-2 border rounded-lg border-slate-700 text-white px-3 py-3">
                    <div className="flex justify-between">
                      <span className="text-xs text-slate-300">
                        {t("bank_active_balance")}
                      </span>
                      <span
                        className="text-xs text-slate-300 cursor-pointer"
                        onClick={() => setSubMenu(subMenuList["history"])}
                      >
                        {t("bank_in_out")}
                      </span>
                    </div>
                    <div className="flex items-center w-full">
                      <FaDollarSign className="text-xl" />
                      <span className="text-xl truncate">
                        {currencyFormat(bank.balance)}
                      </span>
                    </div>
                    <div className="flex w-full pt-2">
                      <div
                        className="bg-gray-700 hover:bg-gray-800 px-2 py-1 text-xs"
                        style={{
                          borderRadius: 5,
                        }}
                      >
                        <div
                          className="flex items-center cursor-pointer"
                          onClick={() => setSubMenu(subMenuList["transfer"])}
                        >
                          <span>{t("bank_transfer_now")}</span>
                          <FaAngleRight />
                        </div>
                      </div>
                    </div>
                    <div className="absolute bottom-0 right-0">
                      <img
                        src="./images/monas.png"
                        className="w-10 object-cover opacity-70"
                        alt=""
                      />
                    </div>
                  </div>
                  <br />
                  <div className="flex justify-between">
                    <span className="text-xs font-normal border-b pb-1 border-slate-700">
                      {t("bank_last_transactions")}
                    </span>
                    <span
                      className="text-xs font-normal border-slate-700 cursor-pointer"
                      onClick={() => setSubMenu(subMenuList["history"])}
                    >
                      {t("bank_show_all")}
                    </span>
                  </div>
                  <div className="flex flex-col space-y-2">
                    {bank.histories.slice(0, 5).map((v, i) => {
                      return (
                        <div
                          className="flex justify-between items-center space-x-3"
                          key={i}
                        >
                          <div className="w-1/2">
                            <div className="flex space-x-2 justify-start items-center text-sm">
                              <span className="w-3">{i + 1}.</span>
                              <span className="truncate">{v.label}</span>
                            </div>
                          </div>
                          <div className="w-1/2">
                            <div
                              className={`flex justify-end items-center w-full text-sm ${
                                v.type == "withdraw"
                                  ? "text-red-500"
                                  : "text-green-500"
                              }`}
                            >
                              {v.type == "withdraw" ? "- " : ""}
                              <FaDollarSign />
                              <span className="truncate">
                                {currencyFormat(v.total)}
                              </span>
                            </div>
                          </div>
                        </div>
                      );
                    })}
                  </div>
                  <span className="text-xs font-normal border-slate-700 pt-5 text-center">
                    {t("bank_footer", [NAME.toLocaleUpperCase()])}
                  </span>
                </div>
              </div>
            </div>
          </div>
          <div
            className="h-full"
            style={{
              ...(subMenu !== subMenuList["history"]
                ? { display: "none" }
                : {}),
            }}
          >
            <div className="p-3 rounded-lg">
              <div className="flex justify-between items-center mb-4">
                <h3 className="text-lg font-bold leading-none text-white">
                  {t("bank_top_transactions")}
                </h3>
              </div>
              <div className="flow-root pb-10">
                <ul role="list-history" className="divide-y divide-gray-800">
                  {bank.histories.map((v, i) => {
                    return (
                      <li className="py-3" key={i}>
                        <div className="flex items-center space-x-4">
                          <div className="flex-1 line-clamp-1">
                            <p className="text-sm font-medium truncate text-white">
                              {v.type.toUpperCase()}
                            </p>
                            <p className="text-xs truncate text-gray-400">
                              {v.label == "" ? "-" : v.label}
                            </p>
                          </div>
                          <div className="inline-flex items-end text-base font-semibold">
                            {v.type == "withdraw" ? (
                              <div className="flex flex-col -space-y-1 text-right">
                                <span className="text-red-500">
                                  - ${currencyFormat(v.total)}
                                </span>
                                <span className="text-xss text-gray-400">
                                  {v.created_at}
                                </span>
                              </div>
                            ) : (
                              <div className="flex flex-col -space-y-1 text-right">
                                <span className="text-green-500">
                                  + ${currencyFormat(v.total)}
                                </span>
                                <span className="text-xss text-gray-400">
                                  {v.created_at}
                                </span>
                              </div>
                            )}
                          </div>
                        </div>
                      </li>
                    );
                  })}
                </ul>
              </div>
            </div>
          </div>
          <div
            className="h-full"
            style={{
              ...(subMenu !== subMenuList["bill"] ? { display: "none" } : {}),
            }}
          >
            <div className="p-3 rounded-lg">
              <div className="flex flex-col space-y-2 mb-4">
                <h3 className="text-lg font-bold leading-none text-white">
                  {t("bank_bills")}
                </h3>
                <p className="text-xs text-gray-400">
                  {t("bank_bills_note")}
                </p>
              </div>
              <div className="flow-root pb-10">
                <ul role="list-bill" className="divide-y divide-gray-800">
                  {bank.bills.map((v, i) => {
                    return (
                      <li className="py-3" key={i}>
                        <div className="flex w-full items-center space-x-4 justify-between">
                          <div className="flex flex-col text-base font-semibold">
                            <span className="text-sm line-clamp-1">
                              {v.society.toUpperCase()}
                            </span>
                            <span className="text-red-500 line-clamp-1">
                              - ${currencyFormat(v.amount)}
                            </span>
                          </div>
                          <div className="flex flex-col space-y-1 text-right">
                            <button
                              className="flex space-x-1 bg-gray-700 items-center justify-center px-2 cursor-pointer hover:bg-green-700 rounded-lg"
                              onClick={() => handlePayInvoice(v)}
                            >
                              <FaCheck className="text-sm" />
                              <span className="text-sm font-semibold py-0.5">
                                {t("bank_pay")}
                              </span>
                            </button>
                            <span className="text-xss text-gray-400">
                              {v.created_at}
                            </span>
                          </div>
                        </div>
                      </li>
                    );
                  })}
                </ul>
              </div>
            </div>
          </div>
          <div
            className="h-full"
            style={{
              ...(subMenu !== subMenuList["transfer"]
                ? { display: "none" }
                : {}),
            }}
          >
            <form
              className="flex flex-col space-y-1 pt-1"
              onSubmit={handleTransferFormSubmit}
            >
              <div className="text-xs px-3 text-gray-400">
                {t("bank_transfer_intro")}
              </div>
              <div className="pt-2 px-3">
                <div className="flex flex-col space-y-1 border-b border-gray-800 w-full pb-1">
                  <span className="text-sm text-gray-400">{t("bank_from")}</span>
                  <div className="flex space-x-2 items-center justify-between">
                    <div className="flex items-center space-x-2 line-clamp-1">
                      <FaDollarSign className="text-xl" />
                      <div className="flex flex-col">
                        <span className="text-sm">
                          {t("bank_account_label", [NAME])}
                        </span>
                        <span className="text-xs text-gray-400 line-clamp-1">
                          {t("bank_active_balance_label", [
                            currencyFormat(bank.balance),
                          ])}
                        </span>
                      </div>
                    </div>
                    <FaCheck className="text-green-500" />
                  </div>
                </div>
              </div>
              <div className="flex justify-end px-5 pt-2">
                <FaMoneyBillTransfer className="text-xl" />
              </div>
              <div className="px-3">
                <div className="flex flex-col space-y-1 border-b border-gray-800 w-full pb-1">
                  <div className="text-sm text-gray-400 flex space-x-1 items-center">
                    <span>{t("bank_to")}</span>
                    {receiver.isValid ? (
                      <span className="text-green-500 font-semibold">
                        {receiver.name}
                      </span>
                    ) : null}
                  </div>
                  <span className="text-xss text-gray-400">
                    {t("bank_to_hint")}
                  </span>
                  <div className="flex space-x-2 items-center justify-between w-full">
                    <div className="flex items-center space-x-2 w-full">
                      <FaRegUser className="text-xl" />
                      <div className="flex flex-col w-full">
                        <input
                          type="text"
                          name="receiver"
                          className="bg-black text-lg font-medium w-full focus:outline-none"
                          value={formDataTransfer.receiver}
                          onChange={handleTransferFormChange}
                          required
                          autoComplete="off"
                        />
                      </div>
                    </div>
                    <div
                      className="bg-gray-700 hover:bg-gray-800 px-2 py-1 text-xs"
                      style={{
                        borderRadius: 5,
                      }}
                    >
                      <div
                        className="flex items-center cursor-pointer space-x-1"
                        onClick={handleCheckReceiver}
                      >
                        <span>{t("bank_check")}</span>
                        <FaSearch />
                      </div>
                    </div>
                  </div>
                </div>
              </div>
              <div className="px-3">
                <div className="flex flex-col space-y-1 border-b border-gray-800 w-full pb-1">
                  <span className="text-sm text-gray-400">{t("bank_nominal")}</span>
                  <div className="flex space-x-2 items-center justify-between w-full">
                    <div className="flex items-center space-x-2 w-full">
                      <FaDollarSign className="text-xl" />
                      <div className="flex flex-col w-full">
                        <input
                          type="text"
                          name="total"
                          value={formDataTransfer.total}
                          onChange={handleTransferChange}
                          onKeyDown={handleTransferKeyDown}
                          className="bg-black text-lg font-medium w-full focus:outline-none"
                          required
                          autoComplete="off"
                        />
                      </div>
                    </div>
                  </div>
                </div>
              </div>
              <div className="px-3">
                <div className="flex flex-col space-y-1 border-b border-gray-800 w-full pb-1">
                  <span className="text-sm text-gray-400">{t("bank_note")}</span>
                  <div className="flex space-x-2 items-center justify-between w-full">
                    <div className="flex items-center space-x-2 w-full">
                      <div className="flex flex-col w-full">
                        <input
                          type="text"
                          name="note"
                          value={formDataTransfer.note}
                          onChange={handleTransferFormChange}
                          className="bg-black text-sm font-medium focus:outline-none"
                          required
                          autoComplete="off"
                        />
                      </div>
                    </div>
                  </div>
                </div>
              </div>
              <div className="px-3">
                <div className="text-xss text-gray-400">{t("bank_note_warning")}</div>
              </div>
              <div className="px-3">
                {errorTransfer != null ? (
                  <span className="text-red-500 text-xs">{errorTransfer}</span>
                ) : null}
              </div>
              <div className="px-5 pt-2">
                <button
                  type="submit"
                  className="w-full bg-blue-600 hover:bg-blue-700 font-semibold py-2 rounded-lg flex justify-center items-center space-x-2"
                >
                  <span>{t("bank_transfer_button")}</span>
                  <FaArrowRightLong />
                </button>
              </div>
            </form>
          </div>
          <div className="absolute bottom-0 w-full pb-2 pt-2.5 bg-black z-30">
            <div className="grid h-full w-full grid-cols-4 mx-auto font-medium">
              <button
                type="button"
                className={`inline-flex flex-col items-center justify-center px-5 group ${
                  subMenu === subMenuList["balance"]
                    ? "text-white"
                    : "text-gray-600"
                }`}
                onClick={() => setSubMenu(subMenuList["balance"])}
              >
                <FiHome className="text-xl" />
                <span className="text-xs">{t("bank_tab_balance")}</span>
              </button>
              <button
                type="button"
                className={`inline-flex flex-col items-center justify-center px-5 group ${
                  subMenu === subMenuList["transfer"]
                    ? "text-white"
                    : "text-gray-600"
                }`}
                onClick={() => setSubMenu(subMenuList["transfer"])}
              >
                <FaMoneyBillTransfer className="text-xl" />
                <span className="text-xs">{t("bank_tab_transfer")}</span>
              </button>
              <button
                type="button"
                className={`inline-flex flex-col items-center justify-center px-5 group ${
                  subMenu === subMenuList["bill"]
                    ? "text-white"
                    : "text-gray-600"
                }`}
                onClick={() => setSubMenu(subMenuList["bill"])}
              >
                <MdOutlineReceiptLong className="text-xl" />
                <span className="text-xs">{t("bank_tab_bills")}</span>
              </button>
              <button
                type="button"
                className={`inline-flex flex-col items-center justify-center px-5 group ${
                  subMenu === subMenuList["history"]
                    ? "text-white"
                    : "text-gray-600"
                }`}
                onClick={() => setSubMenu(subMenuList["history"])}
              >
                <BiTransfer className="text-xl" />
                <span className="text-xs">{t("bank_tab_history")}</span>
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
export default BankComponent;
