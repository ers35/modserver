from modserver import *

def run(s):
  set_status(s, 200)
  set_header(s, "Content-Type", "text/plain; charset=UTF-8")
  arg = get_arg(s, "arg")
  if arg:
    rwrite(s, arg + "\n")
  rwrite(s, get_method(s)  + "\n")
  rwrite(s, get_header(s, "User-Agent") + "\n")
  rflush(s)
