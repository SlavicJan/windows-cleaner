const cards = document.querySelectorAll('.case-card');

cards.forEach((card) => {
  card.addEventListener('click', () => {
    card.classList.toggle('flipped');
  });

  card.addEventListener('keydown', (event) => {
    if (event.key === 'Enter' || event.key === ' ') {
      event.preventDefault();
      card.classList.toggle('flipped');
    }
  });
});

const year = document.getElementById('year');
if (year) {
  year.textContent = String(new Date().getFullYear());
}

function handleFakeSubmit(event) {
  event.preventDefault();
  const msg = document.getElementById('form-msg');
  if (msg) {
    msg.textContent = 'Спасибо! Сообщение заполнено. Подключите Formspree/Telegram Bot для реальной отправки.';
  }
  event.target.reset();
  return false;
}

window.handleFakeSubmit = handleFakeSubmit;
