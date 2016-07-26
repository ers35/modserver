def run(s)
  set_status(s, 200)
  set_header(s, "Content-Type", "text/plain; charset=UTF-8")
  arg = get_arg(s, "arg")
  unless arg.nil?
    rwrite(s, arg)
  end
  rwrite(s, get_method(s))
  header = get_header(s, "User-Agent")
  unless header.nil?
    rwrite(s, header)
  end
  rflush(s)
end
