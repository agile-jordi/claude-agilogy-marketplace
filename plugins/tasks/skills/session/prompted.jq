# jq -n -f prompted.jq <transcript>: whether the user wrote a prompt or Claude replied (local commands alone
# don't count). Claude Code can write a transcript with none after it was archived, when the session exits.
any(inputs;
  (.type == "assistant" and .message.model != "<synthetic>")
  or (.type == "user" and (.isMeta | not)
      and (.message.content | if type == "string" then . else (map(select(.type == "text").text) | join("")) end
           | test("\\S") and (test("^\\s*<(command-name|command-message|local-command-)") | not))))
