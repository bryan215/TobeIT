import requests

url = 'https://dev.elastic.tobeit.net/synthetics-browser-default/_search'
headers = {
    'kbn-xsrf': 'reporting',
    'Authorization': 'Basic dG9iZWl0LnRlc3Q6IVJAbmRvbS41Njch',
}

response = requests.get(url, headers=headers)

if response.status_code == 200:
    data = response.json()  
    print(data) 
else:
    print(f"Error: {response.status_code}")

