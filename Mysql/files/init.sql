CREATE USER 'grafana'@'%' IDENTIFIED BY 'SecretP@assword';
GRANT SELECT ON synthetics.* TO 'grafana'@'%';
FLUSH PRIVILEGES;

CREATE TABLE monitoring (
    id INT AUTO_INCREMENT PRIMARY KEY,
    monitor_name VARCHAR(255),
    step_name VARCHAR(255),
    step_status VARCHAR(50),
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

