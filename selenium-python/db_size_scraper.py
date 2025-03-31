import pandas as pd
import time
import os
from datetime import datetime
from urllib.parse import quote
from selenium import webdriver
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC

def setup_chrome_driver():
    """Setup Chrome driver with Selenium"""
    chrome_options = Options()
    chrome_path = r"C:\Program Files\Google\Chrome\Application\chrome.exe"
    chrome_options.binary_location = chrome_path
    service = Service('chromedriver.exe')  # Make sure chromedriver.exe is in the same directory
    return webdriver.Chrome(service=service, options=chrome_options)

def scrape_database_info(base_url, db_names):
    """Scrape database information using Chrome directly"""
    results = []
    driver = setup_chrome_driver()
    
    try:
        for db_name in db_names:
            encoded_db_name = quote(db_name.strip())
            url = f"{base_url}databse={encoded_db_name}&filter="
            print(f"Processing URL: {url}")
            
            try:
                driver.get(url)
                
                # Wait for table to load
                wait = WebDriverWait(driver, 10)
                table = wait.until(EC.presence_of_element_located((By.XPATH, '/html/body/p[1]/table[4]')))
                
                # Check if there are databases in the list
                no_dbs_text = table.text
                if "There are 0 databases in this list." in no_dbs_text:
                    print(f"No databases found for {db_name}")
                    continue
                
                # Find all database rows
                rows = driver.find_elements(By.XPATH, '/html/body/p[1]/table[4]/tbody/tr/td[2]/p[2]/table/tbody/tr')
                
                for row in rows:
                    try:
                        db = row.find_element(By.XPATH, './td[1]/a').text.strip()
                        allocated = row.find_element(By.XPATH, './td[3]').text.strip()
                        used = row.find_element(By.XPATH, './td[4]').text.strip()
                        
                        results.append({
                            'db_name': db,
                            'space_allocated': allocated,
                            'space_used': used
                        })
                    except Exception as e:
                        print(f"Error processing row: {str(e)}")
                        continue
                
                time.sleep(2)  # Small delay between requests
                
            except Exception as e:
                print(f"Error processing URL {url}: {str(e)}")
                continue
                
    finally:
        driver.quit()
    
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