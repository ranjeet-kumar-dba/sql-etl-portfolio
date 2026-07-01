// Progressive enhancement
document.documentElement.classList.add('js');

const themeToggle = document.querySelector('.theme-toggle');
const themeToggleIcon = themeToggle?.querySelector('.theme-toggle-icon');
const savedTheme = window.localStorage.getItem('theme');
if (savedTheme === 'dark') {
  document.documentElement.classList.add('dark');
}

function updateThemeButton() {
  const isDark = document.documentElement.classList.contains('dark');
  if (!themeToggle) return;
  themeToggle.setAttribute('aria-label', isDark ? 'Switch to light mode' : 'Switch to dark mode');
  if (themeToggleIcon) themeToggleIcon.textContent = isDark ? '☀️' : '🌙';
}

if (themeToggle) {
  themeToggle.addEventListener('click', () => {
    const isDark = document.documentElement.classList.toggle('dark');
    window.localStorage.setItem('theme', isDark ? 'dark' : 'light');
    updateThemeButton();
  });
}

updateThemeButton();

const prefersReduced = window.matchMedia('(prefers-reduced-motion: reduce)').matches;

if (!prefersReduced) {
  const io = new IntersectionObserver((entries) => {
    entries.forEach(e => { if (e.isIntersecting) { e.target.classList.add('in'); io.unobserve(e.target); } });
  }, { threshold: 0.08, rootMargin: '0px 0px -40px 0px' });
  document.querySelectorAll('.reveal').forEach(el => io.observe(el));

  // Safety net: ensure no element ever stays invisible permanently
  window.addEventListener('load', () => {
    setTimeout(() => {
      document.querySelectorAll('.reveal:not(.in)').forEach(el => el.classList.add('in'));
    }, 1500);
  });
} else {
  document.querySelectorAll('.reveal').forEach(el => el.classList.add('in'));
}

/* --- HERO CONSOLE TYPING EFFECT --- */
(function () {
  const target = document.getElementById('consoleQuery');
  const statusEl = document.getElementById('consoleStatus');
  if (!target || !statusEl) return;

  const queries = [
    {
      text:
`SELECT name, title, years_experience
FROM   ranjeet_kumar
WHERE  specialty IN ('SQL Server','Azure SQL','ETL')
  AND  records_managed > 80000000;`,
      status: '8 rows · 12 ms · Execution plan: optimal'
    },
    {
      text:
`EXEC sp_helpindex 'dbo.PensionRecords';
-- Rebuilding fragmented indexes...
ALTER INDEX ALL ON dbo.PensionRecords
REBUILD WITH (ONLINE = ON);`,
      status: 'Query latency reduced 30–40%'
    },
    {
      text:
`BACKUP DATABASE [MCGM_BirthDeath]
TO DISK = 'D:\\Backups\\nightly.bak'
WITH CHECKSUM, COMPRESSION;`,
      status: 'Backup verified · Integrity check passed'
    }
  ];

  if (prefersReduced) {
    target.textContent = queries[0].text;
    statusEl.textContent = queries[0].status;
    return;
  }

  // Keyword highlighting helper
  const KEYWORDS = ['SELECT','FROM','WHERE','AND','IN','EXEC','ALTER','INDEX','ALL','ON','REBUILD','WITH','ONLINE','BACKUP','DATABASE','TO','DISK','CHECKSUM','COMPRESSION'];

  function renderHighlighted(text) {
    const escaped = text
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;');
    const pattern = new RegExp('\\b(' + KEYWORDS.join('|') + ')\\b', 'g');
    return escaped.replace(pattern, '<span class="kw">$1</span>');
  }

  let queryIndex = 0;
  let charIndex = 0;
  let typing = true;

  function tick() {
    const current = queries[queryIndex];
    const fullText = current.text;

    if (typing) {
      charIndex++;
      const shown = fullText.slice(0, charIndex);
      target.innerHTML = renderHighlighted(shown) + '<span class="cursor"></span>';
      statusEl.textContent = 'Executing…';

      if (charIndex >= fullText.length) {
        typing = false;
        statusEl.textContent = current.status;
        setTimeout(tick, 2600);
        return;
      }
      setTimeout(tick, 26);
    } else {
      // erase
      charIndex--;
      const shown = fullText.slice(0, Math.max(charIndex, 0));
      target.innerHTML = renderHighlighted(shown) + '<span class="cursor"></span>';

      if (charIndex <= 0) {
        typing = true;
        queryIndex = (queryIndex + 1) % queries.length;
        setTimeout(tick, 350);
        return;
      }
      setTimeout(tick, 10);
    }
  }

  tick();
})();