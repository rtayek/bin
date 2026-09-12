cd ~/eclipse-workspace/chatmap
git log --format='%ad' --date=short --name-only -- .llm/handoffs/ | \
awk '/^[0-9-]{10}$/{d=$0} /\.md$/{if (!($0 in seen)) {print d, $0; seen[$0]=1}}' | \
sort -r