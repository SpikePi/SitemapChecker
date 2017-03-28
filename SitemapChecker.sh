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
date | tee Report.txt

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
anomalies=0
SECONDS=0
linksCheck=$(wc -l < sitemap_links_part.txt)

# create the header of the Report
echo -e "\nTest\tResponse\tURL" | tee -a Report.txt

# loop through all links in the file and test them
for link in $(cat sitemap_links_part.txt); do
    echo -en "$counter/$linksCheck\t" | tee -a Report.txt
    code=$(curl -L --max-time 10 --connect-timeout 5 --silent --head -o /dev/null -w "%{http_code}" $link)
    echo -n $code | tee -a Report.txt
    if [ $code -gt 200 ]; then
        anomalies=$[$anomalies +1]
        echo -n " *"
    fi
    case $code in
            100 ) Continue="true" ;;
            101 ) SwitchingProtocol="true" ;;
            200 ) OK="true" ;;
            201 ) Created="true" ;;
            202 ) Accepted="true" ;;
            203 ) Non-AuthoritativeInformation="true" ;;
            204 ) NoContent="true" ;;
            205 ) ResetContent="true" ;;
            206 ) PartialContent="true" ;;
            300 ) MultipleChoices="true" ;;
            301 ) MovedPermanently="true" ;;
            302 ) Found="true" ;;
            303 ) SeeOther="true" ;;
            304 ) NotModified="true" ;;
            307 ) TemporaryRedirect="true" ;;
            308 ) PermanentRedirect="true" ;;
            400 ) BadRequest="true" ;;
            401 ) Unauthorized="true" ;;
            403 ) Forbidden="true" ;;
            404 ) NotFound="true" ;;
            405 ) MethodNotAllowed="true" ;;
            406 ) NotAcceptable="true" ;;
            407 ) ProxyAuthenticationRequired="true" ;;
            408 ) RequestTimeout="true" ;;
            409 ) Conflict="true" ;;
            410 ) Gone="true" ;;
            411 ) LengthRequired="true" ;;
            412 ) PreconditionFailed="true" ;;
            413 ) PayloadTooLarge="true" ;;
            414 ) URITooLong="true" ;;
            415 ) UnsupportedMediaType="true" ;;
            416 ) RangeNotSatisfiable="true" ;;
            417 ) ExpectationFailed="true" ;;
            426 ) UpgradeRequired="true" ;;
            428 ) PreconditionRequired="true" ;;
            429 ) TooManyRequests="true" ;;
            431 ) RequestHeaderFieldsTooLarge="true" ;;
            451 ) UnavailableForLegalReasons="true" ;;
            500 ) InternalServerError="true" ;;
            501 ) NotImplemented="true" ;;
            502 ) BadGateway="true" ;;
            503 ) ServiceUnavailable="true" ;;
            504 ) GatewayTimeout="true" ;;
            505 ) HTTPVersionNotSupported="true" ;;
            511 ) NetworkAuthenticationRequired="true" ;;
            * ) ;;
    esac
    echo -e "\t\t$link" | tee -a Report.txt
    counter=$[$counter +1]
done

# sort the report file by status code
sort -k2 -n -s Report.txt > Report.tmp; mv Report.tmp Report.txt

# print found anamolies and their meanings
{
        echo
        echo
        echo "Meaning of HTTP status codes" | tee -a Report.txt
        if [ -n "$Continue" ];then echo "100: Continue" | tee -a Report.txt; fi
        if [ -n "$SwitchingProtocol" ];then echo "101: SwitchingProtocol" | tee -a Report.txt; fi
        if [ -n "$OK" ];then echo "200: OK" | tee -a Report.txt; fi
        if [ -n "$Created" ];then echo "201: Created" | tee -a Report.txt; fi
        if [ -n "$Accepted" ];then echo "202: Accepted" | tee -a Report.txt; fi
        if [ -n "$AuthoritativeInformation" ];then echo "203: Non-AuthoritativeInformation" | tee -a Report.txt; fi
        if [ -n "$NoContent" ];then echo "204: NoContent" | tee -a Report.txt; fi
        if [ -n "$ResetContent" ];then echo "205: ResetContent" | tee -a Report.txt; fi
        if [ -n "$PartialContent" ];then echo "206: PartialContent" | tee -a Report.txt; fi
        if [ -n "$MultipleChoices" ];then echo "300: MultipleChoices" | tee -a Report.txt; fi
        if [ -n "$MovedPermanently" ];then echo "301: MovedPermanently" | tee -a Report.txt; fi
        if [ -n "$Found" ];then echo "302: Found" | tee -a Report.txt; fi
        if [ -n "$SeeOther" ];then echo "303: SeeOther" | tee -a Report.txt; fi
        if [ -n "$NotModieq" ];then echo "304: NotModi; fied" | tee -a Report.txt; fi
        if [ -n "$TemporaryRedirect" ];then echo "307: TemporaryRedirect" | tee -a Report.txt; fi
        if [ -n "$PermanentRedirect" ];then echo "308: PermanentRedirect" | tee -a Report.txt; fi
        if [ -n "$BadRequest" ];then echo "400: BadRequest" | tee -a Report.txt; fi
        if [ -n "$Unauthorized" ];then echo "401: Unauthorized" | tee -a Report.txt; fi
        if [ -n "$Forbidden" ];then echo "403: Forbidden" | tee -a Report.txt; fi
        if [ -n "$NotFound" ];then echo "404: NotFound" | tee -a Report.txt; fi
        if [ -n "$MethodNotAllowed" ];then echo "405: MethodNotAllowed" | tee -a Report.txt; fi
        if [ -n "$NotAcceptable" ];then echo "406: NotAcceptable" | tee -a Report.txt; fi
        if [ -n "$ProxyAuthenticationRequired" ];then echo "407: ProxyAuthenticationRequired" | tee -a Report.txt; fi
        if [ -n "$RequestTimeout" ];then echo "408: RequestTimeout" | tee -a Report.txt; fi
        if [ -n "$Conflict" ];then echo "409: Conflict" | tee -a Report.txt; fi
        if [ -n "$Gone" ];then echo "410: Gone" | tee -a Report.txt; fi
        if [ -n "$LengthRequired" ];then echo "411: LengthRequired" | tee -a Report.txt; fi
        if [ -n "$PreconditionFailed" ];then echo "412: PreconditionFailed" | tee -a Report.txt; fi
        if [ -n "$PayloadTooLarge" ];then echo "413: PayloadTooLarge" | tee -a Report.txt; fi
        if [ -n "$URITooLong" ];then echo "414: URITooLong" | tee -a Report.txt; fi
        if [ -n "$UnsupportedMediaType" ];then echo "415: UnsupportedMediaType" | tee -a Report.txt; fi
        if [ -n "$RangeNotSatis" ];then echo "416: RangeNotSatis; fiable" | tee -a Report.txt; fi
        if [ -n "$ExpectationFailed" ];then echo "417: ExpectationFailed" | tee -a Report.txt; fi
        if [ -n "$UpgradeRequired" ];then echo "426: UpgradeRequired" | tee -a Report.txt; fi
        if [ -n "$PreconditionRequired" ];then echo "428: PreconditionRequired" | tee -a Report.txt; fi
        if [ -n "$TooManyRequests" ];then echo "429: TooManyRequests" | tee -a Report.txt; fi
        if [ -n "$RequestHeaderTooLarge" ];then echo "431: RequestHeader; fieldsTooLarge" | tee -a Report.txt; fi
        if [ -n "$UnavailableForLegalReasons" ];then echo "451: UnavailableForLegalReasons" | tee -a Report.txt; fi
        if [ -n "$InternalServerError" ];then echo "500: InternalServerError" | tee -a Report.txt; fi
        if [ -n "$NotImplemented" ];then echo "501: NotImplemented" | tee -a Report.txt; fi
        if [ -n "$BadGateway" ];then echo "502: BadGateway" | tee -a Report.txt; fi
        if [ -n "$ServiceUnavailable" ];then echo "503: ServiceUnavailable" | tee -a Report.txt; fi
        if [ -n "$GatewayTimeout" ];then echo "504: GatewayTimeout" | tee -a Report.txt; fi
        if [ -n "$HTTPVersionNotSupported" ];then echo "505: HTTPVersionNotSupported" | tee -a Report.txt; fi
        if [ -n "$NetworkAuthenticationRequired" ];then echo "511: Network Authentication Required" | tee -a Report.txt; fi
}

# print overview
echo | tee -a Report.txt
echo -e "Sitemap Files:\t$sitemaps" | tee -a Report.txt
echo -e "Links Total:\t$linksTotal" | tee -a Report.txt
echo -e "Links Unique:\t$linksUnique" | tee -a Report.txt
echo -e "Links Checked:\t$linksCheck" | tee -a Report.txt
echo -e "Anomlies:\t$anomalies" | tee -a Report.txt
echo -e "Duration:\t$(echo $SECONDS)s" | tee -a Report.txt
echo | tee -a Report.txt
echo | tee -a Report.txt
read -p "Done! Press any key to exit ... " -n 1
clear
