javahome() {
  unset JAVA_HOME
  export JAVA_HOME=$(/usr/libexec/java_home -v "$1")
  java -version
}

uuid() {
  uuidgen | tr A-Z a-z
}

jwt-claims() {
  awk -F. '(l = length($2)){printf $2} END {if (l%4 != 0) {for(i=1; i<=(4-l%4); i++){printf "="}}}' | base64 -d
}

jtg() {
  node /usr/local/json-to-go/json-to-go.js
}

jtgc() {
  pbpaste | jtg | pbcopy
}

kp() {
  if [[ -z "$1" ]]; then
    echo "Usage: kp <port>"
    return 1
  fi

  local pids
  pids=("${(@f)$(lsof -t -i :"$1")}")

  if (( ${#pids[@]} == 0 )); then
    echo "No process using port $1"
    return 0
  fi

  echo "Killing: ${pids[@]}"
  kill -9 "${pids[@]}"
}
