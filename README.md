# Ruckus-Unleshed-Benutzeraufzeichnung
Script für die Aufzeichnung und Auswertung von Benutzer in einem Ruckus Unleashed System

# Funktionen
- Analyse der Syslog-Informationen.
- Optische Aufbereitung der Daten.
- Ausgabe in einer CSV-Datei
- Ausgabe in SQL-Datenbank
- Web-Übersicht
 
# Offene Punkte
 - [ ] SQL Hinzufügen
 - [ ] Web-Übersicht CSV
 - [ ] Web-Übersicht SQL

# Einrichtung
## Remote-Syslog bei Unleshed
Um dem Remote-Syslog-Dienst bei einem Ruckus Unleashed-System zu aktivieren ist folgendes Vorgehen notwendig:
* SSH-Verbindung zum Master herstellen.
* Einloggen mit dem Administrator-Konto
* Mit dem Befehl `enable` in den erweiterten Modus wechsel.
* Nun in den Konfigurations-Modus mit `config` wechseln.
* Jetzt in den Bereich des Syslog mit `syslog` wechseln.
* Nun den Syslog-Server mit `server 192.168.1.10` eintragen.
* Mit dem Befehl `priority info` das Syslog-Level auswählen.
* Nun mittels `exit` den Vorgang beenden und speichern.

# Ablauf Diagram
![Hauptablaufdiagramm](/img/Funktionsdiagramm.png)

