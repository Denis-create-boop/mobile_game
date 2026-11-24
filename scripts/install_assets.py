#!/usr/bin/env python3
"""Install Kenney CC0 GLB packs locally; keep archive license texts."""
from pathlib import Path
from urllib.request import urlopen, Request
from zipfile import ZipFile
from io import BytesIO
import json, shutil, re

ROOT=Path(__file__).resolve().parents[1]
DEST=ROOT/"assets"/"kenney"
PACKS={
 "market":"https://kenney.nl/media/pages/assets/mini-market/463f38da51-1729865423/kenney_mini-market.zip",
 "people":"https://kenney.nl/media/pages/assets/mini-characters/bfc7e272b4-1774770718/kenney_mini-characters.zip",
 "food":"https://kenney.nl/media/pages/assets/food-kit/83086fa91c-1719418518/kenney_food-kit.zip"
}
def normalize(s): return re.sub(r"[^a-z0-9]","",s.lower())
def install():
 DEST.mkdir(parents=True,exist_ok=True)
 manifest={}
 for pack,url in PACKS.items():
  folder=DEST/pack
  folder.mkdir(exist_ok=True)
  if not list(folder.rglob("*.glb")):
   print("Downloading",pack,flush=True)
   with urlopen(Request(url,headers={"User-Agent":"MarketEmpire asset installer"}),timeout=90) as r:
    data=r.read()
   with ZipFile(BytesIO(data)) as z:
    for info in z.infolist():
     path=Path(info.filename.replace("\\","/"))
     if info.is_dir() or path.is_absolute() or ".." in path.parts: continue
     if path.suffix.lower() not in (".glb",".png",".jpg",".jpeg",".txt",".md"): continue
     target=folder/path
     target.parent.mkdir(parents=True,exist_ok=True)
     with z.open(info) as source,target.open("wb") as out: shutil.copyfileobj(source,out)
  models=sorted(folder.rglob("*.glb"))
  if not models: raise RuntimeError("No GLB files in "+pack)
  manifest[pack]={normalize(p.stem):"res://"+p.relative_to(ROOT).as_posix() for p in models}
  print(pack,len(models),"models",flush=True)
 (DEST/"catalog.json").write_text(json.dumps(manifest,indent=2),encoding="utf-8")
if __name__=="__main__": install()
