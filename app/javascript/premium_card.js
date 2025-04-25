document.addEventListener('DOMContentLoaded', () => {
  const cardContainer = document.querySelector('.card-container');
  if (!cardContainer) return;

  const card = cardContainer.querySelector('.premium-card');
  const shine = cardContainer.querySelector('.card-shine');

  // Track whether the card is being touched (for mobile)
  let isTouch = false;

  // Handle mouse movement
  cardContainer.addEventListener('mousemove', (e) => {
    if (isTouch) return;
    
    const rect = cardContainer.getBoundingClientRect();
    const x = e.clientX - rect.left;
    const y = e.clientY - rect.top;
    
    // Calculate rotation based on mouse position
    const centerX = rect.width / 2;
    const centerY = rect.height / 2;
    const rotateX = (y - centerY) / 15;
    const rotateY = -(x - centerX) / 15;
    
    // Apply smooth rotation
    card.style.transform = `rotateX(${rotateX}deg) rotateY(${rotateY}deg)`;
    
    // Update shine effect
    const shineMoveX = (x / rect.width) * 100;
    const shineMoveY = (y / rect.height) * 100;
    shine.style.background = `radial-gradient(circle at ${shineMoveX}% ${shineMoveY}%, rgba(255,255,255,0.25) 0%, rgba(255,255,255,0) 60%)`;
  });

  // Handle mouse enter
  cardContainer.addEventListener('mouseenter', () => {
    if (isTouch) return;
    card.style.transition = 'none';
  });

  // Handle mouse leave
  cardContainer.addEventListener('mouseleave', () => {
    if (isTouch) return;
    card.style.transition = 'transform 0.8s cubic-bezier(0.71, 0, 0.33, 1.56)';
    card.style.transform = 'rotateX(0) rotateY(0)';
    shine.style.opacity = '0';
  });

  // Handle touch events for mobile
  cardContainer.addEventListener('touchstart', () => {
    isTouch = true;
    card.style.transform = 'rotateY(-15deg) rotateX(5deg)';
  });

  cardContainer.addEventListener('touchend', () => {
    card.style.transform = 'rotateX(0) rotateY(0)';
  });

  // Add subtle floating animation
  const floatingAnimation = () => {
    if (!isTouch && !cardContainer.matches(':hover')) {
      const time = Date.now() / 2000;
      const floatY = Math.sin(time) * 3;
      const floatX = Math.cos(time) * 2;
      card.style.transform = `rotateX(${floatY}deg) rotateY(${floatX}deg)`;
    }
    requestAnimationFrame(floatingAnimation);
  };

  floatingAnimation();
}); 