# Redaxo Docker Entwicklungsumgebung

Diese Entwicklungsumgebung ermöglicht es, 
mehrere unabhängige Redaxo-Instanzen auf einem System zu betreiben.

## ⚠️ BETA-Status

**Achte darauf, dass das Setup noch BETA-Status hat!**
- Probiere es aus und gib mir Feedback wenn du Fehler findest
- Das Setup ist für Redaxo 5.19.0 optimiert
- Nur für macOS mit M1-Serie getestet

## Voraussetzungen

- macOS mit M1 Chip (M1/M2/M3)
- Docker Desktop installiert und gestartet
- Terminal/Bash
- Internetverbindung für den Redaxo-Download

## Verwendung

### Setup-Skript ausführbar machen
```bash
chmod +x setup.sh
```

### Projekt erstellen
```bash
./setup.sh mein-projekt
```

### In Projektverzeichnis wechseln
```bash
cd ../mein-projekt
```

### Container starten
```bash
./start.sh
```

Nach dem Start sind folgende Services verfügbar:
- **Redaxo**: http://localhost:8082
- **phpMyAdmin**: http://localhost:8083
- **MariaDB**: localhost:3306

## Projektstruktur

Nach der Installation wird folgende Struktur **im übergeordneten Verzeichnis** erstellt:

```
../mein-projekt/            # Projekt wird eine Ebene höher erstellt
├── docker-compose.yml      # Docker Compose Konfiguration
├── .env                    # Umgebungsvariablen
├── apache-php/
│   ├── Dockerfile         # PHP/Apache Image Definition
│   └── apache.conf        # Apache Konfiguration
├── www/
│   └── dev/
│       └── dist/          # Redaxo Installation
├── redaxo-5.19.0.zip      # Original Redaxo ZIP
├── start.sh               # Container starten
├── stop.sh                # Container stoppen
├── status.sh              # Status anzeigen
├── logs.sh                # Logs anzeigen
├── shell.sh               # Container-Shell öffnen
├── cleanup.sh             # Projekt bereinigen
├── update.sh              # Update-Funktionen
└── debug.sh               # Debug-Informationen
```

**Hinweis:** Das Setup-Skript wechselt automatisch in den übergeordneten Ordner, um dort das Projekt anzulegen.

## Weitere Befehle

### Container verwalten
```bash
./stop.sh     # Container stoppen
./status.sh   # Status anzeigen
./logs.sh     # Logs anzeigen
./shell.sh    # Container-Shell öffnen
./cleanup.sh  # Projekt komplett löschen
```

### Logs anzeigen
```bash
# Logs eines spezifischen Containers
./logs.sh web       # Apache/PHP Logs
./logs.sh db        # Datenbank Logs
./logs.sh phpmyadmin

# Alle Logs
./logs.sh all
```

**Warnung:** `cleanup.sh` löscht alle Container, Volumes und Daten!

## Konfiguration

### Umgebungsvariablen (.env)

Die `.env`-Datei enthält alle projektspezifischen Einstellungen:

```env
PROJECT_NAME=mein-projekt
WEB_PORT=8082
DB_PORT=3306
PMA_PORT=8083
MYSQL_ROOT_PASSWORD=rootpass
MYSQL_DATABASE=redaxo_db
MYSQL_USER=redaxo_user
MYSQL_PASSWORD=redaxo_pass
```

### Ports ändern

Falls die Standard-Ports bereits belegt sind, können diese in der `.env`-Datei angepasst werden:

```bash
# .env bearbeiten
nano .env

# Container neu starten
./stop.sh
./start.sh
```

## Redaxo Installation

1. Browser öffnen: http://localhost:8082
2. Redaxo Setup-Wizard folgen
3. Datenbank-Verbindung:
    - **Server**: `db` (nicht localhost!)
    - **Datenbank**: `redaxo_db`
    - **Benutzer**: `redaxo_user`
    - **Passwort**: `redaxo_pass`

## Mehrere Projekte parallel

Dank der projektspezifischen Konfiguration können mehrere Instanzen parallel betrieben werden:

```bash
# Projekt 1
./setup.sh projekt1
cd projekt1
# .env anpassen: WEB_PORT=8082, DB_PORT=3306, PMA_PORT=8083
./start.sh

# Projekt 2
./setup.sh projekt2
cd projekt2
# .env anpassen: WEB_PORT=8092, DB_PORT=3307, PMA_PORT=8093
./start.sh
```

## Troubleshooting

### Port bereits belegt
```bash
# Prüfen welcher Prozess den Port belegt
lsof -i :8082

# Alternative: Ports in .env ändern
```

### Container startet nicht
```bash
# Logs prüfen
./logs.sh web

# Container neu bauen
docker-compose build --no-cache
```

### Berechtigungsprobleme
```bash
# In Container-Shell
./shell.sh

# Berechtigungen korrigieren
chown -R www-data:www-data /var/www/html
```

### Datenbank-Verbindung schlägt fehl
- Verwenden Sie `db` als Hostname, nicht `localhost`
- Prüfen Sie die Zugangsdaten in der `.env`-Datei
- Warten Sie nach dem Start ca. 10 Sekunden bis die DB bereit ist

## Sicherheitshinweise

⚠️ **BETA-Version - Nur für Entwicklungsumgebungen!**

- Die Standard-Passwörter sind öffentlich bekannt
- Nicht für Produktivumgebungen geeignet
- Regelmäßige Backups werden empfohlen
- Getestet nur auf macOS mit Apple Silicon (M1/M2/M3)

Aus Sicherheitsgründen sind folgende Verzeichnisse gesperrt:
- `/bin`, `/cache`, `/data`, `/src`

## Backup & Restore

### Datenbank-Backup
```bash
# Backup erstellen
docker exec mein-projekt_mariadb mysqldump -u root -prootpass redaxo_db > backup.sql

# Backup einspielen
docker exec -i mein-projekt_mariadb mysql -u root -prootpass redaxo_db < backup.sql
```

### Komplettes Projekt-Backup
```bash
# Container stoppen
./stop.sh

# Projekt-Ordner sichern
tar -czf mein-projekt-backup.tar.gz ../mein-projekt

# Wiederherstellen
tar -xzf mein-projekt-backup.tar.gz
```

## Wartung

### Docker Images aktualisieren
```bash
docker-compose pull
docker-compose build --no-cache
```

### Aufräumen ungenutzter Docker-Ressourcen
```bash
# Vorsicht: Betrifft alle Docker-Projekte!
docker system prune -a
```

## Support & Feedback

Da sich das Projekt noch im **BETA-Status** befindet, freue ich mich über:
- Bug-Reports und Fehlermeldungen
- Verbesserungsvorschläge
- Erfahrungsberichte
- Pull Requests

**GitHub Issues:** https://github.com/HalloWelt42/redaxo_new_workaround/issues

Bei Problemen:
1. Logs prüfen (`./logs.sh all`)
2. Debug-Informationen sammeln (`./debug.sh`)
3. Docker Desktop neu starten
4. Issue auf GitHub erstellen mit den Debug-Informationen