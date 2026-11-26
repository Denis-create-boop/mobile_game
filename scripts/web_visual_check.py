from pathlib import Path
from playwright.sync_api import sync_playwright
from PIL import Image
from collections import Counter
root=Path("build/web")
release=next(root.glob("release-*")).name
with sync_playwright() as p:
    browser=p.chromium.launch(headless=True,args=["--no-sandbox","--use-gl=angle","--use-angle=swiftshader","--enable-unsafe-swiftshader"])
    page=browser.new_page(viewport={"width":1280,"height":900})
    errors=[]
    page.on("pageerror",lambda e: errors.append(str(e)))
    page.on("console",lambda msg: print("BROWSER:",msg.type,msg.text[:600]) if msg.type=="error" else None)
    page.goto("http://127.0.0.1:8765/"+release+"/",wait_until="load",timeout=120000)
    page.wait_for_timeout(35000)
    page.screenshot(path="/tmp/menu.png")
    # First button: centered column of 8 buttons below heading/subtitle.
    # Try a range of y coordinates, stopping as soon as the central region shows scene variation.
    ok=False
    for y in [305,325,345,365,285,265]:
        page.mouse.click(640,y)
        page.wait_for_timeout(1800)
        page.screenshot(path="/tmp/game.png")
        im=Image.open("/tmp/game.png").convert("RGB").crop((100,130,1180,760)).resize((180,105))
        colors=Counter(tuple(c//16 for c in rgb) for rgb in im.getdata())
        dominant=colors.most_common(1)[0][1]/(180*105)
        print("scene colors",len(colors),"dominant",dominant)
        if len(colors)>=45 and dominant<0.72:
            ok=True
            break
    print("WEB PAGE ERRORS",errors)
    browser.close()
    if not ok:
        raise SystemExit("Scene not visually verified; inspect screenshot")
