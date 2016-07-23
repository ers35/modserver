from datetime import datetime
from modserver import *

def run(s):
  rwrite(s, str(datetime.now()))
