from pathlib import Path
from playwright.sync_api import sync_playwright
import os, time
from PIL import Image
root=Path("build/web")
release=next(root.glob("release-*")).name
with sync_playwright() as p:
    browser=p.chromium.launch(headless=True,args=["--no-sandbox","--use-gl=angle","--use-angle=swiftshader","--enable-unsafe-swiftshader"])
    page=browser.new_page(viewport={"width":1100,"height":760})
    errors=[]
    page.on("pageerror",lambda e: errors.append(str(e)))
    page.on("console",lambda msg: print("BROWSER:",msg.type,msg.text[:500]) if msg.type=="error" else None)
    page.goto("http://127.0.0.1:8765/"+release+"/",wait_until="load",timeout=120000)
    page.wait_for_timeout(25000)
    # Canvas UI has no DOM buttons. Capture menu, then click its first centered button.
    page.screenshot(path="/tmp/menu.png")
    page.mouse.click(550,268)
    page.wait_for_timeout(1800)
    page.screenshot(path="/tmp/game.png")
    # Record evidence for inspection without guessing whether a pixel test passed.
    print("WEB PAGE ERRORS",errors)
    browser.close()
