// Hans Walker Shorts Factory Website JavaScript

// Smooth scroll for anchor links
document.querySelectorAll('a[href^="#"]').forEach(anchor => {
    anchor.addEventListener('click', function (e) {
        e.preventDefault();
        const target = document.querySelector(this.getAttribute('href'));
        if (target) {
            target.scrollIntoView({
                behavior: 'smooth',
                block: 'start'
            });
        }
    });
});

// Download button tracking (optional)
document.querySelectorAll('.btn-primary').forEach(button => {
    button.addEventListener('click', function() {
        // You can add analytics tracking here
        console.log('Download initiated');
    });
});

// Add parallax effect to hero
window.addEventListener('scroll', () => {
    const scrolled = window.pageYOffset;
    const hero = document.querySelector('.hero');
    if (hero && scrolled < hero.offsetHeight) {
        hero.style.transform = `translateY(${scrolled * 0.5}px)`;
        hero.style.opacity = 1 - (scrolled / hero.offsetHeight) * 0.5;
    }
});

// Feature cards animation on scroll
const observerOptions = {
    threshold: 0.1,
    rootMargin: '0px 0px -100px 0px'
};

const observer = new IntersectionObserver((entries) => {
    entries.forEach(entry => {
        if (entry.isIntersecting) {
            entry.target.style.animation = 'fadeInUp 0.6s ease forwards';
            observer.unobserve(entry.target);
        }
    });
}, observerOptions);

// Observe all feature cards
document.querySelectorAll('.feature-card, .step').forEach(card => {
    card.style.opacity = '0';
    observer.observe(card);
});

// Add fade in animation
const style = document.createElement('style');
style.textContent = `
    @keyframes fadeInUp {
        from {
            opacity: 0;
            transform: translateY(30px);
        }
        to {
            opacity: 1;
            transform: translateY(0);
        }
    }
`;
document.head.appendChild(style);

// Check for latest release version from GitHub
async function checkLatestVersion() {
    try {
        const response = await fetch('https://api.github.com/repos/jan-cermak-1/video-shorts-factory/releases/latest');
        const data = await response.json();
        
        if (data.tag_name) {
            const versionElements = document.querySelectorAll('.version');
            versionElements.forEach(el => {
                el.textContent = el.textContent.replace('v1.1.0', data.tag_name);
            });
        }
    } catch (error) {
        console.log('Could not fetch latest version:', error);
    }
}

// Check version on page load
checkLatestVersion();

// Add button hover sound effect (optional, disabled by default)
const enableSoundEffects = false;
if (enableSoundEffects) {
    document.querySelectorAll('.btn').forEach(button => {
        button.addEventListener('mouseenter', () => {
            // You can add a subtle hover sound here
        });
    });
}

// Log page view (optional analytics placeholder)
console.log('Hans Walker Shorts Factory website loaded');
