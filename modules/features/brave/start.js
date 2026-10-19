const date = document.getElementById('date');
date.textContent = new Intl.DateTimeFormat(undefined, { weekday: 'short', day: 'numeric', month: 'long' }).format(new Date());
date.dateTime = new Date().toISOString().slice(0, 10);
const catThought = document.getElementById('cat-thought');
const thoughts = [
  'Meow. Coordinates look purrfect.',
  'What if the moon is a yarn ball?',
  'All systems nominal. All boxes mine.',
  'A little curiosity. A little chaos.',
  'Mrrp? Oh, just a passing comet.',
  'The stars are just laser pointers.',
  'Next stop: a sunbeam. Meow.',
  'I packed snacks for the void.'
];
let lastThought = -1;
let thoughtTimer;
function scheduleThought() {
  thoughtTimer = setTimeout(() => {
    // The nonzero modular offset prevents consecutive repeats.
    const next = (lastThought + 1 + Math.floor(Math.random() * (thoughts.length - 1))) % thoughts.length;
    lastThought = next;
    catThought.textContent = thoughts[next];
    catThought.classList.add('is-visible');
    catThought.setAttribute('aria-hidden', 'false');
    thoughtTimer = setTimeout(() => {
      catThought.classList.remove('is-visible');
      catThought.setAttribute('aria-hidden', 'true');
      scheduleThought();
    }, 6000);
  }, 15000 + Math.random() * 15000);
}
// Pause messages in background tabs.
document.addEventListener('visibilitychange', () => {
  clearTimeout(thoughtTimer);
  catThought.classList.remove('is-visible');
  catThought.setAttribute('aria-hidden', 'true');
  if (!document.hidden) scheduleThought();
});
if (!document.hidden) scheduleThought();
document.addEventListener('keydown', (event) => {
  if (event.key === '/' && !event.ctrlKey && !event.altKey && !event.metaKey && !['INPUT', 'TEXTAREA'].includes(document.activeElement.tagName) && !document.activeElement.isContentEditable) {
    event.preventDefault();
    document.getElementById('query').focus();
  }
});
