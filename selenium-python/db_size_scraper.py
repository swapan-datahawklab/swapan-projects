import requests
from bs4 import BeautifulSoup
import pandas as pd
import time
import os
import subprocess
from datetime import datetime
from urllib.parse import quote
from lxml import html

def open_chrome(url):
    """Open Chrome browser with the given URL"""
    chrome_path = r"C:\Program Files\Google\Chrome\Application\chrome.exe"
    if os.path.exists(chrome_path):
        subprocess.Popen([chrome_path, url])
    else:
        print(f"Chrome not found at {chrome_path}")
        print("Please update the chrome_path variable with your Chrome installation path")

def scrape_database_info(base_url, db_names):
    """Scrape database information from the URL"""
    results = []
    
    for db_name in db_names:
        # URL encode the database name
        encoded_db_name = quote(db_name.strip())
        url = f"{base_url}databse={encoded_db_name}&filter="
        print(f"Processing URL: {url}")
        
        try:
            # Make HTTP request
            response = requests.get(url)
            response.raise_for_status()
            
            # Parse HTML with lxml for XPath support
            tree = html.fromstring(response.content)
            
            # Check if there are databases in the list
            no_dbs_text = tree.xpath('/html/body/p[1]/table[4]/tbody/tr/td[2]/text()[2]')
            if no_dbs_text and "There are 0 databases in this list." in no_dbs_text[0]:
                print(f"No databases found for {db_name}")
                continue
            
            # Extract database information using XPath
            db_names = tree.xpath('/html/body/p[1]/table[4]/tbody/tr/td[2]/p[2]/table/tbody/tr/td[1]/a/text()')
            space_allocated = tree.xpath('/html/body/p[1]/table[4]/tbody/tr/td[2]/p[2]/table/tbody/tr/td[3]/text()')
            space_used = tree.xpath('/html/body/p[1]/table[4]/tbody/tr/td[2]/p[2]/table/tbody/tr/td[4]/text()')
            
            # Combine the data
            for db, allocated, used in zip(db_names, space_allocated, space_used):
                results.append({
                    'db_name': db.strip(),
                    'space_allocated': allocated.strip(),
                    'space_used': used.strip()
                })
            
            # Open Chrome for visual verification
            open_chrome(url)
            
            # Add a small delay to prevent overwhelming the server
            time.sleep(2)
            
        except Exception as e:
            print(f"Error processing URL {url}: {str(e)}")
            continue
    
    return results

def save_to_csv(data, filename='database_sizes.csv'):
    """Save the scraped data to a CSV file"""
    df = pd.DataFrame(data)
    df.to_csv(filename, index=False)
    print(f"Data saved to {filename}")

def read_database_names(filename='database_names.txt'):
    """Read database names from a file"""
    try:
        with open(filename, 'r') as f:
            return [line.strip() for line in f if line.strip()]
    except FileNotFoundError:
        print(f"Error: {filename} not found")
        return []

def main():
    # Configuration
    base_url = "http://dbatools./com:7777/dba.tools_results_page?v_db_ty0pe=&"
    
    # Read database names from file
    db_names = read_database_names()
    if not db_names:
        print("No database names found. Please create database_names.txt with one database name per line.")
        return
    
    # Scrape data
    results = scrape_database_info(base_url, db_names)
    
    # Save results
    if results:
        save_to_csv(results)
        print(f"Successfully scraped {len(results)} database entries")
    else:
        print("No data was scraped")

if __name__ == "__main__":
    main() 