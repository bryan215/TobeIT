import mysql.connector
import requests
db_config = {
    'host': '192.168.49.2',
    'port': '30000',
    'user': 'tobeit',
    'password': 'SecretP@assword',
    'database': 'synthetics'
}

url = 'https://dev.elastic.tobeit.net/synthetics-browser-default/_search'
headers = {
    'kbn-xsrf': 'reporting',
    'Authorization': 'Basic dG9iZWl0LnRlc3Q6IVJAbmRvbS41Njch',
}
query = {
    "query": {
        "match_all": {}
    },
    "_source": ["monitor.name", "synthetics.step.name", "synthetics.step.status"],
    "size": 50,
    "sort": [
        {
            "@timestamp": {
                "order": "desc"
            }
        }
    ]
}


response = requests.get(url, json=query, headers=headers)

if response.status_code == 200:
    data = response.json()
    conn = mysql.connector.connect(**db_config)
    cursor = conn.cursor()

    for hit in data['hits']['hits']:
        monitor_name = hit['_source']['monitor']['name']
        step_name = hit['_source'].get('synthetics', {}).get('step', {}).get('name')
        step_status = hit['_source'].get('synthetics', {}).get('step', {}).get('status')
        elastic_id = hit['_id'] 

        if step_name and step_status: 
            cursor.execute("""
                INSERT INTO monitoring (id, monitor_name, step_name, step_status) 
                VALUES (%s, %s, %s, %s) 
                ON DUPLICATE KEY UPDATE 
                monitor_name = VALUES(monitor_name), 
                step_name = VALUES(step_name), 
                step_status = VALUES(step_status)
            """, (elastic_id, monitor_name, step_name, step_status))
        else:  
            cursor.execute("""
                INSERT INTO monitoring (id, monitor_name, step_name, step_status) 
                VALUES (%s, %s, %s, %s) 
                ON DUPLICATE KEY UPDATE 
                monitor_name = VALUES(monitor_name), 
                step_name = VALUES(step_name), 
                step_status = VALUES(step_status)
            """, (elastic_id, monitor_name, None, None))
    conn.commit()
    cursor.close()
    conn.close()
else:
    print(f"Error: {response.status_code}")

