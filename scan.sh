
echo -e """\033[0;31m \033[01m
 _           _____
| |_ ___ ___|   __|___ ___ ___
|  _| . | . |__   |  _| .'|   |
|_| |___|  _|_____|___|__,|_|_|
        |_| \033[34m @thenurhabib 
================================
"""
echo -e "\033[01m \033[36m"
read -p "Enter Domain Name : " domain
echo -e "\033[01m \033[93m"
echo -e "Finding Subdomains"
echo -e "\033[0m"
curl -s "https://riddler.io/search/exportcsv?q=pld:$domain" | grep -Po "(([\w.-]*)\.([\w]*)\.([A-z]))\w+" | sort -u  -u | grep "\.$domain" > subdomains.txt

curl -s "https://www.virustotal.com/ui/domains/$domain/subdomains?limit=40" | grep -Po "((http|https):\/\/)?(([\w.-]*)\.([\w]*)\.([A-z]))\w+" | sort -u
curl --silent https://sonar.omnisint.io/subdomains/$domain | grep -oE "[a-zA-Z0-9._-]+\.HOST" | sort -u
echo -e "\033[01m \033[33m Subdomains are Saved in : subdomains.txt file. \033[0m"
echo -e "\033[01m \033[93m"
echo "Port Scanning."
echo -e "\033[0m"
subfinder -silent -d $domain | filter-resolved | cf-check | sort -u | naabu -rate 40000 -silent -verify | httprobe
echo -e "\033[01m \033[93m"
echo "Find Subdomain Tackover"
echo -e "\033[0m"
subfinder -d $domain >> subdomains.txt; assetfinder --subs-only $domain >> subdomains.txt; amass enum -norecursive -noalts -d $domain >> subdomains.txt; subjack -w FILE -t 100 -timeout 30 -ssl -c $GOPATH/src/github.com/haccer/subjack/fingerprints.json -v 3 >> takeover ;
echo -e "\033[01m \033[93m"
echo "Custom URLs from ParamSpider"
echo -e "\033[0m"
cat subdomains.txt.txt | xargs -I % python3 paramspider.py -l high -o ./OUT/% -d %;
echo -e "\033[01m \033[93m"
echo "Gather Domains from Content-Security-Policy"
echo -e "\033[0m"
curl -vs $domain --stderr - | awk '/^content-security-policy:/' | grep -Eo "[a-zA-Z0-9./?=_-]*" |  sed -e '/\./!d' -e '/[^A-Za-z0-9._-]/d' -e 's/^\.//' | sort -u
echo -e "\033[01m \033[93m"
echo "Find Hidden Servers and/or Admin Panels"
echo -e "\033[0m"
ffuf -c -u $domain -H "Host: FUZZ" -w FILE.txt
echo -e "\033[01m \033[93m"
echo "Finding XSS"
echo -e "\033[0m"
waybackurls $domain | grep '=' | qsreplace '"><script>alert(1)</script>' | while read host do; do curl -s --path-as-is --insecure "$host" | grep -qs "<script>alert(1)</script>" && echo "$host \033[0;31" Vulnerable;done
echo -e "\033[01m \033[93m"
echo "Dump URLs from sitemap.xml"
echo -e "\033[0m"
curl -s $domain/sitemap.xml | xmllint --format - | grep -e 'loc' | sed -r 's|</?loc>||g'
echo ""
echo ""
echo -e "\033[01m \033[33m Complete."