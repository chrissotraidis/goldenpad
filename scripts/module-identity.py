#!/usr/bin/env python3
from pathlib import Path
import sys
sys.path.insert(0, str(Path(__file__).resolve().parent))
from module_build import identity
print(identity())
