# SitemapChecker

## Abhängigkeiten
- libxml2 (xmllint)
- curl
- sed
- grep
- coreutils

Wird eine auf Debian basierte Distribution oder Fedora eingesetzt, können die fehlenden Tools auf Wunsch automatisch installiert werden (bei Bedarf kann das ebenfalls fuer andere Distributionnen erweitert werden).

1. Script ausführbar machen
    - per Shell in den Ordner des Scripts wechseln bspw. cd ~/Downloads
    - Script ausführbar machen mittels chmod +x sitemapChecker.sh

- Script starten
    - ./sitemapChecker.sh oder bash /sitemapChecker.sh
    - zu testende Seite muss als erster (und einziger) Parameter an das Script übergeben werden bspw. ./sitemapChecker.sh heise.de


Das Script läd alle Sitemaps herunter und testet alle hinterlegten Links. Das Ergebnis liegt anschliessend in ~/results.html.
