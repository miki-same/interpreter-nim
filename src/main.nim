import repl
import os
let user=getEnv("USER")

echo "Hello ", user,"! This is the Monkey programming language!"

repl.start()