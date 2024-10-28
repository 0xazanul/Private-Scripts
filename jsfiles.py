import os
import subprocess
import argparse
from colorama import Fore, Style, init

# Initialize colorama for colored output
init(autoreset=True)

# Configuration paths
BASE_DIR = "/home/xab/Desktop"
ALL_URLS_FILE = os.path.join(BASE_DIR, "all_urls.txt")  # All URLs including .js
JS_FILES_FILE = os.path.join(BASE_DIR, "js_files.txt")   # Filtered .js URLs only

# Display banner
def print_banner():
    print(Fore.CYAN + Style.BRIGHT + r"""
     ___       ___  __  __   __  __   __   __   __   __  
    |__  |    |__  |__)  _) |__)|__) /  \ |  \ |__) |__  
    |___ |___ |___ |  \ /__ |  \|  \ \__/ |__/ |  \ |___ 
                                                        
    JavaScript File Scanner - URL Collector and Filter
    """ + Style.RESET_ALL)
    print(Fore.MAGENTA + "[*] Collecting URLs with waybackurls, gauplus, waymore, katana, and hakrawler" + Style.RESET_ALL)

# Parse arguments for domain or file input
parser = argparse.ArgumentParser(description="JavaScript URL Collector and Filter")
parser.add_argument('-d', '--domain', help='Specify a single target domain (e.g., example.com)')
parser.add_argument('-f', '--file', help='Specify a file with a list of target domains')
args = parser.parse_args()

# Get list of domains to scan
domains = []
if args.domain:
    domains.append(args.domain)
elif args.file:
    with open(args.file, 'r') as f:
        domains = [line.strip() for line in f if line.strip()]
else:
    print(Fore.RED + "Please provide a target domain with -d or a file with -f." + Style.RESET_ALL)
    exit(1)

# Ensure output directory exists
os.makedirs(BASE_DIR, exist_ok=True)

# Step 1: Collect URLs using external tools and save them to files
def gather_urls(domains):
    print(Fore.YELLOW + "[+] Gathering URLs using waybackurls, gauplus, waymore, katana, and hakrawler..." + Style.RESET_ALL)
    
    all_urls = set()  # Collect all URLs
    js_urls = set()   # Collect only JavaScript URLs

    for domain in domains:
        # Run tools to collect URLs
        tools = [
            f"waybackurls {domain}",
            f"gauplus -t 5 {domain}",
            f"waymore -d {domain}",
            f"katana -u {domain} -d 1 -silent",
            f"hakrawler -url {domain} -depth 2 -plain"
        ]
        
        # Execute each tool and collect unique URLs
        for tool in tools:
            try:
                result = subprocess.run(tool, shell=True, capture_output=True, text=True)
                urls = result.stdout.splitlines()
                
                # Categorize URLs into all URLs and .js URLs
                for url in urls:
                    all_urls.add(url)
                    if url.endswith('.js'):
                        js_urls.add(url)
                
            except subprocess.CalledProcessError as e:
                print(Fore.RED + f"Failed to run {tool}: {e}" + Style.RESET_ALL)

    # Write all URLs including JS files
    with open(ALL_URLS_FILE, 'w') as all_file:
        all_file.write("\n".join(sorted(all_urls)))

    # Write only JavaScript URLs
    with open(JS_FILES_FILE, 'w') as js_file:
        js_file.write("\n".join(sorted(js_urls)))

    print(Fore.GREEN + f"[+] Collected {len(all_urls)} total URLs, with {len(js_urls)} JavaScript URLs." + Style.RESET_ALL)
    print(Fore.YELLOW + f"[+] All URLs saved to {ALL_URLS_FILE}" + Style.RESET_ALL)
    print(Fore.YELLOW + f"[+] JavaScript URLs saved to {JS_FILES_FILE}" + Style.RESET_ALL)

# Run the URL collection function
print_banner()
gather_urls(domains)

print(Fore.GREEN + "[+] URL collection and filtering complete." + Style.RESET_ALL)
