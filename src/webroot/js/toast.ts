import '@material/web/icon/icon.js';

type ToastType = 'success' | 'error';

export function showToast(message: string, type?: ToastType, icon?: string): void {
  const toast = document.createElement('div');
  toast.className = 'md-toast' + (type ? ` md-toast--${type}` : '');
  toast.setAttribute('role', type === 'error' ? 'alert' : 'status');

  if (icon) {
    const iconEl = document.createElement('md-icon');
    iconEl.className = 'md-toast__icon';
    iconEl.textContent = icon;
    toast.append(iconEl);
  }
  const text = document.createElement('span');
  text.className = 'md-toast__message';
  text.textContent = message;
  toast.append(text);

  document.body.append(toast);
  requestAnimationFrame(() => toast.classList.add('md-toast--open'));
  setTimeout(() => {
    toast.classList.remove('md-toast--open');
    setTimeout(() => toast.remove(), 400);
  }, 3000);
}
