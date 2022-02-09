for i in {1..5}; do curl -I -H "x-type: a" -H "x-number: one" -sk http://localhost:8080/productpage;echo ''; done

for i in {1..5}; do curl -I -H "x-type: a" -H "x-number: one" -sk http://localhost:8081/productpage;echo ''; done
