# 🦇 Dracula Theme Integration für REDAXO Anleitung

## Installation

1. **Kopiere den `dracula-theme` Ordner** in das gleiche Verzeichnis wie deine HTML-Datei

2. **Öffne deine HTML-Datei** und füge folgende Zeilen hinzu:

### Im `<head>` Bereich:
```html
<!-- Dracula Theme CSS -->
<link rel="stylesheet" href="dracula-theme/css/dracula.min.css">
<link rel="stylesheet" href="dracula-theme/css/dracula-custom.css">
```

### Vor dem `</body>` Tag:
```html
<!-- Highlight.js -->
<script src="dracula-theme/js/highlight.min.js"></script>
<script src="dracula-theme/js/php.min.js"></script>

<!-- Initialisierung -->
<script>
document.addEventListener('DOMContentLoaded', function() {
    // Finde alle Code-Blöcke
    document.querySelectorAll('.code-block pre code').forEach((block) => {
        // Füge die PHP-Klasse hinzu wenn data-lang="PHP"
        const codeBlock = block.closest('.code-block');
        if (codeBlock && codeBlock.getAttribute('data-lang') === 'PHP') {
            block.classList.add('language-php');
        }

        // Highlight den Code
        hljs.highlightElement(block);
    });
});
</script>
```

3. **Entferne oder kommentiere** die alten Code-Block Styles aus:
   - Suche nach `.code-block` in deinem bestehenden CSS
   - Kommentiere diese Regeln aus oder lösche sie

## Features

- ✅ Original JetBrains Dracula Farbschema
- ✅ JetBrains Mono Schriftart
- ✅ PHP-optimiertes Syntax Highlighting
- ✅ Smooth Scrollbars im Dracula Style
- ✅ Responsive und mobile-friendly

## Anpassungen

Falls du die Schriftgröße ändern möchtest, editiere in `dracula-custom.css`:
```css
.hljs {
    font-size: 14px !important; /* Ändere diesen Wert */
}
```

## Struktur

```
dracula-theme/
├── css/
│   ├── dracula.min.css      # Original Dracula Theme
│   └── dracula-custom.css   # Anpassungen für JetBrains Look
├── js/
│   ├── highlight.min.js     # Highlight.js Core
│   └── php.min.js          # PHP Language Support
├── fonts/
│   ├── JetBrainsMono-Regular.woff2
│   └── JetBrainsMono-Bold.woff2
└── README.md
```

## Troubleshooting

**Code wird nicht highlighted:**
- Stelle sicher, dass die Pfade zu den Dateien korrekt sind
- Prüfe die Browser-Konsole auf Fehler
- Stelle sicher, dass das Script NACH dem DOM geladen wird

**Schriftart wird nicht angezeigt:**
- Prüfe, ob die Font-Dateien korrekt geladen werden (Netzwerk-Tab im Browser)
- Stelle sicher, dass die Pfade in der CSS-Datei stimmen

---
Viel Spaß mit deinem neuen Dracula Theme! 🦇
