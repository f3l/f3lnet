import sys
import os
cwd = os.path.abspath(os.path.dirname(__file__))
os.chdir(cwd)
sys.path.insert(0, cwd)
from application import app as application
