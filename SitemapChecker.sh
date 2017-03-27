#!/bin/bash

# clear screen to see exciting stuff happen
clear

# Save arguments of command line to variables
label=$1
url=$2
maxNumURLs=$3

# label your testrun
if [ -z $1 ]; then
    read -p "Type a name for your testrun: " label

fi

# check if seccessary tools are installed
# if not install them (made it work on debian based distros and fedora)
which xmllint curl wget sort sed grep > /dev/null 2>&1
if [ $? -ne 0 ]; then
    distribution=$(lsb_release -is)

    if [ $? -ne 0 ]; then
        echo "Cant't identify your Linux Distribution because lsb_release is not installed"
        read -p "Press any key to exit ... " -n 1
        exit 1
    fi

    case $distribution in
        Debian | LinuxMint | Ubuntu )
            sudo apt-get update; sudo apt-get install curl libxml2-utils wget coreutils sed grep
            ;;
        Fedora )
            sudo dnf install curl libxml2 wget coreutils sed grep
            ;;
        * )
            echo "Your Linux Distribution is not yet supported"
            echo "Please manually install the following tools: curl wget sed grep coreutils"
            read -p "Press any key to exit ... " -n 1
            exit 1
            ;;
    esac
fi


# if argument 1 is empty ask for input
if [ -z $2 ]; then
    read -p "Type the URL you want to check: " url
    clear
fi

# clean remainings of previous run
rm -rf ~/SitemapCheck_$label/* 2> /dev/null

# create a folder for the files we need to check
mkdir ~/SitemapCheck_$label 2> /dev/null
# go into the directory we want to work with
cd ~/SitemapCheck_$label

# download the sitemap.xml. In case of an error exit the script
wget $url -O sitemap.tmp
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

# clear output
clear

# show and save timestamp to report
date | tee ~/SitemapCheck_Report_$label.txt

# check if there was a second argument for maxNumURLs
if [ -z $3 ]; then
    # print how many unique links were found
    echo
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
echo -e "\nTest\tResponse\tURL" | tee -a ~/SitemapCheck_Report_$label.txt

# loop through all links in the file and test them
for link in $(cat sitemap_links_part.txt); do
    {
        echo -en "$counter/$linksCheck\t"
        code=$(curl -L --max-time 10 --connect-timeout 5 --silent --head -o /dev/null -w "%{http_code}" $link)
        echo -n $code
        #if [ $? -ne 200 ]; then
        #    errors=$[$errors +1]
        #fi
        echo -e "\t\t$link"
    } | tee -a ~/SitemapCheck_Report_$label.txt
    counter=$[$counter +1]
done

# sort the report file by status code
sort -k2 -n -s ~/SitemapCheck_Report_$label.txt > ~/SitemapCheck_Report_$label.tmp; mv ~/SitemapCheck_Report_$label.tmp ~/SitemapCheck_Report_$label.txt

# print overview
echo | tee -a ~/SitemapCheck_Report_$label.txt
echo -e "Sitemap Files:\t$sitemaps" | tee -a ~/SitemapCheck_Report_$label.txt
echo -e "Links Total:\t$linksTotal" | tee -a ~/SitemapCheck_Report_$label.txt
echo -e "Links Unique:\t$linksUnique" | tee -a ~/SitemapCheck_Report_$label.txt
echo -e "Links Checked:\t$linksCheck" | tee -a ~/SitemapCheck_Report_$label.txt
#echo -e "Errors:\t\t$errors" | tee -a ~/SitemapCheck_Report_$label.txt
echo -e "Duration:\t$(echo $SECONDS)s" | tee -a ~/SitemapCheck_Report_$label.txt
echo | tee -a ~/SitemapCheck_Report_$label.txt
echo | tee -a ~/SitemapCheck_Report_$label.txt
read -p "Done! Press any key to exit ... " -n 1
clear
