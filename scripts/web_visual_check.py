from pathlib import Path
from playwright.sync_api import sync_playwright
from PIL import Image
from collections import Counter
root=Path("build/web")
release=next(root.glob("release-*")).name
with sync_playwright() as p:
    browser=p.chromium.launch(headless=True,args=["--no-sandbox","--use-gl=angle","--use-angle=swiftshader","--enable-unsafe-swiftshader"])
    page=browser.new_page(viewport={"width":1280,"height":900})
    page.on("console",lambda msg: print("BROWSER:",msg.type,msg.text[:600]) if msg.type=="error" else None)
    page.goto("http://127.0.0.1:8765/"+release+"/?visual_test=1",wait_until="load",timeout=120000)
    page.wait_for_timeout(45000)
    page.screenshot(path="/tmp/game.png",timeout=120000)
    im=Image.open("/tmp/game.png").convert("RGB").crop((220,180,1060,720)).resize((210,135))
    colors=Counter(tuple(c//16 for c in rgb) for rgb in im.getdata())
    dominant=colors.most_common(1)[0][1]/(210*135)
    print("central scene colors",len(colors),"dominant",dominant)
    if len(colors)<45 or dominant>0.60:
        raise SystemExit("Scene appears blank or menu is still visible")
    browser.close()
