#!/bin/bash

# ========================================
# JetBrains Darcula Theme Setup für Code-Highlighting
# ========================================
# Dieses Script erstellt ein exaktes JetBrains Darcula Theme
# wie in PHPStorm/WebStorm

echo "🌙 JetBrains Darcula Theme Setup für REDAXO Anleitung"
echo "====================================================="

# Erstelle Verzeichnisstruktur
echo "📁 Erstelle Verzeichnisse..."
mkdir -p jetbrains-darcula/{css,js,fonts}

# Download Highlight.js (wir brauchen nur die Core Library)
echo "📥 Lade Highlight.js..."
curl -o jetbrains-darcula/js/highlight.min.js https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.9.0/highlight.min.js

# Download PHP Language Support
echo "📥 Lade PHP Language Support..."
curl -o jetbrains-darcula/js/php.min.js https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.9.0/languages/php.min.js
curl -o jetbrains-darcula/js/xml.min.js https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.9.0/languages/xml.min.js

# Download JetBrains Mono Font
echo "📥 Lade JetBrains Mono Font..."
curl -L -o jetbrains-darcula/fonts/JetBrainsMono.zip https://github.com/JetBrains/JetBrainsMono/releases/download/v2.304/JetBrainsMono-2.304.zip

# Entpacke Font
echo "📦 Entpacke Font..."
cd jetbrains-darcula/fonts
unzip -q JetBrainsMono.zip
mv fonts/webfonts/*.woff2 .
rm -rf fonts META-INF OFL.txt AUTHORS.txt JetBrainsMono.zip
cd ../..

# Erstelle exaktes JetBrains Darcula Theme CSS
echo "🎨 Erstelle JetBrains Darcula Theme CSS..."
cat > jetbrains-darcula/css/darcula-theme.css << 'EOF'
/* JetBrains Mono Font */
@font-face {
    font-family: 'JetBrains Mono';
    src: url('../fonts/JetBrainsMono-Regular.woff2') format('woff2');
    font-weight: 400;
    font-style: normal;
    font-display: swap;
}

@font-face {
    font-family: 'JetBrains Mono';
    src: url('../fonts/JetBrainsMono-Bold.woff2') format('woff2');
    font-weight: 700;
    font-style: normal;
    font-display: swap;
}

/* JetBrains Darcula Theme - Exakte Farben */
.hljs {
    background: #2b2b2b !important;
    color: #a9b7c6 !important;
    font-family: 'JetBrains Mono', 'Consolas', 'Monaco', monospace !important;
    font-size: 13px !important;
    line-height: 1.5 !important;
    padding: 20px !important;
    border-radius: 8px !important;
    overflow-x: auto !important;
}

/* PHP Keywords (orange) - class, private, function, case, if, else, new */
.hljs-keyword,
.hljs-selector-tag,
.hljs-literal,
.hljs-type {
    color: #cc7832 !important;
    font-weight: normal !important;
}

/* Strings (grün) */
.hljs-string,
.hljs-doctag {
    color: #6a8759 !important;
}

/* Zahlen */
.hljs-number {
    color: #6897bb !important;
}

/* Funktionsaufrufe (gelb) - get(), isLogin(), getPage() */
.hljs-title.function_,
.hljs-title.function,
.hljs-built_in {
    color: #ffc66d !important;
    font-weight: normal !important;
}

/* Variablen (lila) - $user, $p, $this */
.hljs-variable,
.language-php .hljs-variable {
    color: #9876aa !important;
}

/* Klassen und Namespaces (grau/weiß) */
.hljs-title.class_,
.hljs-title.class,
.hljs-class {
    color: #a9b7c6 !important;
}

/* Kommentare */
.hljs-comment,
.hljs-quote {
    color: #808080 !important;
    font-style: italic !important;
}

/* Meta/Tags (PHP öffnende Tags) */
.hljs-meta {
    color: #bbb529 !important;
}

/* Properties und Methoden nach -> */
.hljs-property,
.hljs-attr {
    color: #a9b7c6 !important;
}

/* HTML/XML Tags */
.hljs-tag {
    color: #e8bf6a !important;
}

.hljs-tag .hljs-name {
    color: #e8bf6a !important;
}

.hljs-tag .hljs-attr {
    color: #bababa !important;
}

.hljs-attribute {
    color: #bababa !important;
}

/* Namespace Separators */
.hljs-operator,
.hljs-punctuation {
    color: #a9b7c6 !important;
}

/* PHP spezifische Anpassungen */
.language-php .hljs-meta {
    color: #bbb529 !important;
    font-weight: normal !important;
}

.language-php .hljs-meta-keyword {
    color: #bbb529 !important;
}

/* Namespace Teile */
.language-php .hljs-title.class_::before {
    color: #808080 !important;
}

/* This, self, parent keywords */
.language-php .hljs-variable.language_ {
    color: #9876aa !important;
    font-weight: normal !important;
}

/* String Interpolation */
.language-php .hljs-subst {
    color: #a9b7c6 !important;
}

/* :: und -> Operatoren */
.language-php .hljs-operator {
    color: #a9b7c6 !important;
}

/* Code Container */
.code-block {
    position: relative !important;
    margin: 20px 0 !important;
    background: #2b2b2b !important;
    border-radius: 8px !important;
    box-shadow: 0 2px 8px rgba(0, 0, 0, 0.5) !important;
    border: 1px solid #3c3c3c !important;
}

.code-block pre {
    margin: 0 !important;
    background: transparent !important;
}

.code-block code {
    background: transparent !important;
    padding: 0 !important;
    font-family: 'JetBrains Mono', monospace !important;
    display: block !important;
}

/* Language Badge */
.code-block::before {
    content: attr(data-lang);
    position: absolute;
    top: 0;
    right: 0;
    background: #3c3c3c;
    color: #a9b7c6;
    padding: 5px 15px;
    border-radius: 0 7px 0 8px;
    font-size: 11px;
    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
    font-weight: 500;
    z-index: 1;
    border-left: 1px solid #2b2b2b;
    border-bottom: 1px solid #2b2b2b;
}

/* Scrollbar für Webkit Browser */
.hljs::-webkit-scrollbar {
    height: 10px;
    width: 10px;
}

.hljs::-webkit-scrollbar-track {
    background: #3c3c3c;
    border-radius: 5px;
}

.hljs::-webkit-scrollbar-thumb {
    background: #606366;
    border-radius: 5px;
}

.hljs::-webkit-scrollbar-thumb:hover {
    background: #6e7275;
}

/* Selection */
.hljs::selection,
.hljs *::selection {
    background: #214283;
    color: inherit;
}

/* Inline Code */
code:not(.hljs) {
    background: #3c3c3c;
    color: #6a8759;
    padding: 2px 6px;
    border-radius: 3px;
    font-family: 'JetBrains Mono', monospace;
    font-size: 0.9em;
    border: 1px solid #555555;
}

/* Line Numbers (optional) */
.hljs-ln-numbers {
    color: #606366 !important;
    border-right: 1px solid #3c3c3c !important;
    padding-right: 10px !important;
    margin-right: 10px !important;
}

/* REX_VALUE, REX_MEDIA usw. highlighting */
.hljs-constant {
    color: #9876aa !important;
    font-weight: bold !important;
}

/* Spezielle PHP Patterns für REDAXO */
.token-rex-value {
    color: #9876aa !important;
    font-weight: bold !important;
}

.token-rex-function {
    color: #ffc66d !important;
}
EOF

# Erstelle erweiterte Initialisierung für besseres Highlighting
echo "📄 Erstelle erweiterte Initialisierung..."
cat > jetbrains-darcula/js/darcula-init.js << 'EOF'
// JetBrains Darcula Theme Initialisierung
document.addEventListener('DOMContentLoaded', function() {
    // Registriere zusätzliche Patterns für REDAXO
    hljs.configure({
        classPrefix: 'hljs-',
        languages: ['php', 'xml', 'html']
    });

    // Highlight alle Code-Blöcke
    document.querySelectorAll('.code-block pre code').forEach((block) => {
        // Füge die PHP-Klasse hinzu wenn data-lang="PHP"
        const codeBlock = block.closest('.code-block');
        if (codeBlock && codeBlock.getAttribute('data-lang') === 'PHP') {
            block.classList.add('language-php');
        }

        // Pre-process REDAXO spezifische Tokens
        let html = block.innerHTML;

        // Highlight REX_VALUE, REX_MEDIA, etc.
        html = html.replace(/\b(REX_[A-Z_]+)(\[)/g, '<span class="hljs-constant">$1</span>$2');

        // Highlight rex_ functions
        html = html.replace(/\b(rex_[a-z_]+)(\()/g, '<span class="hljs-title function_">$1</span>$2');

        // Apply changes
        block.innerHTML = html;

        // Highlight den Code
        hljs.highlightElement(block);
    });

    // Optional: Highlight auch inline code
    document.querySelectorAll('code:not(.hljs)').forEach((block) => {
        if (block.textContent.includes('<?php') ||
            block.textContent.includes('rex_') ||
            block.textContent.includes('REX_')) {
            block.classList.add('language-php');
            hljs.highlightElement(block);
        }
    });
});
EOF

# Erstelle Integrations-HTML
echo "📄 Erstelle Integrations-Beispiel..."
cat > jetbrains-darcula/integration.html << 'EOF'
<!--
    INTEGRATION: JetBrains Darcula Theme
    ====================================

    Füge diese Zeilen in den <head> Bereich deiner HTML-Datei ein:
-->

<!-- JetBrains Darcula Theme CSS -->
<link rel="stylesheet" href="jetbrains-darcula/css/darcula-theme.css">

<!--
    Füge diese Zeilen VOR dem schließenden </body> Tag ein:
-->

<!-- Highlight.js -->
<script src="jetbrains-darcula/js/highlight.min.js"></script>
<script src="jetbrains-darcula/js/php.min.js"></script>
<script src="jetbrains-darcula/js/xml.min.js"></script>
<script src="jetbrains-darcula/js/darcula-init.js"></script>
EOF

# Erstelle README
echo "📝 Erstelle README..."
cat > jetbrains-darcula/README.md << 'EOF'
# 🌙 JetBrains Darcula Theme für REDAXO Anleitung

Exakte Nachbildung des JetBrains Darcula Themes aus PHPStorm/WebStorm.

## Installation

1. **Kopiere den `jetbrains-darcula` Ordner** in das gleiche Verzeichnis wie deine HTML-Datei

2. **Öffne deine HTML-Datei** und füge folgende Zeilen hinzu:

### Im `<head>` Bereich:
```html
<!-- JetBrains Darcula Theme CSS -->
<link rel="stylesheet" href="jetbrains-darcula/css/darcula-theme.css">
```

### Vor dem `</body>` Tag:
```html
<!-- Highlight.js mit JetBrains Darcula -->
<script src="jetbrains-darcula/js/highlight.min.js"></script>
<script src="jetbrains-darcula/js/php.min.js"></script>
<script src="jetbrains-darcula/js/xml.min.js"></script>
<script src="jetbrains-darcula/js/darcula-init.js"></script>
```

3. **Entferne oder kommentiere** die alten Code-Block Styles aus

## Farb-Referenz (Exakte JetBrains Darcula Farben)

| Element | Farbe | Hex |
|---------|-------|-----|
| Background | Dunkelgrau | `#2b2b2b` |
| Default Text | Hellgrau | `#a9b7c6` |
| Keywords | Orange | `#cc7832` |
| Strings | Grün | `#6a8759` |
| Functions | Gelb | `#ffc66d` |
| Variables | Lila | `#9876aa` |
| Numbers | Blau | `#6897bb` |
| Comments | Grau | `#808080` |
| PHP Tags | Gelb-Grün | `#bbb529` |

## Features

- ✅ 100% akkurate JetBrains Darcula Farben
- ✅ JetBrains Mono Schriftart
- ✅ REDAXO-spezifisches Highlighting (REX_VALUE, rex_functions)
- ✅ Optimiert für PHP und HTML/XML
- ✅ IDE-like Scrollbars und Selection
- ✅ Responsive und performant

## Anpassungen

### Schriftgröße ändern:
```css
.hljs {
    font-size: 13px !important; /* Standard JetBrains Größe */
}
```

### Line Numbers aktivieren:
Füge `hljs-ln.min.js` hinzu und initialisiere mit:
```javascript
hljs.initLineNumbersOnLoad();
```

## Struktur

```
jetbrains-darcula/
├── css/
│   └── darcula-theme.css    # Komplettes Theme
├── js/
│   ├── highlight.min.js     # Core Library
│   ├── php.min.js          # PHP Support
│   ├── xml.min.js          # XML/HTML Support
│   └── darcula-init.js     # Initialisierung
├── fonts/
│   ├── JetBrainsMono-Regular.woff2
│   └── JetBrainsMono-Bold.woff2
└── README.md
```

## Vergleich mit JetBrains IDE

Dieses Theme reproduziert exakt die Farben aus:
- PHPStorm 2023.x
- WebStorm 2023.x
- IntelliJ IDEA Ultimate

mit dem Standard Darcula Theme.

---
Genieße das authentische JetBrains Feeling! 🌙
EOF

# Erstelle Test HTML
echo "📄 Erstelle Test-Datei..."
cat > jetbrains-darcula/test.html << 'EOF'
<!DOCTYPE html>
<html lang="de">
<head>
    <meta charset="UTF-8">
    <title>JetBrains Darcula Theme Test</title>
    <link rel="stylesheet" href="css/darcula-theme.css">
    <style>
        body {
            background: #1e1e1e;
            padding: 20px;
            font-family: -apple-system, sans-serif;
        }
        h1 { color: #a9b7c6; }
        .container { max-width: 800px; margin: 0 auto; }
    </style>
</head>
<body>
    <div class="container">
        <h1>JetBrains Darcula Theme Test</h1>

        <div class="code-block" data-lang="PHP">
            <pre><code>&lt;?php
class Handler {
    private function getPage() {
        // Kommentar
        switch ($action) {
            case 'weiterbildung':
                $user = \App\User::get();

                if (\App\User::isLogin()) {
                    $p = new \App\Weiterbildung($this->get_params, $this->post_params);
                    $this->html = $p->getPage();
                } else {
                    redirect('/login');
                }
                break;

            default:
                $this->html = 'Seite nicht gefunden';
        }

        // REDAXO spezifisch
        $article = rex_article::getCurrent();
        $value = 'REX_VALUE[1]';
        $media = 'REX_MEDIA[1]';
    }
}</code></pre>
        </div>
    </div>

    <script src="js/highlight.min.js"></script>
    <script src="js/php.min.js"></script>
    <script src="js/xml.min.js"></script>
    <script src="js/darcula-init.js"></script>
</body>
</html>
EOF

echo ""
echo "✅ Setup abgeschlossen!"
echo ""
echo "📁 Struktur erstellt:"
tree jetbrains-darcula 2>/dev/null || find jetbrains-darcula -type f | sed 's|[^/]*/|- |g'
echo ""
echo "📖 Nächste Schritte:"
echo "1. Kopiere den 'jetbrains-darcula' Ordner in dein Projekt"
echo "2. Folge den Anweisungen in jetbrains-darcula/README.md"
echo "3. Teste mit jetbrains-darcula/test.html"
echo ""
echo "🌙 Viel Spaß mit dem authentischen JetBrains Darcula Theme!"