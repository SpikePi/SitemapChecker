#!/bin/bash

# clear screen to see exciting stuff happen
clear

# Save arguments of command line to variables
LABEL=$1
URL=$2
MAXNUMURLS=$3

# label your testrun
if [[ -z $1 ]]; then
        read -p "Type a name for your testrun: " LABEL
fi

# check if seccessary tools are installed
# if not install them (made it work on debian based distros and fedora)
which xmllint curl wget sort sed grep > /dev/null 2>&1
if [[ $? -ne 0 ]]; then
        DISTRIBUTION=$(lsb_release -is)

        if [ $? -ne 0 ]; then
                echo "Cant't identify your Linux Distribution because lsb_release is not installed."
                read -p "Press any key to exit ... " -n 1
                exit 1
        fi

        case ${DISTRIBUTION}} in
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
if [[ -z ${URL} ]]; then
        echo "If you don't know where the sitemap is, look for it at the robots.txt"
        read -p "Type the URL you want to check: " URL
        clear
fi

# clean remainings of previous run
rm ~/SitemapCheck_${LABEL}/* 2> /dev/null

# create a folder for the files we need to check
mkdir ~/SitemapCheck_${LABEL} 2> /dev/null
# go into the directory we want to work with
cd ~/SitemapCheck_${LABEL}

# download the sitemap.xml. In case of an error exit the script
wget ${URL} -O sitemap.tmp
if [[ -z $? ]]; then
        clear
        echo "No sitemap found!"
        echo
        exit 1
fi
# beautify it to make it better grep-able
xmllint --format sitemap.tmp > sitemap.xml

# look if there are other sitemaps linked
# if sitemap is split into pieces get all parts of it
if grep "\.xml" sitemap.xml; then
        # save all found sitemap addresses in new file
        grep -Eo "<loc>.*\.xml.*</loc>" sitemap.xml > sitemaps.tmp

        # remove surrounding loc-tag
        sed -i 's/<[\/]*loc>//g' sitemaps.tmp

        # get all found sitemaps
        wget $(cat sitemaps.tmp)

        # beatify all sitemaps
        find . -name "*.xml" -type f -exec xmllint --output '{}' --format '{}' \;
fi

# save how many sitemap-files were found
SITEMAPS=$(ls *.xml* 2> /dev/null | wc -l)

# filter all downloaded sitemaps for URLs and put them in one file
grep -Eho "(http[s]*:\/\/www\.)([a-zA-Z0-9_-]{4,}\.)([a-zA-Z]{2,3})([a-zA-Z0-9\/_\.\?-])+" *.xml > sitemap_links_all.tmp
#grep -v "\.xml" *.xml* | grep -Eo "<loc>.*</loc>" > sitemap_links_all.tmp

# remove surrounding loc-tag
#sed -i 's/<[\/]*loc>//g' sitemap_links_all.tmp

# save how many links were found
LINKSTOTAL=$(wc -l < sitemap_links_all.tmp)

# sort all links to remove duplicats
sort -u sitemap_links_all.tmp > sitemap_links_all.txt
LINKSUNIQUE=$(wc -l < sitemap_links_all.txt)

# shuffle links to get a random set of links from every part of the site
shuf sitemap_links_all.txt > sitemap_links_all.tmp

# clear output
clear

# show and save timestamp to report
date | tee Report.txt

# check if there was a second argument for maxNumURLs
if [[ -z $3 ]]; then
        # print how many unique links were found
        echo
        echo -e "Found ${LINKSUNIQUE} unique links.\n"

        # ask how many of the links should be checked
        read -p "How many links should be checked? (Press ENTER to check all) " MAXNUMURLS
else
        echo "Testinging ${MAXNUMURLS} Links out of ${LINKSUNIQUE}."
fi
if [[ -z ${MAXNUMURLS} ]]; then maxNumURLs=999999; fi

# take first ${argument2} links that should be tested and sort them again
# so that they are tested in alphabetic order to get a better output
head -n ${MAXNUMURLS} sitemap_links_all.tmp | sort > sitemap_links_part.txt

# clean xml- and temp-files
rm *.tmp
rm *.xml

# set some variables to get a nice output
COUNTER=0
ANOMALIES=0
SECONDS=0
LINKSTOCHECK=$(wc -l < sitemap_links_part.txt)

# create the header of the Report
echo -e "\nTest\tResponse\tURL" | tee -a Report.txt

# loop through all links in the file and test them
for LINK in $(cat sitemap_links_part.txt); do
        COUNTER=$(( ${COUNTER} + 1 ))
        echo -en "${COUNTER}/${LINKSTOCHECK}\t" | tee -a Report.txt
        CODE=$(curl --user-agent "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/57.0.2987.110 Safari/537.36" -L --max-time 10 --connect-timeout 5 --silent --head -o /dev/null --write-out "%{http_code}" ${LINK})
        echo -n ${CODE} | tee -a Report.txt
        if [ ${CODE} -ne 200 ]; then
                ANOMALIES=$(( ${ANOMALIES} + 1 ))
                echo -n " *"
        fi
        case ${CODE} in
                000 ) CURL="true" ;;
                100 ) CONTINUE="true" ;;
                101 ) SWITCHINGPROTOCOL="true" ;;
                200 ) OK="true" ;;
                201 ) CREATED="true" ;;
                202 ) ACCEPTED="true" ;;
                203 ) NON-AuthoritativeInformation="true" ;;
                204 ) NOCONTENT="true" ;;
                205 ) RESETCONTENT="true" ;;
                206 ) PARTIALCONTENT="true" ;;
                300 ) MULTIPLECHOICES="true" ;;
                301 ) MOVEDPERMANENTLY="true" ;;
                302 ) FOUND="true" ;;
                303 ) SEEOTHER="true" ;;
                304 ) NOTMODIFIED="true" ;;
                307 ) TEMPORARYREDIRECT="true" ;;
                308 ) PERMANENTREDIRECT="true" ;;
                400 ) BADREQUEST="true" ;;
                401 ) UNAUTHORIZED="true" ;;
                403 ) FORBIDDEN="true" ;;
                404 ) NOTFOUND="true" ;;
                405 ) METHODNOTALLOWED="true" ;;
                406 ) NOTACCEPTABLE="true" ;;
                407 ) PROXYAUTHENTICATIONREQUIRED="true" ;;
                408 ) REQUESTTIMEOUT="true" ;;
                409 ) CONFLICT="true" ;;
                410 ) GONE="true" ;;
                411 ) LENGTHREQUIRED="true" ;;
                412 ) PRECONDITIONFAILED="true" ;;
                413 ) PAYLOADTOOLARGE="true" ;;
                414 ) URITOOLONG="true" ;;
                415 ) UNSUPPORTEDMEDIATYPE="true" ;;
                416 ) RANGENOTSATISFIABLE="true" ;;
                417 ) EXPECTATIONFAILED="true" ;;
                426 ) UPGRADEREQUIRED="true" ;;
                428 ) PRECONDITIONREQUIRED="true" ;;
                429 ) TOOMANYREQUESTS="true" ;;
                431 ) REQUESTHEADERFIELDSTOOLARGE="true" ;;
                451 ) UNAVAILABLEFORLEGALREASONS="true" ;;
                500 ) INTERNALSERVERERROR="true" ;;
                501 ) NOTIMPLEMENTED="true" ;;
                502 ) BADGATEWAY="true" ;;
                503 ) SERVICEUNAVAILABLE="true" ;;
                504 ) GATEWAYTIMEOUT="true" ;;
                505 ) HTTPVERSIONNOTSUPPORTED="true" ;;
                511 ) NETWORKAUTHENTICATIONREQUIRED="true" ;;
                * ) UNKNOWN="true" ;;
        esac
        echo -e "\t\t${LINK}" | tee -a Report.txt
done

# sort the report file by status code
sort -k2 -n -s Report.txt > Report.tmp; mv Report.tmp Report.txt

# print found status codes and their meanings
echo -e "\n\nMeaning of HTTP status codes" | tee -a Report.txt
if [[ -n "$CURL" ]];then echo "000: cURL did not receive a HTTP response code" | tee -a Report.txt; fi
if [[ -n "$CONTINUE" ]];then echo "100: Continue" | tee -a Report.txt; fi
if [[ -n "$SWITCHINGPROTOCOL" ]];then echo "101: SwitchingProtocol" | tee -a Report.txt; fi
if [[ -n "$OK" ]];then echo "200: OK" | tee -a Report.txt; fi
if [[ -n "$CREATED" ]];then echo "201: Created" | tee -a Report.txt; fi
if [[ -n "$ACCEPTED" ]];then echo "202: Accepted" | tee -a Report.txt; fi
if [[ -n "$AUTHORITATIVEINFORMATION" ]];then echo "203: Non-AuthoritativeInformation" | tee -a Report.txt; fi
if [[ -n "$NOCONTENT" ]];then echo "204: NoContent" | tee -a Report.txt; fi
if [[ -n "$RESETCONTENT" ]];then echo "205: ResetContent" | tee -a Report.txt; fi
if [[ -n "$PARTIALCONTENT" ]];then echo "206: PartialContent" | tee -a Report.txt; fi
if [[ -n "$MULTIPLECHOICES" ]];then echo "300: MultipleChoices" | tee -a Report.txt; fi
if [[ -n "$MOVEDPERMANENTLY" ]];then echo "301: MovedPermanently" | tee -a Report.txt; fi
if [[ -n "$FOUND" ]];then echo "302: Found" | tee -a Report.txt; fi
if [[ -n "$SEEOTHER" ]];then echo "303: SeeOther" | tee -a Report.txt; fi
if [[ -n "$NOTMODIEQ" ]];then echo "304: NotModi; fied" | tee -a Report.txt; fi
if [[ -n "$TEMPORARYREDIRECT" ]];then echo "307: TemporaryRedirect" | tee -a Report.txt; fi
if [[ -n "$PERMANENTREDIRECT" ]];then echo "308: PermanentRedirect" | tee -a Report.txt; fi
if [[ -n "$BADREQUEST" ]];then echo "400: BadRequest" | tee -a Report.txt; fi
if [[ -n "$UNAUTHORIZED" ]];then echo "401: Unauthorized" | tee -a Report.txt; fi
if [[ -n "$FORBIDDEN" ]];then echo "403: Forbidden" | tee -a Report.txt; fi
if [[ -n "$NOTFOUND" ]];then echo "404: NotFound" | tee -a Report.txt; fi
if [[ -n "$METHODNOTALLOWED" ]];then echo "405: MethodNotAllowed" | tee -a Report.txt; fi
if [[ -n "$NOTACCEPTABLE" ]];then echo "406: NotAcceptable" | tee -a Report.txt; fi
if [[ -n "$PROXYAUTHENTICATIONREQUIRED" ]];then echo "407: ProxyAuthenticationRequired" | tee -a Report.txt; fi
if [[ -n "$REQUESTTIMEOUT" ]];then echo "408: RequestTimeout" | tee -a Report.txt; fi
if [[ -n "$CONFLICT" ]];then echo "409: Conflict" | tee -a Report.txt; fi
if [[ -n "$GONE" ]];then echo "410: Gone" | tee -a Report.txt; fi
if [[ -n "$LENGTHREQUIRED" ]];then echo "411: LengthRequired" | tee -a Report.txt; fi
if [[ -n "$PRECONDITIONFAILED" ]];then echo "412: PreconditionFailed" | tee -a Report.txt; fi
if [[ -n "$PAYLOADTOOLARGE" ]];then echo "413: PayloadTooLarge" | tee -a Report.txt; fi
if [[ -n "$URITOOLONG" ]];then echo "414: URITooLong" | tee -a Report.txt; fi
if [[ -n "$UNSUPPORTEDMEDIATYPE" ]];then echo "415: UnsupportedMediaType" | tee -a Report.txt; fi
if [[ -n "$RANGENOTSATIS" ]];then echo "416: RangeNotSatis; fiable" | tee -a Report.txt; fi
if [[ -n "$EXPECTATIONFAILED" ]];then echo "417: ExpectationFailed" | tee -a Report.txt; fi
if [[ -n "$UPGRADEREQUIRED" ]];then echo "426: UpgradeRequired" | tee -a Report.txt; fi
if [[ -n "$PRECONDITIONREQUIRED" ]];then echo "428: PreconditionRequired" | tee -a Report.txt; fi
if [[ -n "$TOOMANYREQUESTS" ]];then echo "429: TooManyRequests" | tee -a Report.txt; fi
if [[ -n "$REQUESTHEADERTOOLARGE" ]];then echo "431: RequestHeader; fieldsTooLarge" | tee -a Report.txt; fi
if [[ -n "$UNAVAILABLEFORLEGALREASONS" ]];then echo "451: UnavailableForLegalReasons" | tee -a Report.txt; fi
if [[ -n "$INTERNALSERVERERROR" ]];then echo "500: InternalServerError" | tee -a Report.txt; fi
if [[ -n "$NOTIMPLEMENTED" ]];then echo "501: NotImplemented" | tee -a Report.txt; fi
if [[ -n "$BADGATEWAY" ]];then echo "502: BadGateway" | tee -a Report.txt; fi
if [[ -n "$SERVICEUNAVAILABLE" ]];then echo "503: ServiceUnavailable" | tee -a Report.txt; fi
if [[ -n "$GATEWAYTIMEOUT" ]];then echo "504: GatewayTimeout" | tee -a Report.txt; fi
if [[ -n "$HTTPVERSIONNOTSUPPORTED" ]];then echo "505: HTTPVersionNotSupported" | tee -a Report.txt; fi
if [[ -n "$NETWORKAUTHENTICATIONREQUIRED" ]];then echo "511: Network Authentication Required" | tee -a Report.txt; fi
if [[ -n "$UNKNOWN" ]];then echo "Unknown HTTP response code" | tee -a Report.txt; fi

# print overview
echo | tee -a Report.txt
echo -e "Sitemap Files:\t${SITEMAPS}" | tee -a Report.txt
echo -e "Links Total:\t${LINKSTOTAL}" | tee -a Report.txt
echo -e "Links Unique:\t${LINKSUNIQUE}" | tee -a Report.txt
echo -e "Links Checked:\t${COUNTER}" | tee -a Report.txt
echo -e "Anomalies:\t${ANOMALIES}" | tee -a Report.txt
echo -e "Duration:\t${SECONDS} s\n\n" | tee -a Report.txt
read -p "Done! Press any key to exit ... " -n 1
clear
