import argparse
import threading
from selenium import webdriver
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.chrome.options import Options
from selenium.common.exceptions import UnexpectedAlertPresentException, TimeoutException
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC

# Define color codes
class Colors:
    RESET = "\033[0m"
    RED = "\033[31m"
    GREEN = "\033[32m"
    YELLOW = "\033[33m"
    BLUE = "\033[34m"
    MAGENTA = "\033[35m"
    CYAN = "\033[36m"
    WHITE = "\033[37m"

def check_xss(url, driver, output_file):
    try:
        driver.get(url)
        print(f"{Colors.YELLOW}[-] Visiting URL: {url}{Colors.RESET}")

        try:
            alert = WebDriverWait(driver, 3).until(EC.alert_is_present())
            alert.accept()
            print(f"{Colors.GREEN}[+] XSS Detected: {url}{Colors.RESET}")
            with open(output_file, 'a') as file:
                file.write(f"{url}\n")
        except (TimeoutException, UnexpectedAlertPresentException):
            pass  # Do nothing if no alert or unexpected alert detected
    except Exception as e:
        pass  # Suppress other exceptions and errors

def worker(urls, driver_path, output_file):
    chrome_options = Options()
    chrome_options.add_argument("--headless")
    chrome_options.add_argument("--disable-gpu")
    chrome_options.add_argument("--disable-extensions")
    chrome_options.add_argument("--no-sandbox")
    chrome_service = Service(driver_path)
    driver = webdriver.Chrome(service=chrome_service, options=chrome_options)

    try:
        for url in urls:
            check_xss(url.strip(), driver, output_file)
    finally:
        driver.quit()

def main(urls_file, output_file, num_threads):
    with open(urls_file, 'r') as file:
        urls = file.readlines()

    chunk_size = len(urls) // num_threads
    threads = []

    driver_path = "/usr/bin/chromedriver"
    for i in range(num_threads):
        chunk = urls[i*chunk_size:(i+1)*chunk_size]
        t = threading.Thread(target=worker, args=(chunk, driver_path, output_file))
        threads.append(t)
        t.start()

    for t in threads:
        t.join()

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="XSS Testing Script")
    parser.add_argument('-l', '--list', required=True, help="Path to the input URL list file")
    parser.add_argument('-o', '--output', required=True, help="Path to the output file for alert-detected URLs")
    parser.add_argument('-t', '--threads', type=int, default=4, help="Number of threads for parallel processing")
    args = parser.parse_args()

    main(args.list, args.output, args.threads)
