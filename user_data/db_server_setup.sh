#!/bin/bash
set -e
yum update -y

amazon-linux-extras install postgresql14 -y

postgresql-setup --initdb

systemctl start postgresql
systemctl enable postgresql 

cp /var/lib/pgsql/data/postgresql.conf /var/lib/pgsql/data/postgresql.conf.backup
cp /var/lib/pgsql/data/pg_hba.conf /var/lib/pgsql/data/pg_hba.conf.backup

sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/" /var/lib/pgsql/data/postgresql.conf

cat >> /var/lib/pgsql/data/pg_hba.conf << EOF

# Allow connections from VPC
host    all             all             10.0.0.0/16             md5
EOF

systemctl restart postgresql

sudo -u postgres psql << EOF
-- Create a database
CREATE DATABASE techcorp_db;

-- Create a user with password
CREATE USER techcorp_user WITH ENCRYPTED PASSWORD 'TechCorp2024!';

-- Grant privileges
GRANT ALL PRIVILEGES ON DATABASE techcorp_db TO techcorp_user;

-- Create a sample table
\c techcorp_db
CREATE TABLE server_info (
    id SERIAL PRIMARY KEY,
    server_name VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert sample data
INSERT INTO server_info (server_name) VALUES ('TechCorp Database Server');

-- Grant table privileges
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO techcorp_user;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO techcorp_user;
EOF

echo "PostgreSQL setup completed successfully!"
echo "Database: techcorp_db"
echo "User: techcorp_user"
echo "Password: TechCorp2024!"
echo "Connection example: psql -h localhost -U techcorp_user -d techcorp_db"
```