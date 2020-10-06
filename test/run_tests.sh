script_dir="$(dirname "$0")"
chmod +x "$script_dir/../push_appstore.sh"

echo "Starting test execution"

echo "Starting mockserver"
npm start &

echo "Waiting for mockserver"
i=0
while ! nc -z localhost 7000; do  
    printf "." 
    sleep 0.5 
    if [ $i -gt 20 ]; then
        echo "Mockserver did not start within 10s"
        exit 1
    fi
    ((i=i+1))
done
echo ""
echo "Mockserver is online"
echo ""

bats test.bats

npm stop