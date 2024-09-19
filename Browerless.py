from selenium import webdriver
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.chrome.options import Options

# Specify the path to the downloaded ChromeDriver binary
service = Service("/opt/webdriver/chromedriver")  # Update with your actual path

# Initialize Chrome options
options = Options()
options.add_argument('--headless')  # Run in headless mode
options.add_argument('--disable-gpu')  # Disable GPU rendering for headless mode

# Use the service and options to initialize the Chrome WebDriver
driver = webdriver.Chrome(service=service, options=options)

# Navigate to a web page
driver.get("https://www.google.com")

# Get and print the page title
page_title = driver.title
print(page_title)

# Close the Selenium session
driver.quit()
