#!/bin/bash

# clear screen to see exciting stuff happen
clear

# Save arguments of command line to variables
sitemap=$1
maxNumURLs=$2

# check if seccessary tools are installed
# if not install them (made it work on debian based distros and fedora)
which xmllint curl wget sort sed grep > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo -e "To run this Script you need to install the following tools:\n curl sed grep coreutils"
    echo
    read -n 1 -p "Press any key to continue... "
    #   test if distribution is fedora
    which dnf > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        sudo dnf install curl libxml2 wget coreutils sed grep
    fi

    #   test if distribution is debian-based
    which apt-get > /dev/null 2>&1

    if [ $? -eq 0 ]; then
        sudo apt-get update; sudo apt-get install curl libxml2-utils wget coreutils sed grep
    fi

    #   feedback, that other distros are (currently) not supported
    which dnf || which apt-get > /dev/null 2>&1
    if [ $? -ne 0 ]; then
        echo -e "Your distribution is not supported, so you have to install the seccessary tools manually"
    fi
fi
clear


# if argument 1 is empty ask for input
if [ -z $1 ]; then
    read -p "Type the URL you want to check: " sitemap
    clear
fi

# clean remainings of previous run
rm ~/sitemapChecker/*  2> /dev/null
# create a folder for the files we need to check
mkdir ~/sitemapChecker 2> /dev/null
# go into the directory we want to work with
cd ~/sitemapChecker

# download the sitemap.xml. In case of an error exit the script
wget $sitemap/sitemap.xml -O sitemap.tmp
if [ $? -ne 0 ]; then
    clear
    echo "No sitemap found!"
    echo
    exit 1
fi

# beautify it to make it better grep-able
xmllint --format sitemap.tmp > sitemap.xml

# look if there are other sitemaps linked
grep "\.xml" sitemap.xml > /dev/null

# if sitemap is split into pieces get all parts of it
if [ $? -eq 0 ]; then
    # save all found sitemap addresses in new file
    egrep -o "<loc>.*\.xml.*</loc>" sitemap.xml > sitemaps.tmp

    # remove surrounding loc-tag
    sed -i 's/<[\/]*loc>//g' sitemaps.tmp

    # get all found sitemaps
    wget $(cat sitemaps.tmp)

    # beatify all sitemaps
    find . -name "*.xml" -type f -exec xmllint --output '{}' --format '{}' \;
fi

# save how many sitemap-files were found
sitemaps=$(ls *.xml 2> /dev/null | wc -l)

# clear output
clear

# filter all downloaded sitemaps for URLs and put them in one file
egrep -v "\.xml" *.xml* | egrep -o "<loc>.*</loc>" > sitemap_links_all.tmp

# remove surrounding loc-tag
sed -i 's/<[\/]*loc>//g' sitemap_links_all.tmp

# save how many links were found
linksTotal=$(wc -l < sitemap_links_all.tmp)

# sort all links to remove duplicats
sort -u sitemap_links_all.tmp > sitemap_links_all.txt
linksUnique=$(wc -l < sitemap_links_all.txt)

# shuffle links to get a random set of links from every part of the site
shuf sitemap_links_all.txt > sitemap_links_all.tmp

# show and save timestamp to report
date | tee report.txt

# check if there was a second argument for maxNumURLs
if [ -z $2 ]; then
    # print how many unique links were found
    echo -e "Found $linksUnique unique links."

    # ask how many of the links should be checked
    read -p "How many links should be checked? " maxNumURLs
else
    echo "Testinging $maxNumURLs Links out of $linksUnique."
fi

# take first ${argument2} links that should be tested and sort them again
# so that they are tested in alphabetic order to get a better output
head -n $maxNumURLs sitemap_links_all.tmp | sort > sitemap_links_part.txt

# clean xml- and temp-files
rm *.tmp
rm *.xml

# set some variables to get a nice output
counter=1
errors=0
SECONDS=0
linksCheck=$(wc -l < sitemap_links_part.txt)

# create the header of the Report
echo -e "\nTest\tResponse\tURL" | tee -a report.txt

# loop through all links in the file and test them
for url in $(cat sitemap_links_part.txt); do
    {
        echo -en "$counter/$linksCheck\t"
        curl -L --silent --head -o /dev/null -w "%{http_code}" $url
        if [ $? -ne 0 ]; then
            errors=$[$errors +1]
        fi
        echo -e "\t$url"
    } | tee -a report.txt
    counter=$[$counter +1]
done

# sort the report file by status code
sort -k2 -n -s report.txt > report.tmp; mv report.tmp report.txt

# print overview
echo
echo -e "Sitemap Files:\t$sitemaps" | tee -a report.txt
echo -e "Links Total:\t$linksTotal" | tee -a report.txt
echo -e "Links Unique:\t$linksUnique" | tee -a report.txt
echo -e "Links Checked:\t$linksCheck" | tee -a report.txt
echo -e "Errors:\t\t$errors" | tee -a report.txt
echo -e "Duration:\t$(echo $SECONDS)s" | tee -a report.txt
echo
echo "Done!"
read -p "Press any key to exit ... " -n 1
clear