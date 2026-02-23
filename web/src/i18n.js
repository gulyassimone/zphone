import locale from "./locale.json";
import config from "/public/static/config.json";

const DEFAULT_LANG = "en";
let currentLang = config.lang || import.meta.env.VITE_ZPHONE_LANG || DEFAULT_LANG;

const getByPath = (obj, path) => {
  return path.split(".").reduce((acc, k) => {
    if (acc && acc[k] !== undefined && acc[k] !== null) return acc[k];
    return undefined;
  }, obj);
};

export const setLocale = (lang) => {
  if (lang && locale[lang]) {
    currentLang = lang;
  }
};

export const getLocale = () => currentLang;

export const t = (key, params) => {
  const langPack = locale[currentLang] || locale[DEFAULT_LANG] || {};
  let value = getByPath(langPack, key);

  if (value === undefined || value === null) {
    const fallbackPack = locale[DEFAULT_LANG] || {};
    value = getByPath(fallbackPack, key);
  }

  if (value === undefined || value === null) {
    return key;
  }

  if (Array.isArray(params) && params.length) {
    let out = value;
    params.forEach((p) => {
      out = out.replace("%s", p);
    });
    return out;
  }

  return value;
};

// init
setLocale(currentLang);
