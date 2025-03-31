import requests
from bs4 import BeautifulSoup
import pandas as pd
import time
import os
import subprocess
from datetime import datetime

def open_chrome(url):
    """Open Chrome browser with the given URL"""
    chrome_path = r"C:\Program Files\Google\Chrome\Application\chrome.exe"
    if os.path.exists(chrome_path):
        subprocess.Popen([chrome_path, url])
    else:
        print(f"Chrome not found at {chrome_path}")
        print("Please update the chrome_path variable with your Chrome installation path")

def scrape_database_info(base_url, param_range):
    """Scrape database information from the URL"""
    results = []
    
    for param in param_range:
        url = f"{base_url}{param}"
        print(f"Processing URL: {url}")
        
        try:
            # Make HTTP request
            response = requests.get(url)
            response.raise_for_status()
            
            # Parse HTML
            soup = BeautifulSoup(response.text, 'html.parser')
            
            # Find the table (adjust the selector based on your HTML structure)
            table = soup.find('table')
            if table:
                # Process table rows
                for row in table.find_all('tr')[1:]:  # Skip header row
                    cols = row.find_all('td')
                    if len(cols) >= 2:  # Ensure we have enough columns
                        db_name = cols[0].text.strip()
                        db_size = cols[1].text.strip()
                        results.append({
                            'Database Name': db_name,
                            'Database Size': db_size,
                            'Timestamp': datetime.now().strftime('%Y-%m-%d %H:%M:%S')
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

def main():
    # Configuration
    base_url = "YOUR_BASE_URL_HERE"  # Replace with your actual base URL
    param_range = range(1, 11)  # Example: process parameters 1 to 10
    
    # Scrape data
    results = scrape_database_info(base_url, param_range)
    
    # Save results
    if results:
        save_to_csv(results)
        print(f"Successfully scraped {len(results)} database entries")
    else:
        print("No data was scraped")

if __name__ == "__main__":
    main()