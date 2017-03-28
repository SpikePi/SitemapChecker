# SitemapChecker

Linux bash script to test if the linked sites of a sitemap are available. The script also recognizes sitemaps that are split across several files. After execution you can find a report stored in `~/SitemapCheck_${Label}/Report.txt`.

## Dependencies

- libxml2 (xmllint)
- curl
- sed
- grep
- coreutils

If you use a Debian based distribution or Feadora the script will install all needed dependencies if you allow to (on request I may add more distributions).

1. Making the script executable
    - via terminal change directory to where you downloaded the script, e. g. `cd ~/Downloads`
    - make the script executable by running `chmod +x sitemapChecker.sh`
2. Starting the script
    - `./sitemapChecker.sh` or `bash /sitemapChecker.sh`

While executing the script you can append up to 3 parameters (take notice of truth table below) with the following meaning `./SitemapChecker.sh [Label] [URL] [MaxLinksToCheck]` i. e. `./SitemapChecker.sh heise heise.de/sitemap.xml 500`.

1. Label: Only affects the folder name where your report is stored
2. URL: Address to the sitemap you want to check
3. MaxLinksToCheck: How many links should be tested max.

If executed without the parameters the script will ask for input during execution.

## Truth table for script parameters

|Label|URL|MaxLinksToCheck|Working?|
|:---:|:-:|:-------------:|:------:|
|✖    |✖  |✖              |✔       |
|✔    |✔  |✔              |✔       |
|✔    |✔  |✖              |✔       |
|✔    |✖  |✖              |✔       |
|✖    |✔  |✔              |✖       |
|✖    |✔  |✖              |✖       |
|✖    |✖  |✔              |✖       |
