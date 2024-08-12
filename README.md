# XSS Popup Detection Script: autoXSS

## Overview

This Bash script automates the process of detecting potential Cross-Site Scripting (XSS) vulnerabilities in a list of domains. It uses tools like `gau` for URL enumeration, `httpx` for testing potential XSS parameters, and a Python script for further analysis.

## Requirements

Before running the script, ensure that the following tools are installed:

- `gau`
- `httpx`
- `python3`

You can install them using the following commands:

```bash
# For gau
go install github.com/lc/gau/v2/cmd/gau@latest

# For httpx
go install github.com/projectdiscovery/httpx/cmd/httpx@latest

# Python3 should be available by default on most systems
```

## Dependencies: Selenium and ChromeDriver
>Tested Operating System: Ubuntu and kali linux
```
 wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
 sudo dpkg -i google-chrome-stable_current_amd64.deb
 sudo apt-get -f install
 sudo apt install python3-selenium
 google-chrome --version
 rm -rf google-chrome-stable_current_amd64.deb
 wget https://storage.googleapis.com/chrome-for-testing-public/127.0.6533.99/linux64/chromedriver-linux64.zip
 unzip chromedriver-linux64.zip
 sudo mv chromedriver-linux64/chromedriver /usr/local/bin/chromedriver
 sudo chmod +x /usr/local/bin/chromedriver
 chromedriver --version
 rm -rf chromedriver-linux64.zip
```

## File Structure

- `domain.txt` - A file containing a list of domains to scan. Each domain should be on a new line.
- `logs.txt` - Log file where the results of the scan will be saved.
- `scripts/xss.py` - Python script used for further XSS detection (Make sure this script is in the `scripts` directory).
- `potentialXSS` - Directory where potential XSS URLs will be saved.
- `XSS` - Directory where confirmed XSS findings will be saved.

## Usage

1. **Prepare Your Domain List:**

   Create a file named `domain.txt` and list the domains you want to scan, one per line.

2. **Run the Script:**

   Execute the script with the following command:

   ```bash
   ./scripts/scan.sh domain.txt
   ```
>>Replace `domain.txt` with the name of your domain list file if it's different.

## What the Script Does

1. **Setup and Validation:**
   - Checks for the presence of required tools (`gau`, `httpx`, `python3`).
   - Creates necessary directories (`potentialXSS` and `XSS`).

2. **Processing Each Domain:**
   - Retrieves URLs from the domain using `gau`.
   - Modifies URLs to include XSS payloads.
   - Sorts and removes duplicate URLs.
   - Uses `httpx` to find potential XSS vulnerabilities.
   - Runs a Python script to analyze the potential XSS.

3. **Logging and Cleanup:**
   - Logs the results of each domain scan to `logs.txt`.
   - Cleans up temporary files.
   - Sends notifications with the count of XSS and potential XSS found.

4. **Final Summary:**
   - Provides a summary of all scans, including total XSS detections.

## Notifications

The script uses the `notify` command to send notifications via Discord. Ensure you have the `notify` utility installed and configured.

## Troubleshooting

- **Tool Not Found Errors:** Ensure all required tools are installed and accessible in your system's PATH.
- **Permissions Issues:** Make sure the script has execution permissions (`chmod +x scan.sh`).

## License

This script is provided as-is. Use it at your own risk, and ensure you have permission to scan the domains you are testing.

## Contact

For any questions or issues, please contact the author or contribute to the project via the repository where this script is hosted.

---

Feel free to modify or enhance this script according to your specific needs or environment.
   
