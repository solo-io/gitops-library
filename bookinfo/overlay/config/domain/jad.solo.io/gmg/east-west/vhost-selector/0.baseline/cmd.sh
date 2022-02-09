for i in {1..5}; do curl -v -H "Host: www.example.com" localhost:8080/ratings/1;echo ''; done

for i in {1..5}; do curl -v -H "Host: www.example.com" localhost:8081/ratings/1;echo ''; done