#!/bin/bash
# Pfad: ./setup.sh

set -e

# Farben für Ausgabe
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Funktion für farbige Ausgabe
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Projektname ermitteln
if [ -z "$1" ]; then
    read -p "Bitte geben Sie den Projektnamen ein: " PROJECT_NAME
else
    PROJECT_NAME=$1
fi

# Validierung des Projektnamens
if [[ ! "$PROJECT_NAME" =~ ^[a-zA-Z0-9_-]+$ ]]; then
    print_error "Ungültiger Projektname. Erlaubt sind nur Buchstaben, Zahlen, - und _"
    exit 1
fi

# Prüfen ob Projekt bereits existiert
if [ -d "$PROJECT_NAME" ]; then
    print_error "Das Verzeichnis '$PROJECT_NAME' existiert bereits!"
    exit 1
fi

print_info "Erstelle Projekt: $PROJECT_NAME"

# Hauptverzeichnis erstellen
mkdir -p "$PROJECT_NAME"
cd "$PROJECT_NAME"

# Projektstruktur erstellen
print_info "Erstelle Projektstruktur..."
mkdir -p apache-php
mkdir -p www/dev/dist

# Redaxo herunterladen
print_info "Lade Redaxo 5.19.0 herunter..."
curl -L -o redaxo-5.19.0.zip https://redaxo.org/download/redaxo/5.19.0.zip

# Entpacken mit verbesserter Methode
print_info "Entpacke Redaxo..."
# Temporäres Verzeichnis erstellen
rm -rf temp_redaxo
mkdir -p temp_redaxo

# ZIP entpacken
unzip -q redaxo-5.19.0.zip -d temp_redaxo

# Debug: Zeige was entpackt wurde
print_info "Analysiere ZIP-Struktur..."
find temp_redaxo -maxdepth 2 -type d | head -10

# Prüfe ob direkt Dateien oder in Unterordner entpackt wurde
if [ -f "temp_redaxo/index.php" ] || [ -d "temp_redaxo/redaxo" ]; then
    # Fall 1: Dateien sind direkt in temp_redaxo
    print_info "Dateien direkt im Hauptverzeichnis gefunden"
    cp -R temp_redaxo/* www/dev/dist/
elif [ -d "temp_redaxo/redaxo_5.19.0" ]; then
    # Fall 2: Dateien sind in redaxo_5.19.0 Unterordner
    print_info "Gefunden: temp_redaxo/redaxo_5.19.0"
    cp -R temp_redaxo/redaxo_5.19.0/* www/dev/dist/
else
    # Fall 3: Suche nach einem einzelnen Ordner
    SINGLE_DIR=$(find temp_redaxo -maxdepth 1 -mindepth 1 -type d | head -1)
    if [ -n "$SINGLE_DIR" ] && [ $(find temp_redaxo -maxdepth 1 -mindepth 1 -type d | wc -l) -eq 1 ]; then
        print_info "Einzelner Ordner gefunden: $SINGLE_DIR"
        cp -R "$SINGLE_DIR"/* www/dev/dist/
    else
        print_error "Unerwartete ZIP-Struktur!"
        ls -la temp_redaxo/
        exit 1
    fi
fi

# Aufräumen
rm -rf temp_redaxo

# Prüfen ob Installation erfolgreich
if [ ! -f "www/dev/dist/index.php" ] && [ ! -d "www/dev/dist/redaxo" ]; then
    print_error "Installation fehlgeschlagen - keine index.php oder redaxo-Ordner gefunden!"
    print_info "Inhalt von www/dev/dist:"
    ls -la www/dev/dist/
    exit 1
else
    print_info "Redaxo erfolgreich entpackt!"
fi

# .env Datei erstellen
print_info "Erstelle .env Datei..."
cat > .env << EOF
# Projekt: $PROJECT_NAME
PROJECT_NAME=$PROJECT_NAME

# Ports
WEB_PORT=8082
DB_PORT=3306
PMA_PORT=8083

# Datenbank
MYSQL_ROOT_PASSWORD=rootpass
MYSQL_DATABASE=redaxo_db
MYSQL_USER=redaxo_user
MYSQL_PASSWORD=redaxo_pass

# Container Präfix
CONTAINER_PREFIX=${PROJECT_NAME}
EOF

# docker-compose.yml erstellen
print_info "Erstelle docker-compose.yml..."
cat > docker-compose.yml << 'EOF'
# Pfad: ./docker-compose.yml

services:
  web:
    build: ./apache-php
    container_name: ${CONTAINER_PREFIX}_apache
    ports:
      - "${WEB_PORT}:80"
    volumes:
      - ./apache-php/apache.conf:/etc/apache2/sites-enabled/000-default.conf
      - ./www/dev/dist:/var/www/html
    depends_on:
      - db
    networks:
      - project_network
    environment:
      - PROJECT_NAME=${PROJECT_NAME}

  db:
    image: mariadb:10.11
    container_name: ${CONTAINER_PREFIX}_mariadb
    environment:
      MYSQL_ROOT_PASSWORD: ${MYSQL_ROOT_PASSWORD}
      MYSQL_DATABASE: ${MYSQL_DATABASE}
      MYSQL_USER: ${MYSQL_USER}
      MYSQL_PASSWORD: ${MYSQL_PASSWORD}
    ports:
      - "${DB_PORT}:3306"
    volumes:
      - db_data:/var/lib/mysql
    networks:
      - project_network

  phpmyadmin:
    image: phpmyadmin/phpmyadmin
    container_name: ${CONTAINER_PREFIX}_pma
    restart: always
    ports:
      - "${PMA_PORT}:80"
    environment:
      PMA_HOST: db
      PMA_USER: root
      PMA_PASSWORD: ${MYSQL_ROOT_PASSWORD}
    depends_on:
      - db
    networks:
      - project_network

volumes:
  db_data:
    name: ${CONTAINER_PREFIX}_db_data

networks:
  project_network:
    name: ${CONTAINER_PREFIX}_net
    driver: bridge
EOF

# Dockerfile erstellen
print_info "Erstelle Dockerfile..."
cat > apache-php/Dockerfile << 'EOF'
# Pfad: ./apache-php/Dockerfile

FROM php:8.2-apache

# System-Pakete installieren
RUN apt-get update && apt-get install -y \
    mariadb-client \
    libzip-dev zip unzip \
    libpng-dev libjpeg-dev libfreetype6-dev \
    libonig-dev libcurl4-openssl-dev libicu-dev \
    && rm -rf /var/lib/apt/lists/*

# PHP Extensions konfigurieren und installieren
RUN docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install pdo pdo_mysql zip gd mbstring curl intl opcache

# Apache Module aktivieren
RUN a2enmod rewrite headers expires

# PHP Konfiguration optimieren
RUN { \
    echo 'opcache.memory_consumption=128'; \
    echo 'opcache.interned_strings_buffer=8'; \
    echo 'opcache.max_accelerated_files=4000'; \
    echo 'opcache.revalidate_freq=2'; \
    echo 'opcache.fast_shutdown=1'; \
    echo 'opcache.enable_cli=1'; \
} > /usr/local/etc/php/conf.d/opcache-recommended.ini

# Upload Limits erhöhen
RUN { \
    echo 'upload_max_filesize=64M'; \
    echo 'post_max_size=64M'; \
    echo 'max_execution_time=300'; \
    echo 'memory_limit=256M'; \
} > /usr/local/etc/php/conf.d/uploads.ini

# Arbeitsverzeichnis
WORKDIR /var/www/html

# Benutzer www-data verwenden
USER www-data
EOF

# Apache Konfiguration erstellen
print_info "Erstelle Apache Konfiguration..."
cat > apache-php/apache.conf << 'EOF'
# Pfad: ./apache-php/apache.conf

<VirtualHost *:80>
    ServerAdmin webmaster@localhost
    DocumentRoot /var/www/html

    # Hauptverzeichnis Konfiguration
    <Directory /var/www/html>
        Options -Indexes +FollowSymLinks
        AllowOverride All
        Require all granted

        # Sicherheitsheader
        Header set X-Frame-Options "SAMEORIGIN"
        Header set X-Content-Type-Options "nosniff"
        Header set X-XSS-Protection "1; mode=block"
    </Directory>

    # Sicherheit: Sensible Verzeichnisse sperren
    <Directory /var/www/html/bin>
        Require all denied
    </Directory>

    <Directory /var/www/html/cache>
        Require all denied
    </Directory>

    <Directory /var/www/html/data>
        Require all denied
    </Directory>

    <Directory /var/www/html/src>
        Require all denied
    </Directory>

    # Redaxo spezifische Einstellungen
    <Directory /var/www/html/redaxo>
        Options -Indexes
    </Directory>

    # Logs
    ErrorLog ${APACHE_LOG_DIR}/error.log
    CustomLog ${APACHE_LOG_DIR}/access.log combined

    # Kompression aktivieren
    <IfModule mod_deflate.c>
        AddOutputFilterByType DEFLATE text/html text/plain text/xml text/css text/javascript application/javascript application/json
    </IfModule>
</VirtualHost>
EOF

# Start-Skript erstellen
print_info "Erstelle start.sh..."
cat > start.sh << 'EOF'
#!/bin/bash
# Pfad: ./start.sh

# Farben
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# .env laden
if [ -f .env ]; then
    export $(cat .env | grep -v '^#' | xargs)
fi

echo -e "${GREEN}Starte Docker Container für Projekt: $PROJECT_NAME${NC}"
docker-compose up -d

echo -e "\n${GREEN}Container gestartet!${NC}"
echo -e "${YELLOW}Webseite:${NC} http://localhost:$WEB_PORT"
echo -e "${YELLOW}phpMyAdmin:${NC} http://localhost:$PMA_PORT"
echo -e "${YELLOW}Datenbank:${NC} localhost:$DB_PORT"
echo -e "\n${YELLOW}Datenbank-Zugangsdaten:${NC}"
echo -e "  Host: db"
echo -e "  Datenbank: $MYSQL_DATABASE"
echo -e "  Benutzer: $MYSQL_USER"
echo -e "  Passwort: $MYSQL_PASSWORD"
EOF

# Stop-Skript erstellen
print_info "Erstelle stop.sh..."
cat > stop.sh << 'EOF'
#!/bin/bash
# Pfad: ./stop.sh

# Farben
RED='\033[0;31m'
NC='\033[0m'

# .env laden
if [ -f .env ]; then
    export $(cat .env | grep -v '^#' | xargs)
fi

echo -e "${RED}Stoppe Docker Container für Projekt: $PROJECT_NAME${NC}"
docker-compose down
EOF

# Status-Skript erstellen
print_info "Erstelle status.sh..."
cat > status.sh << 'EOF'
#!/bin/bash
# Pfad: ./status.sh

# Farben
BLUE='\033[0;34m'
NC='\033[0m'

# .env laden
if [ -f .env ]; then
    export $(cat .env | grep -v '^#' | xargs)
fi

echo -e "${BLUE}Status für Projekt: $PROJECT_NAME${NC}\n"
docker-compose ps
EOF

# Logs-Skript erstellen
print_info "Erstelle logs.sh..."
cat > logs.sh << 'EOF'
#!/bin/bash
# Pfad: ./logs.sh

# Parameter: Container-Name (web, db, phpmyadmin)
CONTAINER=$1

if [ -z "$CONTAINER" ]; then
    echo "Verwendung: ./logs.sh [web|db|phpmyadmin]"
    echo "Oder: ./logs.sh all (für alle Container)"
    exit 1
fi

# .env laden
if [ -f .env ]; then
    export $(cat .env | grep -v '^#' | xargs)
fi

if [ "$CONTAINER" == "all" ]; then
    docker-compose logs -f
else
    docker-compose logs -f $CONTAINER
fi
EOF

# Shell-Skript erstellen
print_info "Erstelle shell.sh..."
cat > shell.sh << 'EOF'
#!/bin/bash
# Pfad: ./shell.sh

# .env laden
if [ -f .env ]; then
    export $(cat .env | grep -v '^#' | xargs)
fi

# In den Web-Container einloggen
docker exec -it ${CONTAINER_PREFIX}_apache bash
EOF

# Cleanup-Skript erstellen
print_info "Erstelle cleanup.sh..."
cat > cleanup.sh << 'EOF'
#!/bin/bash
# Pfad: ./cleanup.sh

# Farben
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# .env laden
if [ -f .env ]; then
    export $(cat .env | grep -v '^#' | xargs)
fi

echo -e "${RED}WARNUNG: Dies löscht alle Container, Volumes und Netzwerke für Projekt: $PROJECT_NAME${NC}"
read -p "Sind Sie sicher? (y/N) " -n 1 -r
echo

if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Stoppe und lösche Container...${NC}"
    docker-compose down -v
    echo -e "${RED}Cleanup abgeschlossen!${NC}"
else
    echo "Abgebrochen."
fi
EOF

# Update-Skript erstellen
print_info "Erstelle update.sh..."
cat > update.sh << 'EOF'
#!/bin/bash
# Pfad: ./update.sh

set -e

# Farben für Ausgabe
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# .env laden
if [ -f .env ]; then
    export $(cat .env | grep -v '^#' | xargs)
else
    echo -e "${RED}[ERROR]${NC} .env Datei nicht gefunden!"
    exit 1
fi

echo -e "${BLUE}Update-Skript für Projekt: $PROJECT_NAME${NC}\n"

# Funktion für Redaxo Update
update_redaxo() {
    echo -e "${YELLOW}Verfügbare Redaxo Versionen:${NC}"
    echo "1) 5.19.0 (aktuell installiert)"
    echo "2) 5.18.1"
    echo "3) 5.17.1"
    echo "4) Andere Version eingeben"
    echo "5) Abbrechen"

    read -p "Wählen Sie eine Option (1-5): " choice

    case $choice in
        1)
            VERSION="5.19.0"
            ;;
        2)
            VERSION="5.18.1"
            ;;
        3)
            VERSION="5.17.1"
            ;;
        4)
            read -p "Geben Sie die Versionsnummer ein (z.B. 5.16.0): " VERSION
            ;;
        5)
            echo "Update abgebrochen."
            return
            ;;
        *)
            echo -e "${RED}Ungültige Auswahl!${NC}"
            return
            ;;
    esac

    echo -e "\n${YELLOW}WARNUNG: Dies überschreibt die aktuelle Redaxo-Installation!${NC}"
    echo -e "${YELLOW}Stellen Sie sicher, dass Sie ein Backup haben!${NC}"
    read -p "Fortfahren? (y/N) " -n 1 -r
    echo

    if [[ $REPLY =~ ^[Yy]$ ]]; then
        # Backup erstellen
        echo -e "\n${GREEN}Erstelle Backup...${NC}"
        BACKUP_NAME="backup_$(date +%Y%m%d_%H%M%S)"
        mkdir -p backups
        tar -czf "backups/${BACKUP_NAME}_files.tar.gz" www/dev/dist/

        # Datenbank-Backup
        if docker ps | grep -q "${CONTAINER_PREFIX}_mariadb"; then
            echo -e "${GREEN}Erstelle Datenbank-Backup...${NC}"
            docker exec ${CONTAINER_PREFIX}_mariadb mysqldump -u root -p${MYSQL_ROOT_PASSWORD} ${MYSQL_DATABASE} > "backups/${BACKUP_NAME}_database.sql"
        fi

        # Neue Version herunterladen
        echo -e "\n${GREEN}Lade Redaxo $VERSION herunter...${NC}"
        curl -L -o "redaxo-${VERSION}.zip" "https://redaxo.org/download/redaxo/${VERSION}.zip"

        # Alte Installation sichern und neue entpacken
        echo -e "${GREEN}Installiere neue Version...${NC}"
        rm -rf www/dev/dist_old
        mv www/dev/dist www/dev/dist_old
        mkdir -p www/dev/dist

        # Temporäres Verzeichnis für Entpacken
        rm -rf temp_redaxo
        mkdir -p temp_redaxo
        unzip -q "redaxo-${VERSION}.zip" -d temp_redaxo

        # Prüfe ob direkt Dateien oder in Unterordner entpackt wurde
        if [ -f "temp_redaxo/index.php" ] || [ -d "temp_redaxo/redaxo" ]; then
            # Dateien sind direkt in temp_redaxo
            cp -R temp_redaxo/* www/dev/dist/
        elif [ -d "temp_redaxo/redaxo_${VERSION}" ]; then
            # Dateien sind in versionsspezifischem Unterordner
            cp -R "temp_redaxo/redaxo_${VERSION}"/* www/dev/dist/
        else
            # Suche nach einem einzelnen Ordner
            SINGLE_DIR=$(find temp_redaxo -maxdepth 1 -mindepth 1 -type d | head -1)
            if [ -n "$SINGLE_DIR" ]; then
                cp -R "$SINGLE_DIR"/* www/dev/dist/
            else
                cp -R temp_redaxo/* www/dev/dist/
            fi
        fi

        rm -rf temp_redaxo

        # Konfiguration und Media wiederherstellen
        if [ -d "www/dev/dist_old/media" ]; then
            echo -e "${GREEN}Stelle Media-Dateien wieder her...${NC}"
            cp -r www/dev/dist_old/media/* www/dev/dist/media/ 2>/dev/null || true
        fi

        if [ -f "www/dev/dist_old/data/config.yml" ]; then
            echo -e "${GREEN}Stelle Konfiguration wieder her...${NC}"
            cp www/dev/dist_old/data/config.yml www/dev/dist/data/
        fi

        echo -e "\n${GREEN}✅ Update abgeschlossen!${NC}"
        echo -e "${YELLOW}Backup gespeichert unter: backups/${BACKUP_NAME}${NC}"
        echo -e "${YELLOW}Alte Installation unter: www/dev/dist_old${NC}"
        echo -e "\n${RED}WICHTIG: Führen Sie das Redaxo-Setup im Browser aus!${NC}"
    else
        echo "Update abgebrochen."
    fi
}

# Funktion für Docker Images Update
update_docker_images() {
    echo -e "${BLUE}Aktualisiere Docker Images...${NC}"

    # Container stoppen
    echo -e "${YELLOW}Stoppe Container...${NC}"
    docker-compose down

    # Images aktualisieren
    echo -e "${GREEN}Lade neue Images...${NC}"
    docker-compose pull

    # Apache/PHP Image neu bauen
    echo -e "${GREEN}Baue Apache/PHP Image neu...${NC}"
    docker-compose build --no-cache web

    # Container wieder starten
    echo -e "${GREEN}Starte Container...${NC}"
    docker-compose up -d

    echo -e "\n${GREEN}✅ Docker Images aktualisiert!${NC}"
}

# Funktion für Backup
create_backup() {
    echo -e "${BLUE}Erstelle vollständiges Backup...${NC}"

    BACKUP_NAME="full_backup_$(date +%Y%m%d_%H%M%S)"
    mkdir -p backups

    # Dateien sichern
    echo -e "${GREEN}Sichere Dateien...${NC}"
    tar -czf "backups/${BACKUP_NAME}_files.tar.gz" www/

    # Datenbank sichern
    if docker ps | grep -q "${CONTAINER_PREFIX}_mariadb"; then
        echo -e "${GREEN}Sichere Datenbank...${NC}"
        docker exec ${CONTAINER_PREFIX}_mariadb mysqldump -u root -p${MYSQL_ROOT_PASSWORD} ${MYSQL_DATABASE} > "backups/${BACKUP_NAME}_database.sql"

        # SQL-Datei komprimieren
        gzip "backups/${BACKUP_NAME}_database.sql"
    else
        echo -e "${YELLOW}Container läuft nicht - überspringe Datenbank-Backup${NC}"
    fi

    # Konfiguration sichern
    echo -e "${GREEN}Sichere Konfiguration...${NC}"
    tar -czf "backups/${BACKUP_NAME}_config.tar.gz" .env docker-compose.yml apache-php/

    echo -e "\n${GREEN}✅ Backup abgeschlossen!${NC}"
    echo -e "${YELLOW}Gespeichert unter: backups/${BACKUP_NAME}_*${NC}"

    # Alte Backups aufräumen (optional)
    echo -e "\n${BLUE}Alte Backups (älter als 30 Tage):${NC}"
    find backups -name "*.tar.gz" -o -name "*.sql.gz" -mtime +30 -ls

    read -p "Alte Backups löschen? (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        find backups -name "*.tar.gz" -o -name "*.sql.gz" -mtime +30 -delete
        echo -e "${GREEN}Alte Backups gelöscht!${NC}"
    fi
}

# Hauptmenü
echo "Was möchten Sie aktualisieren?"
echo "1) Redaxo Version"
echo "2) Docker Images (MariaDB, phpMyAdmin, PHP)"
echo "3) Vollständiges Backup erstellen"
echo "4) Abbrechen"

read -p "Wählen Sie eine Option (1-4): " main_choice

case $main_choice in
    1)
        update_redaxo
        ;;
    2)
        update_docker_images
        ;;
    3)
        create_backup
        ;;
    4)
        echo "Abgebrochen."
        exit 0
        ;;
    *)
        echo -e "${RED}Ungültige Auswahl!${NC}"
        exit 1
        ;;
esac
EOF

# .gitignore erstellen
print_info "Erstelle .gitignore..."
cat > .gitignore << 'EOF'
# Environment Dateien
.env
.env.local
.env.*.local

# Redaxo Dateien
www/dev/dist/media/*
!www/dev/dist/media/.gitkeep
www/dev/dist/cache/*
!www/dev/dist/cache/.gitkeep
www/dev/dist/data/config.yml
www/dev/dist/data/addons/*
www/dev/dist/redaxo/cache/*

# Backup Dateien
backups/
*.sql
*.sql.gz
backup_*.tar.gz

# Temporäre Dateien
*.tmp
*.temp
*.log
*.swp
.DS_Store

# Docker Volumes
docker-volumes/

# IDE Dateien
.idea/
.vscode/
*.sublime-*

# Alte Versionen
www/dev/dist_old/

# ZIP Downloads
redaxo-*.zip
EOF

# Debug-Skript erstellen
print_info "Erstelle debug.sh..."
cat > debug.sh << 'EOF'
#!/bin/bash
# Pfad: ./debug.sh

# Farben
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=== Debug-Informationen ===${NC}\n"

# System-Informationen
echo -e "${YELLOW}System:${NC}"
echo "OS: $OSTYPE"
echo "Pfad: $(pwd)"
echo "Benutzer: $(whoami)"
echo

# Docker-Informationen
echo -e "${YELLOW}Docker:${NC}"
docker --version
docker-compose --version
echo

# Projektstruktur
echo -e "${YELLOW}Projektstruktur:${NC}"
if [ -d "www/dev/dist" ]; then
    echo -e "${GREEN}✓${NC} www/dev/dist existiert"
    echo "Inhalt:"
    ls -la www/dev/dist/ | head -10
    echo "..."
else
    echo -e "${RED}✗${NC} www/dev/dist existiert nicht"
fi
echo

# Redaxo ZIP Test
echo -e "${YELLOW}Redaxo ZIP Test:${NC}"
REDAXO_ZIP=$(ls redaxo-*.zip 2>/dev/null | head -1)
if [ -n "$REDAXO_ZIP" ]; then
    echo -e "${GREEN}✓${NC} $REDAXO_ZIP gefunden"
    echo "Größe: $(ls -lh $REDAXO_ZIP | awk '{print $5}')"

    # ZIP-Inhalt prüfen
    echo "ZIP-Struktur (erste Ebene):"
    unzip -l $REDAXO_ZIP | head -20
else
    echo -e "${RED}✗${NC} Keine redaxo-*.zip gefunden"
fi
echo

# Docker Status
echo -e "${YELLOW}Docker Container Status:${NC}"
if [ -f .env ]; then
    export $(cat .env | grep -v '^#' | xargs)
    docker ps -a | grep -E "(CONTAINER|$CONTAINER_PREFIX)" || echo "Keine Container gefunden"
else
    echo -e "${RED}✗${NC} .env nicht gefunden"
fi
echo

# Port-Verfügbarkeit
echo -e "${YELLOW}Port-Verfügbarkeit:${NC}"
for port in 8082 8083 3306; do
    if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1; then
        echo -e "${RED}✗${NC} Port $port ist belegt"
    else
        echo -e "${GREEN}✓${NC} Port $port ist frei"
    fi
done
echo

# Speicherplatz
echo -e "${YELLOW}Speicherplatz:${NC}"
df -h . | grep -v "Filesystem"
echo

# Berechtigungen
echo -e "${YELLOW}Berechtigungen:${NC}"
ls -ld . www www/dev www/dev/dist 2>/dev/null || echo "Einige Verzeichnisse fehlen"
echo

# Test-Entpacken
echo -e "${YELLOW}Test-Entpacken der ZIP:${NC}"
if [ -n "$REDAXO_ZIP" ]; then
    mkdir -p test_extract
    unzip -q $REDAXO_ZIP -d test_extract
    echo "Extrahierte Struktur:"
    find test_extract -maxdepth 3 -type d | head -20
    rm -rf test_extract
fi

echo -e "\n${BLUE}=== Ende Debug-Informationen ===${NC}"
EOF

# README.md erstellen
print_info "Erstelle README.md..."
cat > README.md << 'EOF'
# Redaxo Docker Entwicklungsumgebung

Projektname: PROJECT_NAME_PLACEHOLDER

## Quick Start

```bash
# Container starten
./start.sh

# Container stoppen
./stop.sh

# Status anzeigen
./status.sh
```

## Zugriff

- **Redaxo**: http://localhost:WEB_PORT_PLACEHOLDER
- **phpMyAdmin**: http://localhost:PMA_PORT_PLACEHOLDER
- **MariaDB**: localhost:DB_PORT_PLACEHOLDER

## Datenbank-Zugangsdaten

- Host: `db`
- Datenbank: `MYSQL_DATABASE_PLACEHOLDER`
- Benutzer: `MYSQL_USER_PLACEHOLDER`
- Passwort: Siehe .env Datei

## Weitere Informationen

Siehe die ausführliche README.md im Hauptverzeichnis.
EOF

# Variablen für README definieren
MYSQL_DATABASE="redaxo_db"
MYSQL_USER="redaxo_user"

# Platzhalter in README ersetzen - Robuste Methode für macOS und Linux
print_info "Konfiguriere README.md..."

# Methode 1: Verwende perl (auf macOS immer verfügbar)
if command -v perl >/dev/null 2>&1; then
    perl -i -pe "s/PROJECT_NAME_PLACEHOLDER/$PROJECT_NAME/g" README.md
    perl -i -pe "s/WEB_PORT_PLACEHOLDER/8082/g" README.md
    perl -i -pe "s/PMA_PORT_PLACEHOLDER/8083/g" README.md
    perl -i -pe "s/DB_PORT_PLACEHOLDER/3306/g" README.md
    perl -i -pe "s/MYSQL_DATABASE_PLACEHOLDER/$MYSQL_DATABASE/g" README.md
    perl -i -pe "s/MYSQL_USER_PLACEHOLDER/$MYSQL_USER/g" README.md
else
    # Fallback: Erstelle README neu mit korrekten Werten
    cat > README.md << EOF
# Redaxo Docker Entwicklungsumgebung

Projektname: $PROJECT_NAME

## Quick Start

\`\`\`bash
# Container starten
./start.sh

# Container stoppen
./stop.sh

# Status anzeigen
./status.sh
\`\`\`

## Zugriff

- **Redaxo**: http://localhost:8082
- **phpMyAdmin**: http://localhost:8083
- **MariaDB**: localhost:3306

## Datenbank-Zugangsdaten

- Host: \`db\`
- Datenbank: \`$MYSQL_DATABASE\`
- Benutzer: \`$MYSQL_USER\`
- Passwort: Siehe .env Datei

## Weitere Informationen

Siehe die ausführliche README.md im Hauptverzeichnis.
EOF
fi

# Alle Skripte ausführbar machen
chmod +x *.sh

# Abschlussmeldung
echo
print_info "✅ Projekt '$PROJECT_NAME' wurde erfolgreich erstellt!"
echo
print_info "Nächste Schritte:"
echo "  1. cd $PROJECT_NAME"
echo "  2. ./start.sh"
echo "  3. Öffne http://localhost:8082 für Redaxo"
echo "  4. Öffne http://localhost:8083 für phpMyAdmin"
echo
print_info "Weitere Befehle:"
echo "  ./stop.sh    - Container stoppen"
echo "  ./status.sh  - Status anzeigen"
echo "  ./logs.sh    - Logs anzeigen"
echo "  ./shell.sh   - In Container-Shell"
echo "  ./cleanup.sh - Alles löschen"
echo "  ./debug.sh   - Debug-Informationen"