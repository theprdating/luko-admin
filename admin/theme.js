// Luko Admin Theme — 從 CSS var 讀色，避免 JS 散落 hex
//
// 用法：
//   import { theme } from './theme.js';
//   ctx.fillStyle = theme.forestGreen;
//
// 或非模組 script：
//   window.LukoTheme.forestGreen
//
// 修改色票：改 admin/tokens.css，此檔自動同步。

(function (root) {
  function readVar(name) {
    return getComputedStyle(document.documentElement).getPropertyValue(name).trim();
  }

  const theme = {
    get forestGreen()     { return readVar('--forest-green'); },
    get forestDeep()      { return readVar('--forest-deep'); },
    get brandGold()       { return readVar('--brand-gold'); },
    get brandBg()         { return readVar('--brand-bg'); },
    get bgBase()          { return readVar('--bg-base'); },
    get bgCard()          { return readVar('--bg-card'); },
    get bgElevated()      { return readVar('--bg-elevated'); },
    get border()          { return readVar('--border'); },
    get textPrimary()     { return readVar('--text-primary'); },
    get textSecondary()   { return readVar('--text-secondary'); },
    get success()         { return readVar('--success'); },
    get successSoft()     { return readVar('--success-soft'); },
    get warning()         { return readVar('--warning'); },
    get error()           { return readVar('--error'); },
    get errorSoft()       { return readVar('--error-soft'); },
    get info()            { return readVar('--info'); },
  };

  root.LukoTheme = theme;
})(window);
