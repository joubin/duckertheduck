from playwright.sync_api import sync_playwright, Playwright
import time
import asyncio
import base64
import requests
from dotenv import load_dotenv



def run(playwright: Playwright):
    chromium = playwright.chromium # or "firefox" or "webkit".
    browser = chromium.launch(headless=True)
    context = browser.new_context()
    context.grant_permissions(["clipboard-read"])
    page = context.new_page()

    page.goto("https://grafana.lab.jabbari.io/login")
    time.sleep(1)
    page.get_by_text(text="email or username").fill("reader")
    page.get_by_placeholder("password").fill("reader")
    page.get_by_text(text="Log in").click()
    time.sleep(1)
    page.goto("https://grafana.lab.jabbari.io/d/de2url9wvhts0a/sound-levels?kiosk=&from=now-1w&to=now&timezone=browser")
    # other actions...
    time.sleep(5)

    # page.get_by_alt_text(text="Share Dashboard").click()
    page.locator(selector="#reactRoot > div > div.main-view > header > div.css-1fj7032 > div.css-1ntsjus-NavToolbar-actions > div.css-16lblkh > div > div:nth-child(5) > button > span").click()
    page.locator(selector="body > div:nth-child(14) > div.css-1p0yltr > div.css-1y5q12f-modalHeader > div.css-1kp1llc > div > div:nth-child(3) > button").click()
    time.sleep(1)
    page.locator(selector="#option-3600-expire-select-input").click()
    page.get_by_text("Publish to snapshots.raintank.io").click()
    # page.locator(selector="body > div:nth-child(14) > div.css-1p0yltr > div.css-fwe93l > div > div.css-19n8dai > div > button.css-8b29hm-button > span").click
    page.get_by_text("Copy").click()
    x =page.locator(selector="#snapshot-url-input").input_value()

    browser.close()

    html = f"""
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
    <head>
        <title>Serrano/Bass Lake Safeway Noise Area```</title>
        <style type="text/css">
            body, html
            {{
                margin: 0; padding: 0; height: 100%; overflow: hidden;
            }}

            #content
            {{
                position:absolute; left: 0; right: 0; bottom: 0; top: 0px; 
            }}
        </style>
    </head>
    <body>
        <div id="content">
            <iframe width="100%" height="100%" frameborder="0" src="{x}"></iframe>
        </div>
    </body>
</html>
    """    


    # Define your GitHub credentials and repo details
    OWNER = "joubin"
    REPO = "duckertheduck"
    FILE_PATH = "docs/metrics.html"
    BRANCH = "main"

    # Get the current file's SHA
    url = f"https://api.github.com/repos/{OWNER}/{REPO}/contents/{FILE_PATH}"
    headers = {
        "Authorization": f"Bearer {TOKEN}",
        "Content-Type": "application/json",
    }

    response = requests.get(url, headers=headers)
    response.raise_for_status()  # Ensure the request was successful

    # Extract the SHA of the current file
    file_info = response.json()
    file_sha = file_info["sha"]

    # Prepare the new file content
    new_content_encoded = base64.b64encode(html.encode("utf-8")).decode("utf-8")

    # Prepare the request payload
    payload = {
        "message": "Updating file via GitHub API",
        "content": new_content_encoded,
        "sha": file_sha,
        "branch": BRANCH,
    }

    # Update the file
    response = requests.put(url, headers=headers, json=payload)
    response.raise_for_status()  # Ensure the request was successful

    # Print the result
    print("File updated successfully:", response.json())

while True:
    import os
    # load_dotenv(dotenv_path='/Users/joubin/Git/duckdeduck/db_sensor/.env')
    DELAY=os.getenv('DELAY', 900)
    TOKEN = os.getenv('GITHUB_METRICS_WRITE_TOKEN')
    print(TOKEN)
    with sync_playwright() as playwright:
        run(playwright)
    time.sleep(3600)