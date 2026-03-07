// Nav shadow on scroll
const nav = document.querySelector('nav');
const onScroll = () => nav.classList.toggle('scrolled', window.scrollY > 20);
window.addEventListener('scroll', onScroll, { passive: true });
onScroll(); // init

// Mobile menu toggle
const menuBtn = document.getElementById('navMenuBtn');
const navMenu = document.getElementById('navMenu');
if (menuBtn && navMenu) {
  const toggleMenu = () => {
    const open = nav.classList.toggle('menu-open');
    document.body.classList.toggle('menu-open', open);
    menuBtn.setAttribute('aria-expanded', open);
  };
  menuBtn.addEventListener('click', toggleMenu);
  navMenu.querySelectorAll('a').forEach(a => {
    a.addEventListener('click', () => {
      nav.classList.remove('menu-open');
      document.body.classList.remove('menu-open');
      menuBtn.setAttribute('aria-expanded', 'false');
    });
  });
  navMenu.addEventListener('click', (e) => {
    if (e.target === navMenu) {
      nav.classList.remove('menu-open');
      document.body.classList.remove('menu-open');
      menuBtn.setAttribute('aria-expanded', 'false');
    }
  });
}

// Theme toggle
const themeBtn = document.getElementById('themeBtn');
const root = document.documentElement;
root.dataset.theme = localStorage.getItem('hw-theme') || 'light';
themeBtn.addEventListener('click', () => {
  const next = root.dataset.theme === 'light' ? 'dark' : 'light';
  root.dataset.theme = next;
  localStorage.setItem('hw-theme', next);
});

// Scroll reveal
const observer = new IntersectionObserver(entries => {
  entries.forEach((e, i) => {
    if (e.isIntersecting) {
      e.target.classList.add('up');
      observer.unobserve(e.target);
    }
  });
}, { threshold: 0.07 });

document.querySelectorAll('.reveal').forEach((el, i) => {
  el.style.transitionDelay = (i % 5) * 0.08 + 's';
  observer.observe(el);
});
