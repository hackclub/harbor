// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"

document.addEventListener("DOMContentLoaded", function() {
  const container = document.querySelector('.currently-hacking-container');
  const header = container?.querySelector('.currently-hacking-header');
  if (container && header) {
    header.addEventListener('click', function() {
      container.classList.toggle('visible');
    });
  }
});
