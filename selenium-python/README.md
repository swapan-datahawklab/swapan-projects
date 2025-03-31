# Database Size Scraper

This Python script scrapes database information from a web page and saves it to a CSV file. It uses Chrome browser to open each URL for visual verification.

## Prerequisites

- Python 3.6 or higher
- Google Chrome browser installed
- Required Python packages (install using `pip install -r requirements.txt`)

## Installation

1. Clone this repository or download the files
2. Install the required packages:

   ```bash
   pip install -r requirements.txt
   ```

## Configuration

1. Open `db_size_scraper.py`
2. Update the following variables in the `main()` function:
   - `base_url`: Your target URL where the database information is displayed
   - `param_range`: The range of parameters to iterate through

3. If your Chrome installation is in a different location, update the `chrome_path` variable in the `open_chrome()` function.

## Usage

Run the script:

```bash
python db_size_scraper.py
```

The script will:

1. Process each URL in the specified range
2. Open Chrome browser for each URL
3. Parse the HTML table to extract database names and sizes
4. Save the results to `database_sizes.csv`

## Output

The script generates a CSV file (`database_sizes.csv`) containing:

- Database Name
- Database Size
- Timestamp of when the data was scraped

## Notes

- The script includes a 2-second delay between requests to prevent overwhelming the server
- Make sure you have proper access rights to the target URL
- Adjust the table parsing logic in `scrape_database_info()` if the HTML structure is different