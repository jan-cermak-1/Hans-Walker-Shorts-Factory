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
