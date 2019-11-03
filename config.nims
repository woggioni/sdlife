# mode = ScriptMode.Whatif
task build, "builds an example":
  setCommand("c", "src/sdlife/main.nim")
  for i in 0..paramCount():
    let param = paramStr(i)
    if param == "-d:wasm":
        cpFile("resources/index.html", "build/index.html")
