import '@material/web/icon/icon.js';
import { styles as typescaleStyles } from '@material/web/typography/md-typescale-styles.js';
import outlinedIcons from 'material-icons/iconfont/material-icons-outlined.woff2?url';
import filledIcons from 'material-icons/iconfont/material-icons.woff2?url';

if (typescaleStyles.styleSheet) document.adoptedStyleSheets.push(typescaleStyles.styleSheet);

// Only the woff2 files; the package CSS would also bundle the unused woff fallbacks.
for (const [family, url] of [
  ['Material Icons Outlined', outlinedIcons],
  ['Material Icons', filledIcons],
] as const) {
  const face = new FontFace(family, `url(${url}) format('woff2')`, { display: 'block' });
  document.fonts.add(face);
  face.load().catch(() => {});
}
