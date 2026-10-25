#!/usr/bin/env python3
from pathlib import Path
import json
import sys
from module_build import ROOT, HEADERS_PIN, check_generated, check_source
try:
    pin = json.loads((ROOT / "sources.lock.json").read_text())["components"]["goldeneye"]
    check_source(ROOT / pin["path"], pin["commit"])
    check_source(ROOT / pin["path"] / "lib/ge", HEADERS_PIN)
    check_generated(Path(sys.argv[1]))
except (OSError, ValueError) as error:
    sys.exit(str(error))
